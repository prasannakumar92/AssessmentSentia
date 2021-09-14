
param environment string
param ApplicationName string
param Location string
param tagvalue object
@secure()
param adminPassword string
param NIC_ID string
param scriptName string
param commonStorageName string
param commandToExecute string
param VMType string

resource VirtualMachines 'Microsoft.Compute/virtualMachines@2021-04-01' = {
  name: toLower('${environment}${ApplicationName}${VMType}')
  location:Location
  tags:tagvalue
  properties:{
    hardwareProfile:{
      vmSize:'Standard_B1s'
    }
    osProfile:{
      adminPassword: adminPassword
      adminUsername:'${environment}${ApplicationName}${VMType}'
      allowExtensionOperations:true
      computerName:'${environment}${ApplicationName}${VMType}'
    }
    storageProfile:{
      osDisk:{
        createOption:'FromImage'
        managedDisk:{
          storageAccountType:'Standard_LRS'
        }
      }
      imageReference:{
        offer: '0001-com-ubuntu-server-focal'
        publisher: 'canonical'
        sku: '20_04-lts'
        version: 'latest'
       }
    }
    networkProfile:{
      networkInterfaceConfigurations:[]
      networkInterfaces:[
        {
          id:NIC_ID
        }
      ]
    }
  }
}


// resource vmName_installcustomscript 'Microsoft.Compute/virtualMachines/extensions@2020-12-01' = {
//   parent: VirtualMachines
//   name: 'installcustomscript'
//   location: Location
//   properties: {
//     publisher: 'Microsoft.Azure.Extensions'
//     type: 'CustomScript'
//     typeHandlerVersion: '2.1'
//     autoUpgradeMinorVersion: true
//     settings: {
//       fileUris: [
//         uri('https://${commonStorageName}.blob.core.windows.net/vmextensions/Scripts/', scriptName)
//       ]
//       commandToExecute: concat(commandToExecute)
//     }
//   }
// }
