targetScope = 'subscription'

param identifier string = 'carmldemo'

param resourceGroupNameWorkload string = 'rg-${identifier}-workload'

@secure()
param virtualMachinePassword string

param subnetResourceId string
param privateDnsZoneKeyVaultResourceId string

// Resource Group
module resourceGroup 'ts/CoreSpecs:resources.resourcegroups:latest' = {
  name: '${uniqueString(deployment().name)}-rg'
  params: {
    name: resourceGroupNameWorkload
  }
}

// Key Vault
module keyVault 'ts/CoreSpecs:keyvault.vaults:latest' = {
  scope: az.resourceGroup(resourceGroupNameWorkload)
  name: '${uniqueString(deployment().name)}-kv'
  params: {
    name: 'kv-${identifier}'
    enableRbacAuthorization: true
    publicNetworkAccess: 'Disabled'
    roleAssignments: [
      {
        roleDefinitionIdOrName: 'Key Vault Secrets Officer'
        principalIds: [
          virtualMachine.outputs.systemAssignedPrincipalId
        ]
        principalType: 'ServicePrincipal'
      }
    ]
    privateEndpoints: [
      {
        privateDnsZoneGroup: {
          privateDNSResourceIds: [
            privateDnsZoneKeyVaultResourceId
          ]
        }
        service: 'vault'
        subnetResourceId: subnetResourceId
        tags: {
          Environment: 'Non-Prod'
          Role: 'DeploymentValidation'
        }
      }
    ]
    enableSoftDelete: false
    enablePurgeProtection: false
  }
}

// Virtual Machine
module virtualMachine 'ts/CoreSpecs:compute.virtualmachines:latest' = {
  scope: az.resourceGroup(resourceGroupNameWorkload)
  name: '${uniqueString(deployment().name)}-vm'
  params: {
    name: 'vm-${identifier}'
    computerName: 'vm-${identifier}'
    adminUsername: 'carmldemo'
    imageReference: {
      publisher: 'microsoftvisualstudio'
      offer: 'visualstudio2022'
      sku: 'vs-2022-comm-latest-ws2022'
      version: 'latest'
    }
    nicConfigurations: [
      {
        ipConfigurations: [
          {
            name: 'ipconfig01'
            subnetResourceId: subnetResourceId
          }
        ]
        nicSuffix: '-nic-01'
      }
    ]
    osDisk: {
      diskSizeGB: '128'
      managedDisk: {
        storageAccountType: 'Premium_LRS'
      }
    }
    osType: 'Windows'
    vmSize: 'Standard_DS1_v2'
    adminPassword: virtualMachinePassword
    systemAssignedIdentity: true
  }
  dependsOn: [
    resourceGroup
  ]
}


