
param(
    [parameter(mandatory=$true)][string]$Environment,
    [parameter(mandatory=$true)][string]$Application,
    [parameter(mandatory=$true)][string]$location,
    [parameter(mandatory=$false)][string]$ResourceGroup = "$($Environment)-$($Application)-RG",
    [parameter(mandatory=$true)][string]$TemplateFilePath,
    [parameter(mandatory=$true)][string]$TemplateParameterFilePath
)

$DateTime = (Get-Date).ToString("yyyyMMddHHmm")

# create a resource group
az group create -n $ResourceGroup.ToUpper() -l $Location

# deploy the bicep file directly
az deployment group create --name "$($Environment)-$($Application)_RG_$($DateTime)" --resource-group $ResourceGroup.ToUpper() --template-file $TemplateFilePath --parameters $TemplateParameterFilePath