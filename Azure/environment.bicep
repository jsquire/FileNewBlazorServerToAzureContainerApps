param baseName string = resourceGroup().name
param location string = resourceGroup().location

resource logs 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  name: '${baseName}logs'
  location: location
  properties: any({
    retentionInDays: 30
    features: {
      searchVersion: 1
    }
    sku: {
      name: 'PerGB2018'
    }
  })
}

resource storage 'Microsoft.Storage/storageAccounts@2021-02-01' = {
  name: '${baseName}strg'
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Premium_LRS'
  }
}


resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: '${baseName}ai'
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logs.id
  }
}

resource env 'Microsoft.App/managedEnvironments@2022-03-01' = {
  name: '${baseName}env'
  location: location
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logs.properties.customerId
        sharedKey: logs.listKeys().primarySharedKey
      }
    }
  }
}

output id string = env.id
output appInsightsInstrumentationKey string = appInsights.properties.InstrumentationKey
output appInsightsConnectionString string = appInsights.properties.ConnectionString
