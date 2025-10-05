function Get-DeletedConditionalAccessPolicies {
    <#
    .SYNOPSIS
    Retrieves deleted Conditional Access policies from Microsoft Graph
    
    .DESCRIPTION
    Gets a list of deleted Conditional Access policies that can potentially be restored
    
    .PARAMETER IncludeDetails
    Include full policy details in the output
    
    .EXAMPLE
    Get-DeletedConditionalAccessPolicies
    
    .EXAMPLE
    Get-DeletedConditionalAccessPolicies -IncludeDetails
    #>
    
    [CmdletBinding()]
    param(
        [switch]$IncludeDetails
    )
    
    try {
        Write-Verbose "Retrieving deleted Conditional Access policies..."
        
        # Check authentication and connect if needed
        if (-not (Test-GraphAuthentication)) {
            return @()
        }
        
        $uri = "https://graph.microsoft.com/beta/identity/conditionalAccess/deletedItems/policies"
        # Use centralized helper which includes retry logic and beta handling
        $response = Invoke-GraphRequest -Uri $uri -Method GET
        
        if ($response.value) {
            $policies = $response.value
            Write-Verbose "Found $($policies.Count) deleted Conditional Access policies"
            
            if ($IncludeDetails) {
                return $policies
            }
            else {
                # Helper to read a property from the object, falling back to AdditionalProperties (SDK models)
                $getProp = {
                    param($obj, $name)
                    if (-not $obj) { return $null }
                    try {
                        if ($obj.PSObject.Properties.Match($name)) { return $obj.$name }
                    }
                    catch { }
                    try {
                        if ($obj.AdditionalProperties -and $obj.AdditionalProperties.ContainsKey($name)) { return $obj.AdditionalProperties[$name] }
                    }
                    catch { }
                    return $null
                }

                return $policies | Select-Object @{Name = 'DisplayName'; Expression = { & $getProp $_ 'displayName' } }, @{Name = 'State'; Expression = { & $getProp $_ 'state' } }, @{Name = 'Id'; Expression = { & $getProp $_ 'id' } }, @{Name = 'DeletedDateTime'; Expression = { & $getProp $_ 'deletedDateTime' } }
            }
        }
        else {
            Write-Verbose "No deleted Conditional Access policies found"
            return @()
        }
    }
    catch {
        Write-Error "Failed to retrieve deleted policies: $($_.Exception.Message)"
        throw
    }
}