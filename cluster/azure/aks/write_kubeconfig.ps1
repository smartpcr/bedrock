param(
    [string]$ClusterName,
    [string]$ResourceGroupName,
    [string]$KubeConfigFile,
    [string]$IsAdmin = "true"
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
Install-Module powershell-yaml -AllowClobber -Confirm:$false -Force
Import-Module powershell-yaml -Force

if ($IsAdmin -ieq "true") {
    Write-Host "connect to aks as cluster admin"
    az aks get-credentials -g $ResourceGroupName -n $ClusterName --admin --overwrite-existing --file $KubeConfigFile
}
else {
    Write-Host "connect to aks as cluster user"
    az aks get-credentials -g $ResourceGroupName -n $ClusterName --admin --overwrite-existing --file $KubeConfigFile
}