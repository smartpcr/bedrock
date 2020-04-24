param(
    [string]$AccountName,
    [string]$SubscriptionId,
    [string]$DbSettings,
    [string]$VaultName
)

function GenerateCosmosDBAuthToken {
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $Verb,

        [Parameter(Mandatory = $true)]
        [string]
        $ResourceType,

        [Parameter(Mandatory = $true)]
        [string]
        $ResourceId,

        [Parameter(Mandatory = $true)]
        [string]
        $Date,

        [Parameter(Mandatory = $true)]
        [string]
        $Key,

        [Parameter(Mandatory = $false)]
        [string]
        $KeyType = 'master',

        [Parameter(Mandatory = $false)]
        [string]
        $TokenVersion = '1.0'
    )

    $payload = "$($verb.ToLowerInvariant())`n$($resourceType.ToLowerInvariant())`n$resourceId`n$($date.ToLowerInvariant())`n`n"

    $hmacSha256 = New-Object System.Security.Cryptography.HMACSHA256
    $hmacSha256.Key = [System.Convert]::FromBase64String($key)
    $encoding = [System.Text.Encoding]::UTF8
    $payloadHash = $hmacSha256.ComputeHash($encoding.GetBytes($payload))
    $signature = [System.Convert]::ToBase64String($payloadHash)
    return [System.Web.HttpUtility]::UrlEncode("type=$keyType&ver=$tokenVersion&sig=$signature")
}

function SubmitCosmosDbApiRequest {
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $Verb,

        [Parameter(Mandatory = $true)]
        [string]
        $ResourceId,

        [Parameter(Mandatory = $true)]
        [string]
        $ResourceType,

        [Parameter(Mandatory = $true)]
        [string]
        $Url,

        [Parameter(Mandatory = $true)]
        [string]
        $BodyJson,

        [Parameter(Mandatory = $true)]
        [string]
        $Key
    )

    $date = (Get-Date).ToUniversalTime().ToString('r')
    $authToken = GenerateCosmosDBAuthToken -Verb $Verb -ResourceType $ResourceType -ResourceId $ResourceId -Date $date -Key $Key

    # Add the headers
    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("Authorization", $authToken)
    $headers.Add("x-ms-version", '2015-08-06')
    $headers.Add("x-ms-date", $date)

    # Send the request and handle the result
    try {
        Invoke-RestMethod $Url `
            -Headers $headers `
            -Method $Verb `
            -ContentType 'application/json' `
            -Body $BodyJson
    }
    catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        if ($statusCode -eq 409) {
            return 'AlreadyExists'
        }
        else {
            throw
        }
    }
}

function DeployUserDefinedFunction {
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $AccountName,

        [Parameter(Mandatory = $true)]
        [string]
        $AccountKey,

        [Parameter(Mandatory = $true)]
        [string]
        $DatabaseName,

        [Parameter(Mandatory = $true)]
        [string]
        $CollectionName,

        [Parameter(Mandatory = $true)]
        [string]
        $UserDefinedFunctionName,

        [Parameter(Mandatory = $true)]
        [string]
        $SourceFilePath
    )

    # Assemble the UDF definition to send to Cosmos DB
    Write-Host 'Preparing UDF...'
    $sourceFileContents = Get-Content $SourceFilePath | Out-String
    $definition = @{
        body = $sourceFileContents
        id   = $UserDefinedFunctionName
    }
    $definitionJson = $definition | ConvertTo-Json

    CreateCosmosDBObject `
        -AccountName $AccountName `
        -AccountKey $AccountKey `
        -DatabaseName $DatabaseName `
        -CollectionName $CollectionName `
        -ObjectType UDF `
        -ObjectName $UserDefinedFunctionName `
        -Definition $definitionJson
}

function DeployStoredProcedure {
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $AccountName,

        [Parameter(Mandatory = $true)]
        [string]
        $AccountKey,

        [Parameter(Mandatory = $true)]
        [string]
        $DatabaseName,

        [Parameter(Mandatory = $true)]
        [string]
        $CollectionName,

        [Parameter(Mandatory = $true)]
        [string]
        $StoredProcedureName,

        [Parameter(Mandatory = $true)]
        [string]
        $SourceFilePath
    )

    # Assemble the stored procedure definition to send to Cosmos DB
    Write-Host 'Preparing stored procedure...'
    $sourceFileContents = Get-Content $SourceFilePath | Out-String
    $definition = @{
        body = $sourceFileContents
        id   = $StoredProcedureName
    }
    $definitionJson = $definition | ConvertTo-Json

    CreateCosmosDBObject `
        -AccountName $AccountName `
        -AccountKey $AccountKey `
        -DatabaseName $DatabaseName `
        -CollectionName $CollectionName `
        -ObjectType StoredProcedure `
        -ObjectName $StoredProcedureName `
        -Definition $definitionJson
}

