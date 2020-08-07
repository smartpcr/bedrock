param(
    [Parameter(Mandatory = $true)]
    [string]$EnvName,
    [Parameter(Mandatory = $true)]
    [string]$ModuleFolder,
    [Parameter(Mandatory = $true)]
    [string]$PodIdentityVersion,
    [Parameter(Mandatory = $true)]
    [string]$PodIdentityNamespace
)

helm repo add aad-pod-identity https://raw.githubusercontent.com/Azure/aad-pod-identity/master/charts
helm install aad-pod-identity aad-pod-identity/aad-pod-identity -n $PodIdentityNamespace