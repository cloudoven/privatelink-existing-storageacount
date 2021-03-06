
# How to create private link to existing storage account

## Bicep templates

### Subnet 
Template for subnet

```Bicep
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
```

### Private Endpoint
```
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
```


### Private DNS Zone

```
resource dnszone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: dnsZoneName
  location: 'global'
}
```


### VNet links
```
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
```


### DNS Zone group 

```
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

```

## Deploy to Azure 

```
az deployment group create --resource-group gaga --template-file .\template.bicep  
```

Finally you need to disable public access from all network using Storage firewall. The below command will do that.

## Disable public access from all network (except Private link)
```
    az storage account update --name MyStorageAccount --resource-group MyResourceGroup --public-network-access Disabled
```