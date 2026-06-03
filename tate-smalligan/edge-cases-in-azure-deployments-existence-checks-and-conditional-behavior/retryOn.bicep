@description('Name of the Azure Key Vault')
param keyVaultName string = 'keyvaultwithretryon'

resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' = {
  name: keyVaultName
  location: resourceGroup().location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    enableSoftDelete: true
    enabledForDeployment: true
    enabledForDiskEncryption: true
    enabledForTemplateDeployment: true
    accessPolicies: []
  }
}

module accessPolicy 'accessPolicyRetryOn.bicep' = {
  params: {
    keyVaultName: keyVaultName
  }
}
