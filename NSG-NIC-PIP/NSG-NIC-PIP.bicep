param environment string
param ApplicationName string
param Location string
param VMType string

resource publicIP 'Microsoft.Network/publicIPAddresses@2020-05-01' = {
  name: toLower('${environment}${ApplicationName}${VMType}_PIP')
  location: Location
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource NIC 'Microsoft.Network/networkInterfaces@2020-05-01' = {
  name: toLower('${environment}${ApplicationName}${VMType}_nic')
  location: Location
  dependsOn:[
    publicIP
    NSG
  ]
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          publicIPAddress: {
            id: publicIP.id
          }
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets','${environment}${ApplicationName}vnet','${environment}${ApplicationName}vnet_subnet_VM')
          }
        }
      }
    ]
    networkSecurityGroup:{
        id: NSG.id
    }
  }
}

resource NSG 'Microsoft.Network/networkSecurityGroups@2020-05-01' = {
  name: toLower('${environment}${ApplicationName}${VMType}_nsg')
  location: Location
  properties: {
    securityRules: [
      {
        name: 'SSH'
        properties: {
          description: 'Allows SSH traffic'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
    ]
  }
}


output NIC_id string = NIC.id
