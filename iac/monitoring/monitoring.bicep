param config object
param networking object

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-12-01-preview' = {
  name: '${config.namePrefix}-lgw'
  location: config.location

  properties:{
   sku: {
    name: 'PerGB2018'
   } 
  } 
  tags: config.tags
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: '${config.namePrefix}-ai'
  location: config.location
  kind: ''
  properties: {
    Application_Type: ' '
    WorkspaceResourceId: logAnalyticsWorkspace.id
  }
  tags: config.tags
}


resource privateLinkScope 'microsoft.insights/privateLinkScopes@2021-07-01-preview' = {
  name: '${config.namePrefix}-pes'
  location: 'global'
  properties: {
    accessModeSettings: {
      ingestionAccessMode: 'PrivateOnly'
      queryAccessMode: 'PrivateOnly'
    }
  }
  tags: config.tags
}

module privateEndpoint '../networking/private-endpoint.bicep' = {
  name: 'pesPrivateEndpoint'
  params: {
    config: config
    dnsZones: {
      mon: networking.privateDnsZones.mon
      ods: networking.privateDnsZones.ods
      oms: networking.privateDnsZones.oms
      asc: networking.privateDnsZones.asc
      bl: networking.privateDnsZones.bl
    }
    endpointType: 'azuremonitor'
    parentId: privateLinkScope.id
    parentName: privateLinkScope.name
    subnetId: networking.mainSubnetId
  }
}

resource privateLinkScopeLogAnalyticsConnection 'Microsoft.Insights/privateLinkScopes/scopedResources@2021-07-01-preview' = {
  name: '${privateLinkScope.name}-log-connection'
  parent: privateLinkScope
  properties: {
    linkedResourceId: logAnalyticsWorkspace.id
  }

  dependsOn: [
    privateEndpoint    
  ]
}

resource privateLinkScopeAppInsightsConnection 'Microsoft.Insights/privateLinkScopes/scopedResources@2021-07-01-preview' = {
  name: '${privateLinkScope.name}-ai-connection'
  parent: privateLinkScope
  properties: {
    linkedResourceId: appInsights.id
  }

  dependsOn: [
    privateEndpoint    
  ]
}

output values object = {
  logAnalyticsWorkspaceId: logAnalyticsWorkspace.id
}