function DeployTrigger {
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $AccountName,

        [Parameter(Mandatory = $true)]
        [string]
        $AccountKey,

        [Parameter(Mandatory = $true)]
        [string]
        $DatabaseName,

        [Parameter(Mandatory = $true)]
        [string]
        $CollectionName,

        [Parameter(Mandatory = $true)]
        [string]
        $TriggerName,

        [Parameter(Mandatory = $true)]
        [string]
        [ValidateSet('Pre', 'Post')]
        $TriggerType,

        [Parameter(Mandatory = $true)]
        [string]
        [ValidateSet('All', 'Create', 'Delete', 'Replace')]
        $TriggerOperation,

        [Parameter(Mandatory = $true)]
        [string]
        $SourceFilePath
    )

    # Assemble the trigger definition to send to Cosmos DB
    Write-Host 'Preparing trigger...'
    $sourceFileContents = Get-Content $SourceFilePath | Out-String
    $definition = @{
        body             = $sourceFileContents
        id               = $TriggerName
        triggerOperation = $TriggerOperation
        triggerType      = $TriggerType
    }
    $definitionJson = $definition | ConvertTo-Json

    CreateCosmosDBObject `
        -AccountName $AccountName `
        -AccountKey $AccountKey `
        -DatabaseName $DatabaseName `
        -CollectionName $CollectionName `
        -ObjectType Trigger `
        -ObjectName $TriggerName `
        -Definition $definitionJson
}
function ToBase64() {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$InputString
    )

    return [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($InputString))
}

function FromBase64() {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$InputString
    )

    return [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($InputString))
}

function Retry {
    [CmdletBinding()]
    param(
        [int]$MaxRetries = 3,
        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock,
        [int]$RetryDelay = 10,
        [bool]$LogError = $true
    )

    $isSuccessful = $false
    $retryCount = 0
    $prevErrorActionPref = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    while (!$IsSuccessful -and $retryCount -lt $MaxRetries) {
        try {
            $ScriptBlock.Invoke()
            $isSuccessful = $true
        }
        catch {
            $retryCount++

            if ($LogError) {
                Write-Warning $_.Exception.InnerException.Message
                Write-Warning "failed after $retryCount attempt, wait $RetryDelay seconds and retry"
            }

            Start-Sleep -Seconds $RetryDelay
        }
    }
    $ErrorActionPreference = $prevErrorActionPref
    return $isSuccessful
}

if ($null -ne $SubscriptionId -and $SubscriptionId -ne "") {
    az account set -s $SubscriptionId
}

$json = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($DbSettings))
Write-Host "db setting as json: $json"

$dbSettingsArray = [array](ConvertFrom-Json $json -Depth 10)
if ($dbSettingsArray.Count -eq 0) {
    throw "invalid db settings"
}

Write-Host "retrieve cosmosdb auth key..."
$AuthKey = $(az keyvault secret show --vault-name $VaultName --name "$($AccountName)-AuthKey" | ConvertFrom-Json).value

$dbSettingsArray | ForEach-Object {
    $dbSetting = $_
    $dbName = $dbSetting.name
    $collections = $dbSetting.collections
    Write-Host "checking stored procedures for db: $($dbName), total of $($collections.Count) collections found."

    $collections | ForEach-Object {
        $collection = $_
        $collectionName = $collection.name
        $haveProcedures = [bool]($collection.PSobject.Properties.name -match "storedProcedures")
        if ($haveProcedures) {
            $ResourceType = "sprocs"
            [array]$storedProcedures = $collection.storedProcedures
            if ($storedProcedures.Count -gt 0) {
                Write-Host "Creating stored procedures for collection: $($collectionName), total of $($storedProcedures.Count) stored procedures found."
                $storedProcedures | ForEach-Object {
                    $sp = $_
                    $spName = $sp.spName
                    $spSecretName = $sp.SpSecretName
                    Write-Host "Installing '$ResourceType' '$spName' to Cosmos DB collection '$($dbName)/$($collectionName)'..."
                    $spDefinition = $(az keyvault secret show --vault-name $VaultName --name $spSecretName | ConvertFrom-Json).value | FromBase64
                    $spJson = @{
                        id   = $SpName
                        body = $SpDefinition
                    } | ConvertTo-Json

                    Write-Host "`n`n$($spJson)`n`n"

                    $createResult = SubmitCosmosDbApiRequest `
                        -Verb 'POST' `
                        -ResourceId "dbs/$dbName/colls/$collectionName" `
                        -ResourceType $ResourceType `
                        -Url "https://$AccountName.documents.azure.com/dbs/$dbName/colls/$collectionName/$ResourceType" `
                        -Key $AuthKey `
                        -BodyJson $spJson

                    # If that failed because the object already exists, update the object
                    if ($createResult -eq 'AlreadyExists') {
                        Write-Host "$ObjectType already exists. Updating..."
                        $spUpdated = Retry(3) {
                            SubmitCosmosDbApiRequest `
                                -Verb 'PUT' `
                                -ResourceId "dbs/$dbName/colls/$collectionName/$ResourceType/$spName" `
                                -ResourceType $ResourceType `
                                -Url "https://$AccountName.documents.azure.com/dbs/$dbName/colls/$collectionName/$ResourceType/$spName" `
                                -Key $AuthKey `
                                -BodyJson $spJson | Out-Null
                        }
                        if (!$spUpdated) {
                            throw "Failed to update stored procedure $spName"
                        }
                    }
                }
            }
        }

        $haveUdfs = [bool]($collection.PSobject.Properties.name -match "udfs")
        if ($haveUdfs) {
            $ResourceType = "udfs"
            [array]$udfs = $collection.udfs
            if ($udfs.Count -gt 0) {
                Write-Host "Creating udf for collection: $($collectionName), total of $($udfs.Count) udfs found."
                $udfs | ForEach-Object {
                    $udf = $_
                    $udfName = $udf.udfName
                    $udfSecretName = $udf.UdfSecretName
                    Write-Host "Installing '$ResourceType' '$udfName' to Cosmos DB collection '$($dbName)/$($collectionName)'..."
                    $udfDefinition = $(az keyvault secret show --vault-name $VaultName --name $udfSecretName | ConvertFrom-Json).value | FromBase64
                    $udfJson = @{
                        id   = $UdfName
                        body = $UdfDefinition
                    } | ConvertTo-Json

                    Write-Host "`n`n$($udfJson)`n`n"

                    $createResult = SubmitCosmosDbApiRequest `
                        -Verb 'POST' `
                        -ResourceId "dbs/$dbName/colls/$collectionName" `
                        -ResourceType $ResourceType `
                        -Url "https://$AccountName.documents.azure.com/dbs/$dbName/colls/$collectionName/$ResourceType" `
                        -Key $AuthKey `
                        -BodyJson $udfJson

                    # If that failed because the object already exists, update the object
                    if ($createResult -eq 'AlreadyExists') {
                        Write-Host "$ObjectType already exists. Updating..."
                        $spUpdated = Retry(3) {
                            SubmitCosmosDbApiRequest `
                                -Verb 'PUT' `
                                -ResourceId "dbs/$dbName/colls/$collectionName/$ResourceType/$udfName" `
                                -ResourceType $ResourceType `
                                -Url "https://$AccountName.documents.azure.com/dbs/$dbName/colls/$collectionName/$ResourceType/$udfName" `
                                -Key $AuthKey `
                                -BodyJson $udfJson | Out-Null
                        }
                        if (!$spUpdated) {
                            throw "Failed to update udf $udfName"
                        }
                    }
                }
            }
        }
    }
}
