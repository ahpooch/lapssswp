# lapssswp short description
[![english](https://img.shields.io/badge/read_in-english-blue.svg)](README.md)
[![русском](https://img.shields.io/badge/%D1%87%D0%B8%D1%82%D0%B0%D1%82%D1%8C_%D0%BD%D0%B0-%D1%80%D1%83%D1%81%D1%81%D0%BA%D0%BE%D0%BC-lightblue.svg)](README.ru-RU.md)  
---
lapssswp provide users ability to gain access to a local administator password on treir devices with a request on self service portal.

![Logon screen](./demo_images/logonscreen_en.png?raw=true "Logon screen")
![Main page](./demo_images/main_page_en.png?raw=true "Main page")
![My devices](./demo_images/my_devices_en.png?raw=true "My devices")
![My devices disclaymer](./demo_images/my_devices_show_disclaimer_en.png?raw=true "My devices disclaymer")
![My devices password display](./demo_images/my_devices_show_display_en.png?raw=true "My devices password display")

## Why lapssswp
The lapssswp abbreviation stands for `Local Administrator Password Solution Self Service Web Portal`.  

## lapssswp capabilities
- Domain authentication
- Work in https and http mode (for reverse-proxy)
- Support Microsoft LAPS
- Support Windows LAPS
- Support multiple languages (en, ru, with ability to add new localizations)
- Autodetection and switching to a language preferred by web browser.

## General prerequisites to use lapssswp portal
- Devices with Windows Operating System joined to Active Directory Domain.
- Users of a portal are domain accounts and members of one of specified domain groups.
- There is a Microsoft LAPS configured in domain or newer Windows LAPS built-in soulution.
- Devices are SCCM clients and user-device affinity process configured in SCCM or users to devices relationship set manually.

## Prerequisites to run lapssswp
- Windows Server / Workstation
- Powershell 7
- Powershell Module Pode
- Powershell Module Active Directory
- Powershell Module LAPS (for Microsoft LAPS which is not built-in to Active Directory like Windows LAPS)
- Domain service account with particular permissions for SCCM, Active Directory, Microsoft LAPS/Windows Laps and membership in local administrators group on server where lapssswp will be running.

# Questions and answers
## Which users have rights to view the local administrator password?
Users who are in specified domain groups. Arbitrary group names for administrators and regular users can be set in the server.psm1 file.

## Which device passwords can be displayed?
Only the passwords of local administrators for devices within the Organizational Unit specified in the server.psm1 file are displayed.

## How do the administrator rights differ?
Users from the domain group of lapssswp administrators can view the passwords of all devices within the Organizational Unit specified in the server.psm1 file.

## How determined devices that a user has rights to view its password?
To determine the devices for a user, a query is made to SCCM to obtain a list of device affinity. lapssswp considers devices that have been automatically assigned to the user (after some time of usage) or manually assigned by an SCCM administrator.

# lapssswp deployment
## Preparing Files
- Place the project files in any directory, for example, C:\lapssswp
- Edit the server.psm1 file to set the desired configuration.
- Edit the localization_footer.json file to describe the necessary links that will be displayed at the bottom of the portal.

## Manual launch from a console
The server.ps1 file must be run from Powershell 7 (pwsh.exe).
Powershell 7 should be launched with administrative rights (elevation) and using a domain account that has the necessary permissions. More details about permissions can be found in the section `Permissions for the Service Account`.
### Running Powershell 7 as Administrator
- Install Powershell 7 (https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-windows?view=powershell-7.5)
- Ensure that the service account has local administrator rights on the device.
- Launch Powershell 7 under the service account.
- Run `Start-Process pwsh -Verb RunAs` and confirm UAC if it is enabled.
### Launching the lapssswp Portal
- Run `cd C:\lapssswp` or change path to another directory containing the portal files.
- Run `& .server.ps1`
- Go to https://localhost/ or https://localhost:<port>

# Running lapssswp as a Windows service
To run portal as a Windows service, you can use NSSM (https://nssm.cc/)
## Registering the lapssswp service
```Powershell
# Place nssm.exe to a folder 'nssm' inside project folder
cd C:\lapssswp\nssm
& .\nssm.exe install lapssswp 'C:\Program Files\PowerShell\7\pwsh.exe' '-File .\server.ps1'
& .\nssm.exe set lapssswp DisplayName 'lapssswp'
& .\nssm.exe set lapssswp Description 'lapssswp.mycompany.com web portal. Written on Powershell web framework Pode. Service is installed using NSSM.'
& .\nssm.exe set lapssswp ImagePath 'C:\lapssswp\nssm\nssm.exe'
& .\nssm.exe set lapssswp AppDirectory 'C:\lapssswp'
& .\nssm.exe set lapssswp Start SERVICE_DELAYED_AUTO_START
& .\nssm.exe set lapssswp ObjectName MYCOMPANY\lapssswp_service_account <lapssswp_service_account_password>
& .\nssm.exe start lapssswp
```

### Removint lapssswp service
```Powershell
cd C:\lapssswp\nssm
& .\nssm.exe stop lapssswp
& .\nssm.exe remove lapssswp confirm
```

# Permissions Required for the Service Account
## SCCM
### Simple option with Non-Granular Access
Grant service account an administrator rights on SCCM.
### Complex option with Granular Access
Create a separate role with `User Device Affinities – Read permissions`.
## Microsoft LAPS
If Microsoft LAPS is configured in the domain, grant the service account the necessary permissions using cmdlets from the LAPS module.
## Windows LAPS
If Windows LAPS is configured in the domain, it is sufficient to delegate read permissions on the `ms-Mcs-AdmPwd` attribute and edit permissions on `ms-Mcs-AdmPwdExpirationTime` for computers in the required Organizational Unit.
