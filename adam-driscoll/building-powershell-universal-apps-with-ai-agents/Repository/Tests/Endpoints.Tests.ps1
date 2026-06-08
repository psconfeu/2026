Describe 'Windows server diagnostics endpoints' -Tag 'Endpoints' {
	BeforeAll {
		$script:RepositoryRoot = Split-Path -Parent $PSScriptRoot
		$script:EndpointDefinitionPath = Join-Path $RepositoryRoot '.universal\endpoints.ps1'
		$script:BaseUri = 'http://localhost:5000'
		$script:UserName = 'admin'
		$script:Password = 'admin'
		$script:CommandExpectations = @{
			'Get-PSUWindowsServerCpuUsage' = @{
				ResponseKind       = 'Object'
				ExpectedProperties = @('PercentProcessorTime', 'Source', 'SampleTime')
			}
			'Get-PSUWindowsServerHostName' = @{
				ResponseKind       = 'String'
				ExpectedProperties = @()
			}
			'Get-PSUWindowsServerIisInventory' = @{
				ResponseKind       = 'Object'
				ExpectedProperties = @('Installed', 'ModuleAvailable', 'Sites', 'AppPools')
			}
			'Get-PSUWindowsServerMemoryUsage' = @{
				ResponseKind       = 'Object'
				ExpectedProperties = @('TotalGB', 'UsedGB', 'FreeGB', 'PercentUsed')
			}
			'Get-PSUWindowsServerOperatingSystem' = @{
				ResponseKind       = 'Object'
				ExpectedProperties = @('Caption', 'Version', 'BuildNumber', 'Architecture', 'InstallDate', 'LastBootUpTime', 'SerialNumber', 'RegisteredUser', 'Organization')
			}
			'Get-PSUWindowsServerPendingReboot' = @{
				ResponseKind       = 'Object'
				ExpectedProperties = @('PendingReboot', 'Reasons')
			}
			'Get-PSUWindowsServerRecentEvent' = @{
				ResponseKind       = 'Collection'
				ExpectedProperties = @('TimeCreated', 'LogName', 'ProviderName', 'Id', 'LevelDisplayName', 'MachineName', 'Message')
			}
			'Get-PSUWindowsServerStoppedAutomaticService' = @{
				ResponseKind       = 'Collection'
				ExpectedProperties = @('Name', 'DisplayName', 'State', 'StartMode', 'StartName', 'ExitCode')
			}
			'Get-PSUWindowsServerDiagnostics' = @{
				ResponseKind       = 'Object'
				ExpectedProperties = @('CollectedAt', 'HostName', 'OperatingSystem', 'Uptime', 'CpuUsage', 'MemoryUsage', 'SystemDrive', 'PendingReboot', 'StoppedAutomaticServices', 'RecentEvents', 'Iis')
			}
			'Get-PSUWindowsServerSystemDrive' = @{
				ResponseKind       = 'Object'
				ExpectedProperties = @('Drive', 'VolumeName', 'SizeGB', 'UsedGB', 'FreeGB', 'PercentFree')
			}
			'Get-PSUWindowsServerUptime' = @{
				ResponseKind       = 'Object'
				ExpectedProperties = @('LastBootUpTime', 'Days', 'Hours', 'Minutes', 'Seconds', 'TotalDays')
			}
		}

		$script:SecurePassword = ConvertTo-SecureString $Password -AsPlainText -Force
		$script:Credential = [pscredential]::new($UserName, $SecurePassword)
		$script:BasicAuthHeader = @{
			Authorization = 'Basic {0}' -f [Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes(('{0}:{1}' -f $UserName, $Password)))
		}

		$script:InvokeEndpointRequest = {
			param(
				[Parameter(Mandatory)]
				[string]$Uri,

				[switch]$Anonymous
			)

			$invokeWebRequestParameters = @{
				Uri         = $Uri
				Method      = 'GET'
				TimeoutSec  = 30
				ErrorAction = 'Stop'
			}

			if ($PSVersionTable.PSVersion.Major -ge 6) {
				if (-not $Anonymous) {
					$invokeWebRequestParameters['Authentication'] = 'Basic'
					$invokeWebRequestParameters['Credential'] = $Credential
					$invokeWebRequestParameters['AllowUnencryptedAuthentication'] = $true
				}

				return Invoke-WebRequest @invokeWebRequestParameters
			}

			$invokeWebRequestParameters['UseBasicParsing'] = $true

			if (-not $Anonymous) {
				$invokeWebRequestParameters['Headers'] = $BasicAuthHeader
			}

			Invoke-WebRequest @invokeWebRequestParameters
		}

		$script:EndpointCases = foreach ($line in Get-Content -Path $EndpointDefinitionPath) {
			if ($line -match 'New-PSUEndpoint -Url "(?<Url>[^"]+)".*-Command "(?<Command>[^"]+)"') {
				$expectation = $CommandExpectations[$Matches.Command]

				if (-not $expectation) {
					throw "No test expectation is defined for command '$($Matches.Command)'."
				}

				[pscustomobject]@{
					Url                = $Matches.Url
					Command            = $Matches.Command
					ResponseKind       = $expectation.ResponseKind
					ExpectedProperties = @($expectation.ExpectedProperties)
				}
			}
		}
	}

	It 'responds successfully for all registered endpoints' {
		$EndpointCases.Count | Should -BeGreaterThan 0

		$failures = [System.Collections.Generic.List[string]]::new()

		foreach ($endpointCase in $EndpointCases) {
			try {
				$response = & $InvokeEndpointRequest -Uri ($BaseUri + $endpointCase.Url)

				if ($response.StatusCode -ne 200) {
					throw "Expected status code 200 but received $($response.StatusCode)."
				}

				if ([string]::IsNullOrWhiteSpace($response.Content)) {
					throw 'Expected a non-empty response body.'
				}

				switch ($endpointCase.ResponseKind) {
					'String' {
						if ([string]::IsNullOrWhiteSpace($response.Content.Trim('"'))) {
							throw 'Expected a non-empty string response body.'
						}
					}
					'Object' {
						$payload = $response.Content | ConvertFrom-Json

						if ($null -eq $payload) {
							throw 'Expected a JSON object response body.'
						}

						foreach ($propertyName in $endpointCase.ExpectedProperties) {
							if ($payload.PSObject.Properties.Name -notcontains $propertyName) {
								throw "Missing expected property '$propertyName'."
							}
						}
					}
					'Collection' {
						$trimmedContent = $response.Content.Trim()

						if (-not $trimmedContent.StartsWith('[')) {
							throw 'Expected a JSON array response body.'
						}

						if ($trimmedContent -ne '[]') {
							$payload = @($response.Content | ConvertFrom-Json)

							if ($payload.Count -le 0) {
								throw 'Expected at least one item in the JSON array response body.'
							}

							foreach ($propertyName in $endpointCase.ExpectedProperties) {
								if ($payload[0].PSObject.Properties.Name -notcontains $propertyName) {
									throw "Missing expected property '$propertyName' on the first array item."
								}
							}
						}
					}
					default {
						throw "Unsupported response kind '$($endpointCase.ResponseKind)'."
					}
				}
			}
			catch {
				$failures.Add(('{0} ({1}) failed: {2}' -f $endpointCase.Command, $endpointCase.Url, $_.Exception.Message))
			}
		}

		if ($failures.Count -gt 0) {
			throw ($failures -join [Environment]::NewLine)
		}
	}

	It 'rejects anonymous requests for all registered endpoints' {
		$EndpointCases.Count | Should -BeGreaterThan 0

		$failures = [System.Collections.Generic.List[string]]::new()

		foreach ($endpointCase in $EndpointCases) {
			$statusCode = $null

			try {
				& $InvokeEndpointRequest -Uri ($BaseUri + $endpointCase.Url) -Anonymous | Out-Null
				$failures.Add(('{0} ({1}) unexpectedly allowed an anonymous request.' -f $endpointCase.Command, $endpointCase.Url))
			}
			catch {
				if ($_.Exception.Response -and $_.Exception.Response.StatusCode) {
					$statusCode = [int]$_.Exception.Response.StatusCode
				}

				if ($null -ne $statusCode -and $statusCode -notin @(401, 403)) {
					$failures.Add(('{0} ({1}) returned {2} for an anonymous request instead of 401 or 403.' -f $endpointCase.Command, $endpointCase.Url, $statusCode))
				}
			}
		}

		if ($failures.Count -gt 0) {
			throw ($failures -join [Environment]::NewLine)
		}
	}
}