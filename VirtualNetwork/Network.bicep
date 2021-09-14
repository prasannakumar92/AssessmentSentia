param environment string
param ApplicationName string
param Location string
param tagvalue object
param VnetAddressSpace string
param VnetSubNetAddress array

// Virtual Network
resource VirtualNetwork 'Microsoft.Network/virtualNetworks@2021-02-01' = {
  name: toLower('${environment}${ApplicationName}vnet')
  location:Location
  tags:tagvalue
  properties:{
    addressSpace: {
     addressPrefixes: [
       VnetAddressSpace
      ]
    }
    subnets: [for subnet in VnetSubNetAddress:{
      name:'${environment}${ApplicationName}vnet_${subnet.name}'
      properties:{
        addressPrefix:subnet.AddressPrefix
        serviceEndpoints:[
          {
            service: 'Microsoft.Storage'
          }
          {
            service: 'Microsoft.Web'
          }
          {
            service: 'Microsoft.AzureCosmosDB'
          }
          {
            service: 'Microsoft.ServiceBus'
          }
          {
            service: 'Microsoft.KeyVault'
          }
        ]
        privateEndpointNetworkPolicies: 'Disabled'
        privateLinkServiceNetworkPolicies: 'Enabled'
      }
    }]
  }
}
