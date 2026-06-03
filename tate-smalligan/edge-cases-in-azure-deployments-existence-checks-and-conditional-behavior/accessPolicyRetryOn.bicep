@description('Name of the Azure Key Vault')
param keyVaultName string

@description('Object ID to assign access policy to (e.g., a user, service principal, or managed identity)')
param objectId string = '8db52346-5bb1-4e38-b85a-d36d79a70360'

@description('Permissions to assign to the object ID')
param permissions object = {
  secrets: [
    'get'
    'list'
    'set'
    'delete'
  ]
  keys: [
    'get'
    'list'
    'create'
    'delete'
    'encrypt'
    'decrypt'
  ]
  certificates: [
    'get'
    'list'
    'create'
    'delete'
  ]
}

@retryOn(['VaultNotFound'], 3)
resource accessPolicy 'Microsoft.KeyVault/vaults/accessPolicies@2023-02-01' = {
  name: '${keyVaultName}/add'
  properties: {
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId: objectId
        permissions: permissions
      }
    ]
  }
}
