param location string = resourceGroup().location

// create the azure container registry
resource acr 'Microsoft.ContainerRegistry/registries@2021-09-01' = {
  name: toLower('${resourceGroup().name}acr')
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: true
  }
}

// create the aca environment
module env 'environment.bicep' = {
  name: 'containerAppEnvironment'
  params: {
    location: location
  }
}

// create a signalr service instance
resource signalr 'Microsoft.SignalRService/signalR@2022-02-01' = {
  name: toLower('${resourceGroup().name}signalr')
  kind: 'SignalR'
  location: location
  sku: {
    capacity: 1
    name: 'Standard_S1'
  }
  properties: {
    features: [
      {
        flag: 'ServiceMode'
        value: 'Default'
      }
    ]
  }
}

resource storage 'Microsoft.Storage/storageAccounts@2021-09-01' = {
  name: toLower('${resourceGroup().name}strg')
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
}

resource keyVault 'Microsoft.KeyVault/vaults@2019-09-01' = {
  name: toLower('${resourceGroup().name}kv')
  location: location
  properties: {
    enabledForDeployment: true
    enabledForTemplateDeployment: true
    enabledForDiskEncryption: true
    tenantId: subscription().tenantId
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId: blazorserver.outputs.ident
        permissions: {
          keys: [
            'get'
            'unwrapKey'
            'wrapKey'
          ]
          secrets: [
            'list'
            'get'
          ]
        }
      }
    ]
    sku: {
      name: 'standard'
      family: 'A'
    }
  }
}

resource key 'Microsoft.KeyVault/vaults/keys@2021-11-01-preview' = {
  name: 'dataprotection'
  parent: keyVault
  properties: {
    
  }
}

// create the various config pairs
var shared_config = [
  {
    name: 'ASPNETCORE_ENVIRONMENT'
    value: 'Development'
  }
  {
    name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
    value: env.outputs.appInsightsInstrumentationKey
  }
  {
    name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
    value: env.outputs.appInsightsConnectionString
  }
  {
    name: 'AZURE_SIGNALR_CONNECTIONSTRING'
    value: signalr.listKeys().primaryConnectionString
  }
  {
    name: 'AZURE_STORAGE_CONNECTIONSTRING'
    value: format('DefaultEndpointsProtocol=https;AccountName=${storage.name};AccountKey=${storage.listKeys().keys[0].value};EndpointSuffix=core.windows.net')
  }
  {
    name: 'ASPNETCORE_LOGGING__CONSOLE__DISABLECOLORS'
    value: 'true'
  }
  {
    name: 'KEYS_BLOB_CONTAINER'
    value: 'keys'
  }
  {
    name: 'KEY_VAULT_NAME'
    value: toLower('${resourceGroup().name}kv')
  }
  {
    name: 'KEY_VAULT_KEY'
    value: 'dataprotection'
  }
]

// create the products api container app
module blazorserver 'container_app.bicep' = {
  name: 'blazorserver'
  params: {
    name: 'blazorserver'
    location: location
    registryPassword: acr.listCredentials().passwords[0].value
    registryUsername: acr.listCredentials().username
    containerAppEnvironmentId: env.outputs.id
    registry: acr.name
    envVars: shared_config
    externalIngress: true
  }
}
