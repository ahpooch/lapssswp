Import-Module -Name Pode -MaximumVersion 2.11.1
Import-Module -Name LAPS -MaximumVersion 1.0.0.0
Import-Module .\modules\Get-ADAuthentication.psm1
Import-Module .\modules\Get-RouteIsPermittedForUser.psm1
Import-Module .\modules\Get-BrowserPreferredLanguage.psm1

Start-PodeServer -Thread 1 {
    # Loading configuration values from server.psd1.
    $port                  = (Get-PodeConfig).Port
    $protocol              = (Get-PodeConfig).Protocol
    $certPath              = (Get-PodeConfig).CertPath
    $certPassword          = (Get-PodeConfig).CertPassword 
    $session_duration      = (Get-PodeConfig).Session_Duration
    $SearchBase            = (Get-PodeConfig).DevicesSearchBase
    $SCCMDistinguishedName = (Get-PodeConfig).SCCMDistinguishedName
    $ADAdminGroupName      = (Get-PodeConfig).ADAdminGroupName
    $ADUserGroupName       = (Get-PodeConfig).ADUserGroupName
    $Strings               = Get-Content -Path ".\localization.json" -Raw | ConvertFrom-Json
    $Footer_Strings        = Get-Content -Path ".\localization_footer.json" -Raw | ConvertFrom-Json

    if ((Get-PodeConfig).Protocol -eq "Https") {
        Add-PodeEndpoint -Address "*" -Port $port -Protocol $protocol -Certificate $certPath -CertificatePassword $certPassword
    } else {
        Add-PodeEndpoint -Address "*" -Port $port -Protocol $protocol
    }
    # Using Pode template engine.
    Set-PodeViewEngine -Type Pode
    # Enabling Middleware for working with sessions, cookies etc.
    Enable-PodeSessionMiddleware -Duration $session_duration -Extend
    # Enable CSRT token generation.
    Enable-PodeCsrfMiddleware

    #Enable logging.
    New-PodeLoggingMethod -Terminal | Enable-PodeRequestLogging
    New-PodeLoggingMethod -Terminal | Enable-PodeErrorLogging

    # Define athentication scheme.
    New-PodeAuthScheme -Form | Add-PodeAuth -Name 'Login' -FailureUrl '/login' -SuccessUrl '/' -ScriptBlock {
        param($username, $pswd_for_validation)
        if (Get-ADAuthentication -User $username -PswdForValidation $pswd_for_validation) {
            $ADUser = Get-ADUser $username -Properties Title, Manager
            $ADUserGroups = (Get-ADUser $username -Properties memberof | Select-Object -ExpandProperty memberof | Select-Object -Property @{n = 'Name'; e = { $_.split('=')[1].split(',')[0] } }).Name
            
            if ($ADUserGroups -contains $using:ADAdminGroupName) {
                $User_Devices = Get-ADComputer -Filter * -SearchBase $using:SearchBase | Select-Object -ExpandProperty Name
            }
            elseif ($ADUserGroups -contains $using:ADUserGroupName) {
                try {
                    $User_Devices = (Invoke-RestMethod -Method 'Get' -Uri "https://$using:SCCMDistinguishedName/AdminService/wmi/SMS_UserMachineRelationship/" -UseDefaultCredentials).value | Where-Object { $_.UniqueUserName -eq "$((Get-PodeConfig).ADDomainPlainName)\$username" } | Where-Object { $_.Sources -contains "7" -or $_.Sources -contains "9" -or $_.Sources -contains "2" } | Select-Object -ExpandProperty ResourceName
                    
                    # Sources (https://learn.microsoft.com/en-us/mem/configmgr/develop/reference/core/clients/manage/sms_usermachinerelationship-server-wmi-class) : 
                    #   Value   Name                        Description
                    #   1	    Self-service portal	        The end user enabled the relationship by selecting the option in Software Center.
                    #   2	    Administrator	            An administrator created the relationship manually in the console.
                    #   3	    User                        Unused/deprecated.
                    #   4	    Usage agent	                The threshold of activity triggered a relationship to be created.
                    #   5	    Device management           The user and device were tied together during on-prem MDM enrollment.
                    #   6	    OSD	                        The user and device were tied together as part of an OS deployment task sequence.
                    #   7	    Fast install	            The user/device were tied together temporarily to enable an on-demand install from the catalog if no UDA relationship installed before the Install was triggered.
                    #   8	    Exchange Server connector	The device was provisioned through Exchange ActiveSync.
                    #   9	    Secure usage agent	
                }
                catch {
                    $User_Devices = $null
                }
            }
            else {
                $User_Devices = $null
            }

            return @{
                User = @{
                    ID      = New-Guid
                    Name    = $username
                    Title   = $ADUser.Title
                    Manager = $ADUser.Manager
                    Groups  = $ADUserGroups
                    Devices = $User_Devices
                }
            }
        }
        else {
            Add-PodeFlashMessage -Name 'validation_error' -Message ($using:Strings).(Get-BrowserPreferredLanguage).password_validation_error
        }
    }

    # Route to home page
    Add-PodeRoute -Method Get -Path '/' -Authentication 'Login' -ScriptBlock {
        $token = (New-PodeCsrfToken)
        Write-PodeViewResponse -Path 'auth-home' -Data @{
            Username       = $WebEvent.Auth.User.Name
            Views          = $WebEvent.Session.Data.Views
            User_Devices   = $User_Devices
            csrfToken      = $token
            strings        = $using:Strings
            footer_strings = $using:Footer_Strings
            language       = Get-BrowserPreferredLanguage
        }
    }

    # Route to display user password logon form.
    Add-PodeRoute -Method Get -Path '/login' -Authentication 'Login' -Login -ScriptBlock {
        $token = (New-PodeCsrfToken)
        Write-PodeViewResponse -Path 'auth-login' -FlashMessages -Data @{ 
            csrfToken      = $token
            strings        = $using:Strings
            language       = Get-BrowserPreferredLanguage
        } 
    }

    # Route to user authentication after credentials entered.
    Add-PodeRoute -Method Post -Path '/login' -Authentication 'Login' -Login
    
    # Route to user session logout.
    Add-PodeRoute -Method Post -Path '/logout' -Authentication 'Login' -Logout
    
    # Route to display device local administrator password
    Add-PodeRoute -Method Get -Path '/devices/:Device' -Authentication 'Login' -ScriptBlock {
        $LogFilePath              = (Get-PodeConfig).LogFilePath
        $LogToFileEnabled         = (Get-PodeConfig).LogToFileEnabled
        $LogPasswordToFileEnabled = (Get-PodeConfig).LogPasswordToFileEnabled
        $token                    = (New-PodeCsrfToken)
        if (Get-RouteIsPermittedForUser -CurrentRoutePath $WebEvent.Path -UserGroups $WebEvent.Auth.User.Groups -UserDevices $WebEvent.Auth.User.Devices ) {            
            try {
                $Device = $null
                $Device = Get-LapsADPassword -Identity $WebEvent.Parameters['Device'] -AsPlainText | Select-Object -Property @{n = 'name'; e = { $_.ComputerName } }, Password, @{n = 'ExpirationDate'; e = { $_.ExpirationTimestamp } } -ErrorAction SilentlyContinue 
                if ([string]::IsNullOrEmpty($Device.Password)) {
                    $Device = Get-ADComputer -Identity $WebEvent.Parameters['Device'] -Properties name, ms-Mcs-AdmPwd, ms-Mcs-AdmPwdExpirationTime | Select-Object -Property name, @{n = 'Password'; e = { $_.'ms-Mcs-AdmPwd' } }, @{n = 'ExpirationDate'; e = { [datetime]::FromFileTime($_.'ms-Mcs-AdmPwdExpirationTime') } }
                }
            }
            catch {
                Write-PodeViewResponse -Path 'device-view-notfound' -FlashMessages -Data @{
                    Username       = $WebEvent.Auth.User.Name
                    csrfToken      = $token
                    strings        = $using:Strings
                    footer_strings = $using:Footer_Strings
                    language       = Get-BrowserPreferredLanguage
                }
            }
            
            if ($LogToFileEnabled) {
                [ordered]@{
                    Date                           = $(Get-Date)
                    Username                       = $WebEvent.Auth.User.Name
                    device_name                    = $Device.Name;
                    device_password                = if ($LogPasswordToFileEnabled) { $Device.Password } else { "*********" }
                    device_password_expirationdate = $Device.ExpirationDate
                } | Out-File -Append $LogFilePath
            
            }

            Write-PodeViewResponse -Path 'device-view' -FlashMessages -Data @{
                Username                       = $WebEvent.Auth.User.Name
                device_name                    = $Device.Name
                device_password                = $Device.Password
                device_password_expirationdate = $Device.ExpirationDate
                csrfToken                      = $token
                strings                        = $using:Strings
                footer_strings                 = $using:Footer_Strings
                language                       = Get-BrowserPreferredLanguage
            }
        }
        else {
            Write-PodeViewResponse -Path 'you-are-not-allowed' -FlashMessages -Data @{
                Username       = $WebEvent.Auth.User.Name
                csrfToken      = $token
                strings        = $using:Strings
                footer_strings = $using:Footer_Strings
                language       = Get-BrowserPreferredLanguage
            }
        }
    }

    # Route to display devices available to user.
    Add-PodeRoute -Method Get -Path '/my-devices' -Authentication 'Login' -ScriptBlock {
        $token = (New-PodeCsrfToken)
        if (Get-RouteIsPermittedForUser -CurrentRoutePath $WebEvent.Path -UserGroups $WebEvent.Auth.User.Groups -UserDevices $WebEvent.Auth.User.Devices) {
            if ($null -eq $WebEvent.Auth.User.Devices -or $WebEvent.Auth.User.Devices -eq 0) {
                Write-PodeViewResponse -Path 'my-devices-view-notfound' -FlashMessages -Data @{
                    Username       = $WebEvent.Auth.User.Name
                    csrfToken      = $token
                    strings        = $using:Strings
                    footer_strings = $using:Footer_Strings
                    language       = Get-BrowserPreferredLanguage
                }
            }
            $My_Devices = @()
            foreach ($device in $WebEvent.Auth.User.Devices) {
                $AD_Record_Exist = [bool](Get-ADComputer -Filter { Name -eq $device })
                if ($AD_Record_Exist) {
                    $DevicePasswordData = Get-LapsADPassword -Identity $device -AsPlainText | Select-Object -Property @{n = 'name'; e = { $_.ComputerName } }, Password, @{n = 'ExpirationDate'; e = { $_.ExpirationTimestamp } } -ErrorAction SilentlyContinue 
                    if ([string]::IsNullOrEmpty($DevicePasswordData.Password)) {
                        $DevicePasswordData = Get-ADComputer -Identity $device -Properties name, ms-Mcs-AdmPwd, ms-Mcs-AdmPwdExpirationTime -ErrorAction SilentlyContinue | Select-Object -Property name, @{n = 'Password'; e = { $_.'ms-Mcs-AdmPwd' } }, @{n = 'ExpirationDate'; e = { [datetime]::FromFileTime($_.'ms-Mcs-AdmPwdExpirationTime') } } -ErrorAction SilentlyContinue 
                    }

                    $My_Devices += @{
                        device_name                    = $DevicePasswordData.name;
                        device_password_available      = (!([string]::IsNullOrEmpty($DevicePasswordData.Password)));
                        device_password_expirationdate = $DevicePasswordData.ExpirationDate;
                    }
                }
            }
            Write-PodeViewResponse -Path 'my-devices-view' -FlashMessages -Data @{
                Username       = $WebEvent.Auth.User.Name
                My_Devices     = $My_Devices
                csrfToken      = $token
                strings        = $using:Strings
                footer_strings = $using:Footer_Strings
                language       = Get-BrowserPreferredLanguage
            }
        }
        else {
            Write-PodeViewResponse -Path 'you-are-not-allowed' -FlashMessages -Data @{
                Username       = $WebEvent.Auth.User.Name
                csrfToken      = $token
                strings        = $using:Strings
                footer_strings = $using:Footer_Strings
                language       = Get-BrowserPreferredLanguage
            }
        }
    }
}
# We can export values of internal variables to environment of a server.
# https://badgerati.github.io/Pode/Tutorials/Misc/Outputs/#variables
# Out-PodeVariable -Name VariableName -Value 'AnyPowershellObject'