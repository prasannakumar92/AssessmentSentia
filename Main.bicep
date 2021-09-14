param storagetierName string
param storagetier string
param Location string = resourceGroup().location
param aspSkuName string
param aspSkutier string
param environment string
param ApplicationName string

@description('Address prefix')
param VnetAddressSpace string
param tagvalue object =  {
  environment: environment
  Application: ApplicationName
}
param VnetSubNetAddress array 
param buildvmsubnetId string

var commonStorageAccountName = '${ApplicationName}commonstrg'
var kvResourceGroup = '${ApplicationName}-COMMON-RG'
var kvName = '${ApplicationName}commonkv'
var SubsvriptionID = subscription().subscriptionId


resource kv 'Microsoft.KeyVault/vaults@2019-09-01' existing = {
  name: kvName
  scope: resourceGroup(kvResourceGroup)
}

// Virtual Network
module VirtualNetworkModule 'VirtualNetwork/Network.bicep'  = {
  name: '${environment}${ApplicationName}vnet'
  params:{
    ApplicationName: ApplicationName
    environment: environment
    Location: Location
    tagvalue: tagvalue
    VnetAddressSpace:VnetAddressSpace
    VnetSubNetAddress: VnetSubNetAddress
  }
}

//Storage Account
module storageModule 'Storage/storage.bicep' ={
  name : '${environment}${ApplicationName}strg'
  dependsOn:[
    VirtualNetworkModule
  ]
  params:{
    ApplicationName:ApplicationName
    buildvmsubnetId:buildvmsubnetId
    environment: environment
    Location: Location
    storagetier: storagetier
    storagetierName: storagetierName
  }
}

var StorageAccountName = storageModule.outputs.StorageName

//Create Storage File Share
resource Storage_Fileshare 'Microsoft.Storage/storageAccounts/fileServices/shares@2021-04-01'={
  name: toLower('${environment}${ApplicationName}strg/default/${environment}${ApplicationName}sftp')
  dependsOn:[
    storageModule
    //FTP_VirtualMachine
  ]
}

//Create CosmosDB
module CosmosDB 'CosmosDB/cosmosDB.bicep' = {
  name:'${environment}${ApplicationName}cosmo'
  dependsOn:[
    VirtualNetworkModule
  ]
  params:{
    ApplicationName: ApplicationName
    environment: environment
    buildvmsubnetId: buildvmsubnetId
    Location: Location
    tagvalue: tagvalue
  }
}

//Create ASP and Web App
module AppPlan_WebApp 'WebApps/AppServices.bicep'={
  name: '${environment}${ApplicationName}ASP_APP'
  dependsOn:[
    CosmosDB
    VirtualNetworkModule
    ApplicationInsight
  ]
  params:{
    ApplicationName:ApplicationName
    environment: environment
    aspLocation: Location
    aspSkuName: aspSkuName
    aspSkutier: aspSkutier
    tagvalue: tagvalue
    ApplicationInsightsKey: reference(ApplicationInsight.id, ApplicationInsight.apiVersion).InstrumentationKey
  }
}

//Create Function ASP and App
module FunctionAsp_App 'FunctionApp/FunctionsApp.bicep' = {
  name: '${environment}-${ApplicationName}Func'
  dependsOn:[
    AppPlan_WebApp
  ]
  params:{
    ApplicationName:ApplicationName
    environment: environment
    Location: Location
    tagvalue: tagvalue
    ApplicationInsightsKey:reference(ApplicationInsight.id, ApplicationInsight.apiVersion).InstrumentationKey
  }
}

//Create NSG NIC AND PIP for FTP
module FTP_NSG_NIC_PIP 'NSG-NIC-PIP/NSG-NIC-PIP.bicep'={
  name: '${environment}-${ApplicationName}_FTP_NSG'
  dependsOn:[
    VirtualNetworkModule
  ]
  params:{
    ApplicationName:ApplicationName
    environment: environment
    Location: Location
    VMType : 'FTP'
  }
}

//Create Virtual Machine for FTP
module FTP_VirtualMachine 'VirtualMachine_FTP/VirtualMachine_FTP.bicep'={
  dependsOn:[
    FTP_NSG_NIC_PIP
  ]
  name:'${environment}-${ApplicationName}FTP'
  params:{
    adminPassword: kv.getSecret('vmadminPassword')
    ClientID: kv.getSecret('ClientID')
    ClientSecret: kv.getSecret('ClientSecret')
    SubscriptionID:SubsvriptionID
    tenantID:kv.getSecret('tenantID')
    ApplicationName:ApplicationName
    environment: environment
    Location: Location
    NIC_ID: FTP_NSG_NIC_PIP.outputs.NIC_id
    tagvalue: tagvalue
    scriptName:'mount.sh'
    commonStorageName: commonStorageAccountName
    commandToExecute : 'sh mount.sh ${resourceGroup().name} ${StorageAccountName}'
    VMType : 'FTP'
    FTPMountName:'${environment}${ApplicationName}sftp'
  }
}

