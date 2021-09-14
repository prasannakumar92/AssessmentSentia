param environment string
param ApplicationName string
param Location string
param storagetierName string
param storagetier string
param buildvmsubnetId string

var storageaname = toLower('${environment}${ApplicationName}strg')

// storageAccounts
resource storage 'Microsoft.Storage/storageAccounts@2021-04-01'={
  name:storageaname
  location: Location
  tags:{}
  sku:{
    name:storagetierName
    tier:storagetier
  }
  kind:'Storage'
  properties:{
    networkAcls:{
      defaultAction:'Allow'
      virtualNetworkRules:[
        {
          action: 'Allow'
          id: resourceId('Microsoft.Network/virtualNetworks/subnets','${environment}${ApplicationName}vnet','${environment}${ApplicationName}vnet_App_Subnet')
        }
        {
          action: 'Allow'
          id: resourceId('Microsoft.Network/virtualNetworks/subnets','${environment}${ApplicationName}vnet','${environment}${ApplicationName}vnet_subnet_VM')
        }
        {
          action: 'Allow'
          id: resourceId('Microsoft.Network/virtualNetworks/subnets','${environment}${ApplicationName}vnet','${environment}${ApplicationName}vnet_subnet_PEP')
        }
        {
          action: 'Allow'
          id:buildvmsubnetId
        }
      ]
    }
  }
}

output StorageName string = storage.name
