function Get-ADAuthentication {
    Param(
        [Parameter(Mandatory)][string]$User,
        [Parameter(Mandatory)]$PswdForValidation,
        [Parameter(Mandatory = $false)]$Server,
        [Parameter(Mandatory = $false)][string]$Domain = $env:USERDOMAIN
    )
  
    Add-Type -AssemblyName System.DirectoryServices.AccountManagement
    $contextType = [System.DirectoryServices.AccountManagement.ContextType]::Domain
    $argumentList = New-Object -TypeName "System.Collections.ArrayList"
    $null = $argumentList.Add($contextType)
    $null = $argumentList.Add($Domain)
    if ($null -ne $Server) {
        $argumentList.Add($Server)
    }
    
    $principalContext = New-Object System.DirectoryServices.AccountManagement.PrincipalContext -ArgumentList $argumentList -ErrorAction SilentlyContinue
    if ($null -eq $principalContext) {
        return $false
    }
    
    if ($principalContext.ValidateCredentials($User, $PswdForValidation)) {
        return $true
    }
    else {
        return $false
    }
}