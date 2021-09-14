
param environment string
param ApplicationName string
param Location string
param tagvalue object
param ApplicationInsightsKey string

// Function Plans - Consumption
resource FuncAppServicePlan 'Microsoft.Web/serverfarms@2021-01-15' = {
  name: '${environment}${ApplicationName}_Func_asp'
  location: Location
  tags: tagvalue
  sku:{
    name: 'Y1'
    tier: 'Dynamic'
  }
}

// Functions  for Cron Jobs
resource FunctionApp 'Microsoft.Web/sites@2021-01-15'={
  name: toLower('${environment}${ApplicationName}Funcapp')
  location:Location
  dependsOn:[
    FuncAppServicePlan
  ]
  kind:'functionapp'
  tags:tagvalue
  properties:{
    serverFarmId:FuncAppServicePlan.id
    siteConfig:{
      appSettings:[
        {
          name:'APPINSIGHTS_INSTRUMENTATIONKEY'
          value:ApplicationInsightsKey
        }
      ]
    }
  }
}

