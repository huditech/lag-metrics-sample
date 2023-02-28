param location string = resourceGroup().location

param notificationEmailAddress string

var uniqueId = uniqueString(resourceGroup().id)
var storageKey = listKeys(storageAccount.id, '2021-06-01').keys[0].value
var storageName = 'lagmetrics${uniqueId}'
var eventHubNamespaceName = 'lagmetrics${uniqueId}'
var eventHubName = 'example-event-hub'
var applicationInsightsName = 'lagmetrics${uniqueId}'

var actionGroupName = 'example-action-group'
var alertRuleName = 'example-lag-alert'

var offsetContainerName = 'event-hub-checkpoints'

var storageConnectionString = 'DefaultEndpointsProtocol=https;AccountName=${storageName};AccountKey=${storageKey};EndpointSuffix=${environment().suffixes.storage}'
var eventHubConnectionString = listKeys(eventHubs::monitorAuthRule.id, eventHubs::monitorAuthRule.apiVersion).primaryConnectionString

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: storageName
  kind: 'StorageV2'
  location: location
  sku: {
    name: 'Standard_LRS'
  }

  resource blobService 'blobServices@2021-04-01' = {
    name: 'default'
    resource eventHubCheckpointsContainer 'containers@2021-04-01' = {
      name: offsetContainerName
    }
  }
}

resource eventHubs 'Microsoft.EventHub/namespaces@2021-06-01-preview' = {
  name: eventHubNamespaceName
  location: location
  sku: {
    name: 'Basic'
    tier: 'Basic'
    capacity: 1
  }
  properties: {
    disableLocalAuth: false
    zoneRedundant: false
    isAutoInflateEnabled: false
    kafkaEnabled: false
  }

  resource eventHub 'eventhubs@2021-06-01-preview' = {
    name: eventHubName
    properties: {
      messageRetentionInDays: 1
      partitionCount: 4
      status: 'Active'
    }
  }

  resource monitorAuthRule 'authorizationRules@2021-11-01' = {
    name: 'monitorAuthRule'
    properties: {
      rights: [
        'Manage'
        'Listen'
        'Send'
      ]
    }
  }

  resource sampleClientAuthRule 'authorizationRules@2021-11-01' = {
    name: 'sampleClientAuthRule'
    properties: {
      rights: [
        'Listen'
        'Send'
      ]
    }
  }
}

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: applicationInsightsName
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
    workspaceCapping: {
      dailyQuotaGb: 1
    }
  }
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: applicationInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspace.id
  }
}

resource managedAppDef 'Microsoft.Solutions/applicationDefinitions@2021-07-01' existing = {
  scope: resourceGroup('55c079e7-8c64-4e3d-b797-a71ebda23e81', 'lag-metrics-definition')
  name: 'lag-metrics'
}

resource managedApp 'Microsoft.Solutions/applications@2021-07-01' = {
  name: 'lag-metrics'
  // TODO: Change to kind: marketplace once published
  kind: 'servicecatalog'
  location: location
  properties: {
    #disable-next-line use-resource-id-functions
    managedResourceGroupId: '${resourceGroup().id}-resources-${uniqueString(resourceGroup().id)}'
    applicationDefinitionId: managedAppDef.id
    parameters: {
      eventHubConnectionString: {
        value: eventHubConnectionString
      }
      storageAccountConnectionString: {
        value: storageConnectionString
      }
      applicationInsightsConnectionString: {
        value: appInsights.properties.ConnectionString
      }
      offsetContainerName: {
        value: storageAccount::blobService::eventHubCheckpointsContainer.name
      }
    }
  }
}

resource alertRule 'microsoft.insights/scheduledqueryrules@2022-06-15' = {
  name: alertRuleName
  location: location
  properties: {
    displayName: 'Lag Alert'
    severity: 3
    enabled: true
    evaluationFrequency: 'PT1M'
    scopes: [
      appInsights.id
    ]
    targetResourceTypes: [
      'microsoft.insights/components'
    ]
    windowSize: 'PT5M'
    criteria: {
      allOf: [
        {
          query: 'customMetrics\n| where name == \'Event Hub Consumer Lag\'\n| extend eventHub=tostring(customDimensions[\'Event Hub\'])\n| extend tostring(consumerGroup=customDimensions[\'Consumer Group\'])\n| extend tostring(partitionId=customDimensions[\'Partition Id\'])\n| summarize lag=sum(value) by timestamp, eventHub, consumerGroup\n\n'
          timeAggregation: 'Maximum'
          metricMeasureColumn: 'lag'
          // By specifying dimensions in this way all combinations of eventHub and consumerGroups are compared to the threshold.
          // See: https://learn.microsoft.com/en-us/azure/azure-monitor/alerts/alerts-metric-multiple-time-series-single-rule#multiple-dimensions-multi-dimension
          dimensions: [
            {
              name: 'eventHub'
              operator: 'Include'
              values: [
                '*'
              ]
            }
            {
              name: 'consumerGroup'
              operator: 'Include'
              values: [
                '*'
              ]
            }
          ]
          operator: 'GreaterThan'
          threshold: 100
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }
    autoMitigate: true
    actions: {
      actionGroups: [
        actionGroup.id
      ]
    }
  }
}

resource actionGroup 'microsoft.insights/actionGroups@2022-06-01' = {
  name: actionGroupName
  location: 'Global'
  properties: {
    groupShortName: 'Lag'
    enabled: true
    emailReceivers: [
      {
        name: 'email'
        emailAddress: notificationEmailAddress
        useCommonAlertSchema: false
      }
    ]
  }
}

#disable-next-line outputs-should-not-contain-secrets
output eventHubConnectionString string = listKeys(eventHubs::sampleClientAuthRule.id, eventHubs::sampleClientAuthRule.apiVersion).primaryConnectionString
output storageConnectionString string = storageConnectionString
output offsetContainerName string = offsetContainerName
output eventHubName string = eventHubName
output appInsightsAppId string = appInsights.properties.AppId
