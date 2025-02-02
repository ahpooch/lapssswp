function Get-RouteIsPermittedForUser {
    Param(
        $CurrentRoutePath,
        $UserGroups,
        $UserDevices
    )

    $ADUserGroupName = (Get-PodeConfig).ADUserGroupName

    if ($CurrentRoutePath -eq "/") {
        return $true
    }
    if ($CurrentRoutePath -eq "/my-devices" -and $UserGroups -contains $ADUserGroupName) {
        return $true
    }
    if ($CurrentRoutePath -like "/devices/*" -and $UserGroups -contains $ADUserGroupName) {
        $CurrentDevice = $CurrentRoutePath.split("/")[2]
        if ($UserDevices -contains $CurrentDevice) {
            return $true
        }
        else {
            return $false
        }
    }

    return $false
}