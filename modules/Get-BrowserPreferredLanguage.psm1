function Get-BrowserPreferredLanguage {
    # Getting default portal language
    $browser_Preferred_language = (Get-PodeConfig).Language
    # Getting user preferred language from Accept-Language Header
    $accept_language_header = $(Get-PodeHeader -Name 'Accept-Language') #ru,en;q=0.9,en-US;q=0.8
    
    # Setting language
    if ((Get-PodeConfig).UseBrowserPreferredLanguage){
        # Choosing from localizations available in ..\localization.json file.
        if ($accept_language_header.split(",")[0] -eq "en") { $browser_Preferred_language = "en" }
        if ($accept_language_header.split(",")[0] -eq "ru") { $browser_Preferred_language = "ru" }
    }
    
    return $browser_Preferred_language
}