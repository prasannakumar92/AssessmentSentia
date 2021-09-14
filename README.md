# AssessmentSentia
This following assessment has been hosted on Microsoft Azure Cloud. Current repository contains Infrastructure as Code(IaC) which host complete infra as per mentioned requirments.
Implementation is completey done on Azure Devops Including repository and also for CI anb CD. 

## Table of content
- [Prerequisites](#Prerequisites)
- [Implementation](#Implementation)

## Prerequisites
1) Install Biceps and Azure CLI
      * Following link helps in set up [Azure Bicep and Azure CLI](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/install)
2) Azure Subscription
3) Azure Devops Organization,  DevOps Project
4) Private Build Agent(not mandatory, but good to have)
      * For complete setup I used private agent Pool for all CI and CD.
      * Create Windows VM and configure Agent to run as service to have your private agent. 
      * Ensure you have all Prerequisites installed on agent machine. 
      * Specific to this solution, Powershell Version 5.* and above, Bicep and Azure CLI
5) Create a Service Principle to establish connection between Azure and DevOps.


## Over view of infra Arctecture.
<a >
    <img src="Architecture/Architecture.jpg" alt="Bicep_Moduel_reference" title="Sentia" align="Center" height="500" />
</a>

## Implementation.

Azure Bicep is the new way of IaC to Provision infrastructure in Azure. There are Different way of implementation. 
Declaration of resources has been done form **main.bicep**, where as all the resources and parameter are declare. Following with that, I have separated Azure services into each folder to ensure good understandind.

Now, **main.bicep** templated act as singel source of template, nesting all other templates. bicep utilizes **modules** to refer to other bicep templates as in below image.
<a >
    <img src="images/example1.png" alt="Bicep_Moduel_reference" title="Sentia" align="Center" height="300" />
</a>

