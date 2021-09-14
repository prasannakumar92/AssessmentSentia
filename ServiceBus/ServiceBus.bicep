// // ServiceBus
// resource ServiceBus 'Microsoft.ServiceBus/namespaces@2021-06-01-preview'={
//   name:'${environment}-${ApplicationName}svb'
//   location:Location
//   tags:tagvalue
//   sku:{
//     name:'Basic'
//     tier:'Basic'
//     capacity:1
//   }
// }

// resource ServiceBusQueue 'Microsoft.ServiceBus/namespaces/queues@2021-01-01-preview' = {
//   parent: ServiceBus
//   name: '${environment}-${ApplicationName}svb-Queue'
//   properties: {
//     lockDuration:''
//     maxSizeInMegabytes:1024
//     requiresDuplicateDetection: true
//     requiresSession: true
//     defaultMessageTimeToLive: '5'
//     deadLetteringOnMessageExpiration: true
//     maxDeliveryCount:10
//   }
// }
