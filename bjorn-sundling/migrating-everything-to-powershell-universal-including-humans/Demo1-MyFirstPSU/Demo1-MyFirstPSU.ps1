# What are we building? Scripts, schedules, APIs, and Apps.

& 'C:\Program Files\Mozilla Firefox\firefox.exe' 'https://docs.powershelluniversal.com/automation/about'

# New script
Param($name)
Write-Output "Hello $name"

# New App
& 'C:\Program Files\Mozilla Firefox\firefox.exe' 'https://demo.powershelluniversal.com/'

New-UDApp -Content {    
    New-UDTextbox -Id 'nameBox' -Label 'Name' -Placeholder 'Enter your name' -Value 'John Doe' -OnEnter {
        Show-UDToast -Message "Hello $EventData"
    }
}


# How are we presenting it? Portal
# But how does roles work? Not super clear - you need to giva a role access to have it show up in portal
& 'C:\Program Files\Mozilla Firefox\firefox.exe' 'https://docs.powershelluniversal.com/apps/role-based-access'



# Running script and app from portal tells us what we need to have
