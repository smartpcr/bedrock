param(
    [Parameter(Mandatory = $true)]
    [string]$SubscriptionId,
    [Parameter(Mandatory = $true)]
    [string]$EnvName,
    [Parameter(Mandatory = $true)]
    [string]$ModuleFolder,
    [Parameter(Mandatory = $true)]
    [string]$FlexVolVersion,
    [Parameter(Mandatory = $true)]
    [string]$FlexVolNamespace
)

az account set -s $SubscriptionId
Write-Host "Applying configuration: EnvName=$EnvName, ModuleFolder=$ModuleFolder, FlexVolVersion=$FlexVolVersion, FlexVolNamespace=$FlexVolNamespace"

$configFile = Join-Path (Join-Path $ModuleFolder "config") "common.yaml"
if (-not (Test-Path $configFile)) {
    throw "Unable to find config file: $configFile"
}
$configYaml = Get-Content $configFile -Raw
$configYaml = $configYaml.Replace("{{.Values.flexvol.version}}", $FlexVolVersion)
$configYaml = $configYaml.Replace("{{.Values.flexvol.namespace}}", $FlexVolNamespace)
Remove-Item $configFile -Force
[System.IO.File]::WriteAllText($configFile, $configYaml)

Write-Host "Generating pod-identity yaml for env $EnvName"
$CurrentLocation = (Get-Location).Path
Set-Location $ModuleFolder
fab generate $EnvName
Set-Location $CurrentLocation

$generatedYamlFolder = Join-Path (Join-Path $ModuleFolder "generated") $EnvName
if (-not (Test-Path $generatedYamlFolder -PathType Container)) {
    throw "Failed to generate yaml files using fabrikate component"
}

Write-Host "Ensure k8s namespace '$FlexVolNamespace'"
$k8sNamespaces = kubectl get ns -o json | ConvertFrom-Json
$nsFound = $k8sNamespaces.items | Where-Object { $_.metadata.name -eq $FlexVolNamespace }
if ($null -eq $nsFound) {
    kubectl create namespace $FlexVolNamespace
}

Write-Host "kubectl apply -f $generatedYamlFolder"
kubectl apply -f $generatedYamlFolder