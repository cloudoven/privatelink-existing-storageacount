
@description('Location for all resources.')
param location string = resourceGroup().location

var subscriptionId = ''

var vnetId = '/subscriptions/${subscriptionId}/resourceGroups/gaga/providers/Microsoft.Network/virtualNetworks/gaga-vnet'
var dnsZoneName = 'privatelink.blob.core.windows.net'
var endpointName = 'privlinkmoimhawe'
var subnetId = '/subscriptions/${subscriptionId}/resourceGroups/gaga/providers/Microsoft.Network/virtualNetworks/gaga-vnet/subnets/default'
var nsgId = '/subscriptions/${subscriptionId}/resourceGroups/gaga/providers/Microsoft.Network/networkSecurityGroups/gaga-vnet-default-nsg-westeurope'
var storageAccountId = '/subscriptions/${subscriptionId}/resourceGroups/gaga/providers/Microsoft.Storage/storageAccounts/moimhawe'


resource subnet 'Microsoft.Network/virtualNetworks/subnets@2022-01-01' = {
  name: 'gaga-vnet/default'  
  properties: {
    addressPrefix: '10.0.0.0/24'
    delegations: []
    serviceEndpoints: []
    privateEndpointNetworkPolicies: 'Disabled'
    privateLinkServiceNetworkPolicies: 'Enabled'  
    networkSecurityGroup: {
      id: nsgId
    }    
  }
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2022-01-01' = {
  dependsOn: [
    subnet
  ]
  location: location
  name: endpointName
  properties: {
    subnet: {
      id: subnetId
    }
    customNetworkInterfaceName: '${endpointName}-nic'
    privateLinkServiceConnections: [
      {
        name: endpointName
        properties: {
          privateLinkServiceId: storageAccountId
          groupIds: [ 'blob' ]
        }
      }
    ]
  }
}

resource dnszone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: dnsZoneName
  location: 'global'
}


resource vnetLinks 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${dnsZoneName}/${uniqueString(vnetId)}'  
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetId
    }
  }
}

resource dnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2022-01-01' = {
  dependsOn: [
    privateEndpoint
  ]
  name: '${endpointName}/default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink-blob-core-windows-net'
        properties: {
          privateDnsZoneId: dnszone.id
        }
      }
    ]
  }
}
