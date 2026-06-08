@{
	RootModule           = 'PowerShellUniversal.WindowsServerDiagnostics.psm1'
	ModuleVersion        = '1.0.0'
	GUID                 = '9cfbf960-d608-4da1-b2df-9fe077035aa5'
	Author               = 'GitHub Copilot'
	CompanyName          = 'PowerShell Universal'
	Description          = 'Collects diagnostic information from a Windows server for use in PowerShell Universal features.'
	PowerShellVersion    = '5.1'
	CompatiblePSEditions = @('Desktop', 'Core')
	FunctionsToExport    = @(
		'Get-PSUWindowsServerHostName',
		'Get-PSUWindowsServerOperatingSystem',
		'Get-PSUWindowsServerUptime',
		'Get-PSUWindowsServerCpuUsage',
		'Get-PSUWindowsServerMemoryUsage',
		'Get-PSUWindowsServerSystemDrive',
		'Get-PSUWindowsServerPendingReboot',
		'Get-PSUWindowsServerStoppedAutomaticService',
		'Get-PSUWindowsServerRecentEvent',
		'Get-PSUWindowsServerIisInventory',
		'Get-PSUWindowsServerDiagnostics'
	)
	CmdletsToExport      = @()
	VariablesToExport    = @()
	AliasesToExport      = @()
	PrivateData          = @{
		PSData = @{
			Tags       = @('PowerShellUniversal', 'Windows', 'Diagnostics', 'IIS')
			ProjectUri = 'https://powershelluniversal.com'
		}
	}
}
