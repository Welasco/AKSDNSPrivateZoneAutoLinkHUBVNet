[CmdletBinding()]
Param
([object]$WebhookData)

#The parameter name must to be called as WebHookData otherwise the webhook does not work.

$VerbosePreference = 'continue'

# Ensures you do not inherit an AzContext in your runbook
Disable-AzContextAutosave –Scope Process

$connection = Get-AutomationConnection -Name AzureRunAsConnection

# Wrap authentication in retry logic for transient network failures
$logonAttempt = 0
while(!($connectionResult) -And ($logonAttempt -le 10))
{
    $LogonAttempt++
    # Logging in to Azure...
    $connectionResult =    Connect-AzAccount `
                               -ServicePrincipal `
                               -Tenant $connection.TenantID `
                               -ApplicationId $connection.ApplicationID `
                               -CertificateThumbprint $connection.CertificateThumbprint

    Start-Sleep -Seconds 30
}

###################################################################################################

$HubVNetID = "/subscriptions/<SubscriptionID xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx>/resourceGroups/<Resource Group Name>/providers/Microsoft.Network/virtualNetworks/<Virtual Network Name>"

# If runbook was called from Webhook, WebhookData will not be null.
if ($WebHookData){
    $WebHook = $WebHookData.RequestBody | ConvertFrom-Json
    $resourceGroupName = $WebHook.data.context.activityLog.resourceGroupName
    $resourceID = $WebHook.data.context.activityLog.resourceId
    $PrivateDNSZoneName = $resourceID.Split("/")[8]

    Write-Output ("ResourceGroupName: " + $resourceGroupName)
    Write-Output ("resourceID: " + $resourceID)
    Write-Output ("PrivateDNSZoneName: " + $PrivateDNSZoneName)

    $Link = New-AzPrivateDnsVirtualNetworkLink -ZoneName $PrivateDNSZoneName -ResourceGroupName $resourceGroupName -Name "AKSCluster-link" -VirtualNetworkId $HubVNetID
    Write-Output $Link
}
else
{
    Write-Error -Message 'Runbook was not started from Webhook' -ErrorAction stop
}
Write-Output "Script finished"