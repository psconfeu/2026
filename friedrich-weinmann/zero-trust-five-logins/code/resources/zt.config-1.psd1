@{
	Version = 1
	Tree = @{
		ZeroTrustAssessment = @{
			'Graph.DisableCache' = $true

			ThrottleLimit = @{
				Export = 8
				Tests = 12
			}

			'Tests.Timeout' = '7d'
		}
	}
}