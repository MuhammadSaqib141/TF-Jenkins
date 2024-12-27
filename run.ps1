param($eventHubMessages)

Write-Host "Attempting to authenticate using Managed Identity..."

try {

    Connect-AzAccount -Identity
    Write-Host "Authenticated using Managed Identity"
}
catch {
    Write-Host "Error during authentication: $_"
    return
}


foreach ($message in $eventHubMessages) {
    Write-Host "Received message: $($message)"
    $message | ConvertTo-Json | Write-Host

    $secretName = $message.subject
    $keyVaultName = $message.data.VaultName

    Write-Host "Extracted Key Vault Name: $keyVaultName"
    Write-Host "Extracted Secret Name: $secretName"

    if (-not $keyVaultName) {
        Write-Host "Error: Key Vault Name is missing or null!"
        return
    }
    if (-not $secretName) {
        Write-Host "Error: Secret Name is missing or null!"
        return
    }

    Write-Host "Rotation started for Key Vault: $keyVaultName, Secret: $secretName"

    try {
        try {
            $secret = Get-AzKeyVaultSecret -VaultName $keyVaultName -Name $secretName
            Write-Host "Existing secret retrieved: $($secret.SecretValue)"
        }
        catch {
            Write-Host "Error retrieving secret from Key Vault: $_"
            return
        }

        $newSecretValue = [Guid]::NewGuid().ToString()

        $secureSecretValue = ConvertTo-SecureString -String $newSecretValue -AsPlainText -Force

        try {
            Set-AzKeyVaultSecret -VaultName $keyVaultName -Name $secretName -SecretValue $secureSecretValue
            Write-Host "Secret successfully rotated. New value: $newSecretValue"
        }
        catch {
            Write-Host "Error setting new secret in Key Vault: $_"
        }
    }
    catch {
        Write-Host "Error during secret rotation: $_"
    }
}
