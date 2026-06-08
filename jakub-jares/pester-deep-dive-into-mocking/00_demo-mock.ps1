Describe "Mock" {
    It "Invoke-RestMethod" {
        Mock Invoke-RestMethod {
            "<html><body><h1>Hello World!</h1></body></html>"
        }

        $result = Invoke-RestMethod -Uri "https://google.com"
        $result | Should -BeLike "*Hello World*"
    }
}
