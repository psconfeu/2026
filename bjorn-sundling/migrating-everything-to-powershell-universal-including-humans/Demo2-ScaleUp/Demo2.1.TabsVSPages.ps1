# Initially Lookes at tabs.. And it does what we wanted..
New-UDApp -Content {
    New-UDTabs -Tabs {
        New-UDTab -Text "Tab1" -Id 'Tab1' -Content { 
            New-UDTextbox -Id 'nameBox' -Label 'Name' -Placeholder 'Enter your name' -Value 'John Doe' -OnEnter {
                Show-UDToast -Message "Hello $EventData"
            }
        }
        New-UDTab -Text "Tab2" -Id 'Tab2' -Content {
            New-UDTextbox -Id 'nameBox' -Label 'Age' -Placeholder 'Enter your age' -Value '666' -OnEnter {
                Show-UDToast -Message "You are $EventData years old"
            }
        }
    }
}




# I discovered pages later - but both works - and I need something that makes sense to other devs. One solution.

#app
New-UDApp -Title 'Pages' -HeaderPosition fixed

#pages
New-UDPage -Url "page1" -Name "page1" -Content {
    New-UDHtml -Markup '<br>'
    New-UDHtml -Markup '<br>'
    'Hello, world!'
} -AutoInclude
