@description('Storage Account Name')
param storageName string

@nullIfNotFound()
resource storage 'Microsoft.Storage/storageAccounts@2024-01-01' existing = {
  name: storageName
}

module addFileShare 'addFileShare.bicep' = {
  params: {
    storageExists: storage != null
    storageName: storage.name
  }
}
