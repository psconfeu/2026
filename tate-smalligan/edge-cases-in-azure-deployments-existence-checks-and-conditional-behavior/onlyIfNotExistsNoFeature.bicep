@description('Resource naming prefix')
param prefix string = 'nofeature'

resource vault 'Microsoft.KeyVault/vaults@2025-05-01' existing = {
  name: '${prefix}-vault'
}

@secure()
@description('Randomly generated secret value')
param securePassword string = base64(uniqueString(newGuid(), utcNow()))

// @onlyIfNotExists() 
resource secret 'Microsoft.KeyVault/vaults/secrets@2025-05-01' = {
  parent: vault
  name: 'secret'
  properties: {
    value: securePassword
  }
}
