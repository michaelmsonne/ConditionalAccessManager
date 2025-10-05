function Test-GraphAuthentication {
    <#
    .SYNOPSIS
    Tests if Microsoft Graph authentication is available and prompts to connect if needed
    
    .DESCRIPTION
    Checks if there's an active Microsoft Graph connection. If not, prompts the user
    to connect with the required scopes for Conditional Access management.
    
    .PARAMETER RequiredScopes
    Array of required scopes. Default includes Policy.Read.All and Policy.ReadWrite.ConditionalAccess
    
    .PARAMETER AutoConnect
    If specified, automatically attempts to connect without prompting
    
    .EXAMPLE
    Test-GraphAuthentication
    
    .EXAMPLE
    Test-GraphAuthentication -AutoConnect
    #>
    
    [CmdletBinding()]
    param(
        [string[]]$RequiredScopes = @('Policy.Read.All', 'Policy.ReadWrite.ConditionalAccess'),
        [switch]$AutoConnect
    )
    
    try {
        # Check if already connected
        $context = Get-MgContext
        if ($context) {
            # Check if we have the required scopes
            $hasRequiredScopes = $true
            foreach ($scope in $RequiredScopes) {
                if ($context.Scopes -notcontains $scope) {
                    $hasRequiredScopes = $false
                    break
                }
            }
            
            if ($hasRequiredScopes) {
                Write-Verbose "Already connected to Microsoft Graph with required scopes"
                return $true
            }
            else {
                Write-Warning "Connected to Microsoft Graph but missing required scopes: $($RequiredScopes -join ', ')"
            }
        }
        
        # Not connected or missing scopes
        if ($AutoConnect) {
            Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Yellow
            Connect-MgGraph -Scopes $RequiredScopes -NoWelcome | Out-Null
            return $true
        }
        else {
            Write-Host "Microsoft Graph authentication required." -ForegroundColor Yellow
            Write-Host "Required scopes: $($RequiredScopes -join ', ')" -ForegroundColor Cyan
            $connect = Read-Host "Connect now? (Y/n)"
            
            if ($connect -eq '' -or $connect -eq 'y' -or $connect -eq 'Y') {
                Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Yellow
                Connect-MgGraph -Scopes $RequiredScopes -NoWelcome | Out-Null
                return $true
            }
            else {
                Write-Host "Operation cancelled. Please connect manually using: Connect-MgGraph -Scopes '$($RequiredScopes -join "','")'" -ForegroundColor Red
                return $false
            }
        }
    }
    catch {
        Write-Error "Failed to authenticate to Microsoft Graph: $($_.Exception.Message)"
        return $false
    }
}