//Create NSG NIC AND PIP for KIbana
module Kibana_NSG_NIC_PIP 'NSG-NIC-PIP/NSG-NIC-PIP.bicep' ={
  name:'${environment}-${ApplicationName}_Kibana_NSG'
  dependsOn:[
    VirtualNetworkModule
    FTP_NSG_NIC_PIP
  ]
  params:{
    ApplicationName:ApplicationName
    environment: environment
    Location: Location
    VMType : 'Kibana'
  }
}

//Create Virtual Machine for FTP
module Kibana_VirtualMachine 'VirtualMachine_Kibana/VirtualMachine_Kibana.bicep'={
  name:'${environment}-${ApplicationName}Kibana'
  dependsOn:[
    Kibana_NSG_NIC_PIP
    FTP_VirtualMachine
  ]
  params:{
    adminPassword: kv.getSecret('vmadminPassword')
    ApplicationName:ApplicationName
    environment: environment
    Location: Location
    NIC_ID: Kibana_NSG_NIC_PIP.outputs.NIC_id
    tagvalue: tagvalue
    scriptName:'installKibana.sh'
    commonStorageName: commonStorageAccountName
    commandToExecute : 'sh installKibana.sh'
    VMType : 'Kibana'
  }
}

//Create Traffic Manager Profile and Endpoints
resource TrafficMangerProfile 'Microsoft.Network/trafficmanagerprofiles@2018-08-01' = {
  dependsOn:[
    AppPlan_WebApp
  ]
  name: toLower('${environment}${ApplicationName}TM')
  location:'global'
  tags:tagvalue
  properties:{
    dnsConfig:{
      relativeName:'${environment}${ApplicationName}TM'
      ttl:180
    }
    profileStatus:'Enabled'
    trafficRoutingMethod:'Priority'
    monitorConfig: {
      protocol: 'HTTPS'
      port: 443
      path: '/'
    }
    endpoints:[
      {
        name:'Primary'
        type: 'Microsoft.Network/trafficManagerProfiles/azureEndpoints'
        properties:{
          targetResourceId:AppPlan_WebApp.outputs.WebAppID
          endpointStatus:'Enabled'
          priority:1
        }
      }
      {
        name:'Maintenenace-Example'
        type: 'Microsoft.Network/trafficManagerProfiles/externalEndpoints'
        properties:{
          target:'www.google.com'
          endpointStatus:'Disabled'
          endpointLocation:AppPlan_WebApp.outputs.WebAppLocation
          priority:2
        }
      }
    ]
  }
}

//Create Application Insights
resource ApplicationInsight 'Microsoft.Insights/components@2020-02-02'={
  name: toLower('${environment}${ApplicationName}AppInsight')
  location:Location
  tags:tagvalue
  kind:'web'
  properties:{
    Application_Type:'web'
    publicNetworkAccessForIngestion:'Enabled'
    publicNetworkAccessForQuery:'Enabled'
  }
}

//Create PrivateLinkScop for Application Insights
resource PrivateLinkScope 'microsoft.insights/privateLinkScopes@2019-10-17-preview'={
  name: toLower('${environment}${ApplicationName}PEScope')
  location:'global'
  tags:tagvalue
  properties:{}
}

resource symbolicname 'Microsoft.Insights/privateLinkScopes/scopedResources@2019-10-17-preview' = {
  name: toLower('${environment}${ApplicationName}PEScope/${environment}${ApplicationName}PE_AI')
  dependsOn:[
    PrivateLinkScope
    PrivateEndpoint
  ]
  properties: {
    linkedResourceId: ApplicationInsight.id
  }
}

//Create Private Endpoint to restrict access to AI
resource PrivateEndpoint 'Microsoft.Network/privateEndpoints@2021-02-01'={
  name: toLower('${environment}${ApplicationName}PEP')
  location:Location
  dependsOn:[
    VirtualNetworkModule
    ApplicationInsight
    PrivateLinkScope
  ]
  tags:tagvalue
  properties:{
    privateLinkServiceConnections:[
      {
        name:'${environment}${ApplicationName}PEAI'
        properties:{
          privateLinkServiceId:PrivateLinkScope.id
          groupIds:[
            'azuremonitor'
          ]
        }
      }
    ]
    subnet:{
      id:resourceId('Microsoft.Network/virtualNetworks/subnets','${environment}${ApplicationName}vnet','${environment}${ApplicationName}vnet_subnet_PEP')
    }
    
  }
}
