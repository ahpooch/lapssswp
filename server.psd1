@{
    Web = @{
        ErrorPages = @{
            # Enable exception display. Use only for debugging.
            # https://badgerati.github.io/Pode/Tutorials/Routes/Utilities/ErrorPages/#content-types
            ShowExceptions = $false
            Default = "text/html"
        }
    }

    ######### Web portal network settings #####################################################################################################
    ###########################################################################################################################################
    # Web portal desired port.
    Port                        = 443
    
    # Title will be set to metadata and displayed on web portal.
    Title                       = "lapssswp.mycompany.com"
    
    # Set https for secure protocol or http for unsecure (not recommended but applicable for reverse proxy deployment).
    Protocol                    = "https" # https, http

    # Session duration for users.
    Session_Duration            = 1200
    
    ######### Web portal certificate settings #################################################################################################
    ###########################################################################################################################################
    # Path to pfx certificate file. Commment this line if using http protocol.
    CertPath                    = "C:\lapssswp\lapssswp.mycompany.com.pfx" 
    
    # Password for pfx file. Commment this line if using http protocol.
    CertPassword                = "<Your_password_for_pfx_certificate_file>"
    
    ######### Web portal Active Directory and SCCM settings ###################################################################################
    ###########################################################################################################################################
    # Search scope where devices will be searched.
    DevicesSearchBase           = "OU=computers,DC=mycompany,DC=com"
    
    # SCCM Management Point Server address in FQDN format.
    SCCMDistinguishedName       = "CM01.mycompany.com"
    
    # Provide a name for a group that contains administrators. They will be able to trieve password for any device.
    ADAdminGroupName            = "lapssswp-admins"
    
    # Provide a name for a group that contains users which allowed to retrieve passwords for their devices based on SCCM user affinity.
    ADUserGroupName             = "lapssswp-users"
    
    # Domain Plain Name. If domain name is example.com then domain plain name is EXAMPLE.
    ADDomainPlainName           = "MYCOMPANY"
    
    # If you changed name for built-in local administrator user via group policies then provide your custom name
    LocalAdministratorName      = ".\administrator"
    
    ######### Web portal main settings ########################################################################################################
    ###########################################################################################################################################
    # Default language for Laps Self Service Web Portal
    DefaultLanguage             = "en" # en, ru
    
    # Enable or disable portal language based on web browser preferrence.
    UseBrowserPreferredLanguage = $true
    
    
    # Email address of support team
    SupportEmail                = "help@mycompany.com"
    
    # Copyright title
    CopyrightTitle              = "MYCOMPANY Inc."
    
    # Copyright link
    CopyrightLink               = "mycompany.com"

    ######### Web portal logging settings #####################################################################################################
    ###########################################################################################################################################
    # Enable or disable logging in general.
    LogToFileEnabled            = $true
    
    # Enable or disable writing a password provided to user by portal to a log file.
    LogPasswordToFileEnabled    = $false
    
    # Log file path. Directory should exist beforehand.
    LogFilePath                 = "C:\lapssswp\password_orders.log"
}