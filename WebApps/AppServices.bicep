param aspLocation string
param aspSkuName string
param aspSkutier string
param environment string
param ApplicationName string
param tagvalue object
param ApplicationInsightsKey string

//App service Plan
resource AppServicePlan 'Microsoft.Web/serverfarms@2021-01-15' = {
  name: toLower('${environment}${ApplicationName}_asp')
  location: aspLocation
  kind: 'linux'
  tags: tagvalue
  sku:{
    name:aspSkuName
    tier:aspSkutier
  }
  properties:{
    reserved:true
  }
}

// WebApps
resource WebApp 'Microsoft.Web/sites@2021-01-15'={
  name: toLower('${environment}${ApplicationName}app')
  dependsOn:[
    AppServicePlan
  ]
  location:aspLocation
  kind:'linux'
  tags:{}
  properties:{
    serverFarmId:AppServicePlan.id
    clientAffinityEnabled:true
    siteConfig:{
      appSettings:[
        {
          name:'APPINSIGHTS_INSTRUMENTATIONKEY'
          value:ApplicationInsightsKey
        }
      ]
      alwaysOn:true
    }
  }
}

// WebApps Deployment Slot
resource WebAppSlots 'Microsoft.Web/sites/slots@2021-01-15'= if(environment == 'PROD' || environment == 'ACC'  ) {
  dependsOn:[
    WebApp
  ]
  name: toLower('${WebApp.name}/${WebApp.name}slot')
  location:aspLocation
  kind:'linux'
  tags:tagvalue
  properties:{
    serverFarmId:AppServicePlan.id
    siteConfig:{
      appSettings:[
        {
          name:'APPINSIGHTS_INSTRUMENTATIONKEY'
          value:ApplicationInsightsKey
        }
      ]
      alwaysOn:true
    }
  }
}

resource AutoScaling 'Microsoft.Insights/autoscalesettings@2015-04-01' = if(environment == 'PROD' || environment == 'ACC'  ) {
  dependsOn:[
    WebApp
    WebAppSlots
  ]
  name: toLower('${environment}${ApplicationName}_asp_autoscaling')
  location:aspLocation
  properties:{
    enabled:true
    targetResourceUri:AppServicePlan.id
    profiles:[
      {
        name:'${environment}${ApplicationName}'
        capacity:{
          minimum:'2'
          maximum:'10'
          default:'2'
        }
        rules:[
          {
            metricTrigger:{
              metricName:'CpuPercentage'
              metricResourceUri:AppServicePlan.id
              timeGrain:'PT5M'
              timeAggregation:'Average'
              operator:'GreaterThan'
              threshold:80
              statistic:'Average'
              timeWindow:'PT10M'
            }
            scaleAction:{
              direction:'Increase'
              type:'ChangeCount'
              value:'1'
              cooldown:'PT10M'

            }
          }
          {
            metricTrigger:{
              metricName:'CpuPercentage'
              metricResourceUri:AppServicePlan.id
              timeGrain:'PT5M'
              timeAggregation:'Average'
              operator:'LessThan'
              threshold:40
              statistic:'Average'
              timeWindow:'PT10M'
            }
            scaleAction:{
              direction:'Decrease'
              type:'ChangeCount'
              value:'1'
              cooldown:'PT10M'

            }
          }
        ]
      }
    ]
  }
}


output WebAppName string = WebApp.name
output WebAppLocation string = WebApp.location
output WebAppID string = WebApp.id

