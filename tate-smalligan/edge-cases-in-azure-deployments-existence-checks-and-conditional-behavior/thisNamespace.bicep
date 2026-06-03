@description('Resource Naming Prefix')
param prefix string = 'featuredemo'

resource configurationStore 'Microsoft.AppConfiguration/configurationStores@2025-06-01-preview' existing = {
  name: '${prefix}-configurationStore'

  resource featureFlag 'keyValues' = {
    name: '.appconfig.featureflag~2Fenablement'
    properties: {
      value: this.existingResource().?properties.value ?? string({
        id: 'featureFlagName'
        description: 'Enables beta feature for testing'
        enabled: false
      })
      contentType: 'application/vnd.microsoft.appconfig.ff+json;charset=utf-8'
    }
  }
}
