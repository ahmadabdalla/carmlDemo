targetScope = 'subscription'

param identifier string = 'carmldemo'
param  resourceGroupNameCore string = 'rg-${identifier}-core'

// Resource Group
module resourceGroup 'ts/CoreSpecs:resources.resourcegroups:latest' = {
  name: '${uniqueString(deployment().name)}-rg'
  params: {
    name: resourceGroupNameCore
  }
}

// Network Security Groups
module nsg_subnet_bastion 'ts/CoreSpecs:network.networksecuritygroups:latest' = {
  scope: az.resourceGroup(resourceGroupNameCore)
  name: '${uniqueString(deployment().name)}-nsg-sn-bastionSubnet-vnet'
  dependsOn: [
    resourceGroup
  ]
  params: {
    name: 'nsg-sn-bastionSubnet-vnet-${identifier}'
    securityRules: [
      {
        name: 'AllowHttpsInBound'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationPortRange: '443'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowGatewayManagerInBound'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: 'GatewayManager'
          destinationPortRange: '443'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 110
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowLoadBalancerInBound'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: 'AzureLoadBalancer'
          destinationPortRange: '443'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 120
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowBastionHostCommunicationInBound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationPortRanges: [
            '8080'
            '5701'
          ]
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 130
          direction: 'Inbound'
        }
      }
      {
        name: 'DenyAllInBound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationPortRange: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 1000
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowSshRdpOutBound'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationPortRanges: [
            '22'
            '3389'
          ]
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 100
          direction: 'Outbound'
        }
      }
      {
        name: 'AllowAzureCloudCommunicationOutBound'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationPortRange: '443'
          destinationAddressPrefix: 'AzureCloud'
          access: 'Allow'
          priority: 110
          direction: 'Outbound'
        }
      }
      {
        name: 'AllowBastionHostCommunicationOutBound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationPortRanges: [
            '8080'
            '5701'
          ]
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 120
          direction: 'Outbound'
        }
      }
      {
        name: 'AllowGetSessionInformationOutBound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'Internet'
          destinationPortRanges: [
            '80'
            '443'
          ]
          access: 'Allow'
          priority: 130
          direction: 'Outbound'
        }
      }
      {
        name: 'DenyAllOutBound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 1000
          direction: 'Outbound'
        }
      }
    ]
  }
}

module nsg_subnet_default 'ts/CoreSpecs:network.networksecuritygroups:latest' = {
  scope: az.resourceGroup(resourceGroupNameCore)
  name: '${uniqueString(deployment().name)}-nsg-sn-default-vnet'
  dependsOn: [
    resourceGroup
  ]
  params: {
    name: 'nsg-sn-default-vnet-${identifier}'
  }
}

// Virtual Network
module virtualNetwork 'ts/CoreSpecs:network.virtualnetworks:latest' = {
  scope: az.resourceGroup(resourceGroupNameCore)
  name: '${uniqueString(deployment().name)}-vnet'
  params: {
    addressPrefixes: [
      '10.0.0.0/16'
    ]
    name: 'vnet-${identifier}'
    subnets: [
      {
        addressPrefix: '10.0.0.0/24'
        name: 'AzureBastionSubnet'
        networkSecurityGroupId: nsg_subnet_bastion.outputs.resourceId
      }
      {
        addressPrefix: '10.0.1.0/24'
        name: 'sn-default-vnet-${identifier}'
        networkSecurityGroupId: nsg_subnet_default.outputs.resourceId
      }
    ]
  }
}

// Azure Bastion - Public IP
module publicIpBastion 'ts/CoreSpecs:network.publicipaddresses:latest' = {
  scope: az.resourceGroup(resourceGroupNameCore)
  name: '${uniqueString(deployment().name)}-bst-pip'
  params: {
    name: 'pip-bst-vnet-${identifier}'
    skuName: 'Standard'
    publicIPAllocationMethod: 'Static'
  }
  dependsOn: [
    resourceGroup
  ]
}

// Azure Bastion
module azureBastion 'ts/CoreSpecs:network.bastionhosts:latest' = {
  scope: az.resourceGroup(resourceGroupNameCore)
  name: '${uniqueString(deployment().name)}-bst'
  params: {
    name: 'bst-vnet-${identifier}'
    vNetId: virtualNetwork.outputs.resourceId
    skuName: 'Basic'
    isCreateDefaultPublicIP: false
    bastionSubnetPublicIpResourceId: publicIpBastion.outputs.resourceId
  }
}

// Private DNS Zone for Azure Key Vault
module privateDnsZoneKeyVault 'ts/CoreSpecs:network.privatednszones:latest' = {
  scope: az.resourceGroup(resourceGroupNameCore)
  name: '${uniqueString(deployment().name)}-prdns-kv'
  params: {
    name: 'privatelink.vaultcore.azure.net'
    virtualNetworkLinks: [
      {
        registrationEnabled: false
        virtualNetworkResourceId: virtualNetwork.outputs.resourceId
      }
    ]
  }
}

output workloadSubnetResourceId string = virtualNetwork.outputs.subnetResourceIds[1]
output privateDnsZoneKeyVaultResourceId string = privateDnsZoneKeyVault.outputs.resourceId
