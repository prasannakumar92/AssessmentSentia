
param environment string
param ApplicationName string
param Location string
param tagvalue object
param buildvmsubnetId string


var CosmosDBname = toLower('${environment}${ApplicationName}cosmo')

 // CosmosDB
 resource CosmosDb 'Microsoft.DocumentDB/databaseAccounts@2021-06-15'={
   name:CosmosDBname
   location:Location
   tags:tagvalue
   kind:'MongoDB'
   properties:{
     databaseAccountOfferType: 'Standard'
     isVirtualNetworkFilterEnabled:true
     virtualNetworkRules:[
        {
          //action: 'Allow'
          id: resourceId('Microsoft.Network/virtualNetworks/subnets','${environment}${ApplicationName}vnet','${environment}${ApplicationName}vnet_App_Subnet')
        }
        {
          //action: 'Allow'
          id: resourceId('Microsoft.Network/virtualNetworks/subnets','${environment}${ApplicationName}vnet','${environment}${ApplicationName}vnet_subnet_VM')
        }
        {
          //action: 'Allow'
          id: resourceId('Microsoft.Network/virtualNetworks/subnets','${environment}${ApplicationName}vnet','${environment}${ApplicationName}vnet_subnet_PEP')
        }
        {
          //action: 'Allow'
          id:buildvmsubnetId
        }
     ]
     enableFreeTier:true
     apiProperties:{
       serverVersion:'4.0'
     }
     capabilities:[
       {
         name:'enableserverless'
       }
     ]
   }
 }


 output CosmosDbName string = CosmosDb.name
 output CosmosDbType string = CosmosDb.type
