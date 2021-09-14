param(
    [parameter(Mandatory=$true)][string]$Location,
    [parameter(Mandatory=$true)][string]$UploadFilePath,
    [parameter(Mandatory=$true)][string]$ApplicationName
)

##################################################
################### MAIN CODE ####################
##################################################

##Global Variables
$ResourceGroupName = "$($ApplicationName)-COMMON-RG"
$storageAccoutName = "$($ApplicationName)commonstrg"
$ContainerName = "vmextensions"

##Setup work location and Blob name.
Set-Location -Path $UploadFilePath 

write-host "Working on Storage Account"
$CheckIfRGExist = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue

if(!$CheckIfRGExist){
    New-AzResourceGroup -Name $ResourceGroupName -Location $location
}

$StorageAccount = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $storageAccoutName -ErrorAction SilentlyContinue

if(!$StorageAccount){
    write-host "Creating Storage Account"
    $StorageAccount = New-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $storageAccoutName -SkuName Standard_LRS -Location $location
}
else {
    write-host "Storage accout already exist..`nChecking for container and Blob"
}

$CheckIfContainerExist = Get-AzStorageContainer -Name $ContainerName -Context $StorageAccount.Context -ErrorAction SilentlyContinue

if(!$CheckIfContainerExist){

    New-AzStorageContainer -Name $containerName -Context $StorageAccount.Context -Permission Container
}
else {
    write-host "Storage Continer already exist..`nChecking Blob"
}

#Generate SAS TOken valid for 2 minutes
$sasUrl = New-AzStorageContainerSASToken -Name $ContainerName -Permission rw -Context $StorageAccount.Context -ExpiryTime (Get-Date).AddMinutes(2) -FullUri

#Upload Files to Container
write-host "upload file from location : $($UploadFilePath)" 
Azcopy copy $UploadFilePath $sasUrl --recursive
