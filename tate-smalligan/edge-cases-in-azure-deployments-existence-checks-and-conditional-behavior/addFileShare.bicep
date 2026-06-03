param storageExists bool
param storageName string

resource fileservice 'Microsoft.Storage/storageAccounts/fileServices@2024-01-01' = if (storageExists) {
  name: '${storageName}/default'
  
  resource fileshare 'shares' = {
    name: 'demoshare'
  }
}
