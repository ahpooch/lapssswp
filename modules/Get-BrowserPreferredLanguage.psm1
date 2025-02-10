function Get-BrowserPreferredLanguage {
    # Getting default portal language
    $browser_Preferred_language = (Get-PodeConfig).DefaultLanguage
    # Getting user preferred language from Accept-Language Header
    $accept_language_header = $(Get-PodeHeader -Name 'Accept-Language') #ru,en;q=0.9,en-US;q=0.8
    
    # Setting language
    if ((Get-PodeConfig).UseBrowserPreferredLanguage){
        # Choosing from localizations available in ..\localization.json file.
        if ($null -ne $accept_language_header){
            if ("en-US", "en-GB", "en" -contains $accept_language_header.split(",")[0]) { $browser_Preferred_language = "en" }
            if ("ru-RU", "ru" -contains $accept_language_header.split(",")[0]) { $browser_Preferred_language = "ru" }
        }

    }
    
    return $browser_Preferred_language
}