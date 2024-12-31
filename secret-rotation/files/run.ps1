param($eventHubMessages)


Write-Host "Secret rotation process started at: $(Get-Date)"

try {
    $ErrorActionPreference = "Stop"
    Write-Host "Attempting to authenticate using Managed Identity..."
    $clientId = $env:AZURE_CLIENT_ID  
    Connect-AzAccount -Identity
    Write-Host "Managed Identity authentication successful."
}
catch {
    Write-Host "ERROR: Failed to authenticate using Managed Identity: $_"
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

    Write-Host "Starting rotation for Key Vault: $keyVaultName, Secret: $secretName"

    try {
        # Retrieve the secret from Key Vault
        $secret = Get-AzKeyVaultSecret -VaultName $keyVaultName -Name $secretName
        if ($null -eq $secret) {
            Write-Host "Error: Secret not found in Key Vault: $keyVaultName, Secret: $secretName"
            return
        }

        # Convert the SecureString secret value to plain text
        $currentSecretValue = [System.Net.NetworkCredential]::new("", $secret.SecretValue).Password

        Write-Host "Existing secret retrieved successfully."

        if (-not $currentSecretValue) {
            Write-Host "Error: Current secret value is null or empty. Cannot rotate secret."
            return
        }

        # Use the current secret value (no new secret value needed)
        $secureSecretValue = ConvertTo-SecureString -String $currentSecretValue -AsPlainText -Force

        # Set expiration date to 2 years from the current date
        $expirationDate = (Get-Date).AddYears(2)

        try {
            # Update the secret in Key Vault with the same value and expiration date
            Set-AzKeyVaultSecret -VaultName $keyVaultName -Name $secretName -SecretValue $secureSecretValue -Expires $expirationDate
            Write-Host "Secret successfully rotated (using current value) and expiration set for 2 years for Key Vault: $keyVaultName, Secret: $secretName"
        }
        catch {
            Write-Host "Error updating secret in Key Vault: $_"
        }
    }
    catch {
        Write-Host "Error during secret rotation: $_"
    }
}

Write-Host "Secret rotation process completed."
