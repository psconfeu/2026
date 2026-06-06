class ZtTest : System.Attribute
{
	[string]$Category
	[ValidateSet('Low','Medium','High')][string]$ImplementationCost
	[string[]]$MinimumLicense

	[string[]]$CompatibleLicense

	[string[]]$Service

	[string]$Pillar
	[ValidateSet('Critical','High','Medium','Low','Unranked')][string]$RiskLevel
	[string]$SfiPillar
	[ValidateSet('Workforce','External')][string[]]$TenantType
	[int]$TestId
	[string]$Title
	[ValidateSet('Low','Medium','High')][string]$UserImpact
}