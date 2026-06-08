@{
    RootModule        = 'PSConfEUTestServer.psm1'
    ModuleVersion     = '0.1.0'
    Description       = 'Helpers to start/stop the PSConfEU mock API for tests.'
    FunctionsToExport = @('Start-PSConfEUServer', 'Stop-PSConfEUServer')
}
