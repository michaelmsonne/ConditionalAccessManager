function Start-ConditionalAccessManagerConsole {
    <#
    .SYNOPSIS
    Starts an interactive console for managing Conditional Access policies
    
    .DESCRIPTION
    Provides an interactive menu-driven interface for listing, restoring, and managing 
    deleted Conditional Access policies
    
    .EXAMPLE
    Start-ConditionalAccessManagerConsole
    #>
    
    [CmdletBinding()]
    param()
    
    Write-Host "=== Conditional Access Policy Recovery Console ===" -ForegroundColor Cyan
    Write-Host ""
    
    do {
        Write-Host "`n--- Main Menu ---" -ForegroundColor Yellow
        Write-Host "1. List deleted policies"
        Write-Host "2. List deleted policies (detailed)"
        Write-Host "3. Restore a policy"
        Write-Host "4. Permanently remove a deleted policy"
        Write-Host "5. Export policies to JSON"
        Write-Host "6. Show authentication status"
        Write-Host "0. Exit"
        Write-Host ""
        
        $choice = Read-Host "Select an option (0-6)"
        
        switch ($choice) {
            "1" {
                Write-Host "`nRetrieving deleted policies..." -ForegroundColor Yellow
                try {
                    $policies = Get-DeletedConditionalAccessPolicies
                    if ($policies) {
                        Write-Host "`nFound $(@($policies).Count) deleted Conditional Access policies" -ForegroundColor Green
                        Write-Host ""
                        
                        # Display basic information in a clean table format
                        $policies | Select-Object @{
                            Name       = 'Policy Name'
                            Expression = { $_.DisplayName }
                        }, @{
                            Name       = 'State'
                            Expression = { $_.State }
                        }, @{
                            Name       = 'Deleted Date'
                            Expression = { 
                                if ($_.deletedDateTime) {
                                    [DateTime]$_.deletedDateTime | Get-Date -Format "yyyy-MM-dd HH:mm"
                                }
                                elseif ($_.DeletedDateTime) {
                                    [DateTime]$_.DeletedDateTime | Get-Date -Format "yyyy-MM-dd HH:mm"
                                }
                            }
                        }, @{
                            Name       = 'Policy ID'
                            Expression = { $_.Id }
                        } | Format-Table -AutoSize
                    }
                    else {
                        Write-Host "`nNo deleted Conditional Access policies found" -ForegroundColor Yellow
                    }
                }
                catch {
                    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
                }
            }
            
            "2" {
                Write-Host "`nRetrieving deleted policies with details..." -ForegroundColor Yellow
                try {
                    $policies = Get-DeletedConditionalAccessPolicies -IncludeDetails
                    if ($policies) {
                        foreach ($policy in $policies) {
                            Write-Host "`n--- $($policy.displayName) ---" -ForegroundColor Green
                            Write-Host "ID: $($policy.id)"
                            Write-Host "State: $($policy.state)"
                            Write-Host "Created: $($policy.createdDateTime)"
                            Write-Host "Modified: $($policy.modifiedDateTime)"
                            Write-Host "Deleted: $($policy.deletedDateTime)"
                            
                            # Format Conditions summary
                            Write-Host "`nConditions:" -ForegroundColor Cyan
                            if ($policy.conditions) {
                                $cond = $policy.conditions
                                if ($cond.clientAppTypes) { Write-Host "  Client App Types: $($cond.clientAppTypes -join ', ')" }
                                if ($cond.applications -and $cond.applications.includeApplications) { 
                                    Write-Host "  Include Applications: $($cond.applications.includeApplications -join ', ')" 
                                }
                                if ($cond.applications -and $cond.applications.excludeApplications) { 
                                    Write-Host "  Exclude Applications: $($cond.applications.excludeApplications -join ', ')" 
                                }
                                if ($cond.users) {
                                    if ($cond.users.includeUsers) { Write-Host "  Include Users: $($cond.users.includeUsers -join ', ')" }
                                    if ($cond.users.excludeUsers) { Write-Host "  Exclude Users: $($cond.users.excludeUsers -join ', ')" }
                                    if ($cond.users.includeGroups) { Write-Host "  Include Groups: $($cond.users.includeGroups -join ', ')" }
                                    if ($cond.users.excludeGroups) { Write-Host "  Exclude Groups: $($cond.users.excludeGroups -join ', ')" }
                                    if ($cond.users.includeRoles) { Write-Host "  Include Roles: $($cond.users.includeRoles -join ', ')" }
                                    if ($cond.users.excludeRoles) { Write-Host "  Exclude Roles: $($cond.users.excludeRoles -join ', ')" }
                                    if ($cond.users.includeGuestsOrExternalUsers) { 
                                        Write-Host "  Include External Users: $($cond.users.includeGuestsOrExternalUsers.guestOrExternalUserTypes)" 
                                    }
                                }
                                if ($cond.locations) { Write-Host "  Locations: Configured" }
                                if ($cond.platforms) { Write-Host "  Platforms: Configured" }
                                if ($cond.devices) { Write-Host "  Devices: Configured" }
                                if ($cond.signInRiskLevels) { Write-Host "  Sign-in Risk: $($cond.signInRiskLevels -join ', ')" }
                                if ($cond.userRiskLevels) { Write-Host "  User Risk: $($cond.userRiskLevels -join ', ')" }
                            }
                            else {
                                Write-Host "  None configured"
                            }
                            
                            # Format Grant Controls summary
                            Write-Host "`nGrant Controls:" -ForegroundColor Cyan
                            if ($policy.grantControls) {
                                $gc = $policy.grantControls
                                if ($gc.operator) { Write-Host "  Operator: $($gc.operator)" }
                                if ($gc.builtInControls) { Write-Host "  Built-in Controls: $($gc.builtInControls -join ', ')" }
                                if ($gc.customAuthenticationFactors) { Write-Host "  Custom Auth Factors: $($gc.customAuthenticationFactors -join ', ')" }
                                if ($gc.termsOfUse) { Write-Host "  Terms of Use: $($gc.termsOfUse -join ', ')" }
                                if ($gc.authenticationStrength) { Write-Host "  Auth Strength: Configured" }
                            }
                            else {
                                Write-Host "  None configured"
                            }
                            
                            # Format Session Controls summary
                            Write-Host "`nSession Controls:" -ForegroundColor Cyan
                            if ($policy.sessionControls) {
                                $sc = $policy.sessionControls
                                if ($sc.applicationEnforcedRestrictions) { Write-Host "  App Enforced Restrictions: Enabled" }
                                if ($sc.cloudAppSecurity) { Write-Host "  Cloud App Security: Configured" }
                                if ($sc.persistentBrowser) { Write-Host "  Persistent Browser: Configured" }
                                if ($sc.signInFrequency) { Write-Host "  Sign-in Frequency: Configured" }
                            }
                            else {
                                Write-Host "  None configured"
                            }
                        }
                    }
                }
                catch {
                    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
                }
            }
            
            "3" {
                Write-Host "`nRestore Policy" -ForegroundColor Yellow
                try {
                    # Check authentication and connect if needed
                    if (-not (Test-GraphAuthentication)) {
                        return
                    }
                    
                    # Call Graph API directly to get deleted policies
                    $Uri = 'https://graph.microsoft.com/beta/identity/conditionalAccess/deletedItems/policies'
                    $response = Invoke-GraphRequest -Uri $Uri -Method GET
                    $Data = $response.value
                    
                    if ($Data) {
                        Write-Host "`n$($Data.count) soft-deleted conditional access policies found" -ForegroundColor Green
                        Write-Host ""
                        
                        # Create indexed list for selection
                        $indexedPolicies = @()
                        for ($i = 0; $i -lt $Data.Count; $i++) {
                            $indexedPolicies += [PSCustomObject]@{
                                Index       = $i + 1
                                DisplayName = $Data[$i].displayName
                                Id          = $Data[$i].id
                                State       = $Data[$i].state
                            }
                        }
                        
                        # Display formatted table
                        $indexedPolicies | Format-Table Index, DisplayName, Id, State -AutoSize
                        
                        $selection = Read-Host "Enter policy number to restore (or 'c' to cancel)"
                        if ($selection -eq 'c') {
                            Write-Host "Cancelled" -ForegroundColor Yellow
                        }
                        elseif ($selection -match '^\d+$' -and [int]$selection -le $Data.Count -and [int]$selection -gt 0) {
                            $selectedPolicy = $Data[[int]$selection - 1]
                            Write-Host "`nSelected policy: $($selectedPolicy.displayName)" -ForegroundColor Cyan
                            $confirm = Read-Host "Restore this policy? (y/N)"
                            if ($confirm -eq 'y' -or $confirm -eq 'Y') {
                                Write-Host "Restoring policy..." -ForegroundColor Yellow
                                Restore-ConditionalAccessPolicy -PolicyId $selectedPolicy.id
                            }
                            else {
                                Write-Host "Cancelled" -ForegroundColor Yellow
                            }
                        }
                        else {
                            Write-Host "Invalid selection. Please enter a number between 1 and $($Data.Count), or 'c' to cancel." -ForegroundColor Red
                        }
                    }
                    else {
                        Write-Host "No soft-deleted conditional access policies found to restore" -ForegroundColor Yellow
                    }
                }
                catch {
                    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
                }
            }
            
            "4" {
                Write-Host "`nPermanently Remove Policy" -ForegroundColor Yellow
                try {
                    # Check authentication and connect if needed
                    if (-not (Test-GraphAuthentication)) {
                        return
                    }
                    
                    # Call Graph API directly to get deleted policies
                    $Uri = 'https://graph.microsoft.com/beta/identity/conditionalAccess/deletedItems/policies'
                    $response = Invoke-GraphRequest -Uri $Uri -Method GET
                    $Data = $response.value
                    
                    if ($Data) {
                        Write-Host "`n$($Data.count) soft-deleted conditional access policies found" -ForegroundColor Green
                        Write-Host ""
                        
                        # Create indexed list for selection
                        $indexedPolicies = @()
                        for ($i = 0; $i -lt $Data.Count; $i++) {
                            $indexedPolicies += [PSCustomObject]@{
                                Index       = $i + 1
                                DisplayName = $Data[$i].displayName
                                Id          = $Data[$i].id
                                State       = $Data[$i].state
                            }
                        }
                        
                        # Display formatted table
                        $indexedPolicies | Format-Table Index, DisplayName, Id, State -AutoSize
                        
                        $selection = Read-Host "Enter policy number to remove (or 'c' to cancel)"
                        if ($selection -eq 'c') {
                            Write-Host "Cancelled" -ForegroundColor Yellow
                        }
                        elseif ($selection -match '^\d+$' -and [int]$selection -le $Data.Count -and [int]$selection -gt 0) {
                            $selectedPolicy = $Data[[int]$selection - 1]
                            Write-Host "`nSelected policy: $($selectedPolicy.displayName)" -ForegroundColor Cyan
                            Write-Host "WARNING: This will permanently remove the policy and cannot be undone!" -ForegroundColor Red
                            $confirm = Read-Host "Permanently remove policy '$($selectedPolicy.displayName)'? Type 'DELETE' to confirm"
                            if ($confirm -eq 'DELETE') {
                                Write-Host "Removing policy..." -ForegroundColor Yellow
                                Remove-DeletedConditionalAccessPolicy -PolicyId $selectedPolicy.id -Force
                            }
                            else {
                                Write-Host "Cancelled" -ForegroundColor Yellow
                            }
                        }
                        else {
                            Write-Host "Invalid selection. Please enter a number between 1 and $($Data.Count), or 'c' to cancel." -ForegroundColor Red
                        }
                    }
                    else {
                        Write-Host "No soft-deleted conditional access policies found to remove" -ForegroundColor Yellow
                    }
                }
                catch {
                    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
                }
            }
            
            "5" {
                Write-Host "`nExport Policies" -ForegroundColor Yellow
                try {
                    $defaultPath = ".\CA-Policies-Export-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
                    $outputPath = Read-Host "Enter export folder (default: $defaultPath)"
                    if ([string]::IsNullOrWhiteSpace($outputPath)) {
                        $outputPath = $defaultPath
                    }
                    
                    $includeEnabled = Read-Host "Include enabled policies? (Y/n)"
                    $includeDisabled = Read-Host "Include disabled policies? (Y/n)"
                    $includeDeleted = Read-Host "Include deleted policies? (Y/n)"
                    
                    $params = @{ OutputFolder = $outputPath }
                    if ($includeEnabled -ne 'n') { $params.IncludeEnabled = $true }
                    if ($includeDisabled -ne 'n') { $params.IncludeDisabled = $true }
                    if ($includeDeleted -ne 'n') { $params.IncludeDeleted = $true }
                    
                    $result = Export-ConditionalAccessPolicies @params -Verbose
                    Write-Host "Export completed:" -ForegroundColor Green
                    Write-Host "  Folder: $($result.OutputFolder)"
                    Write-Host "  Enabled policies: $($result.EnabledPoliciesCount)"
                    Write-Host "  Disabled policies: $($result.DisabledPoliciesCount)"
                    Write-Host "  Deleted policies: $($result.DeletedPoliciesCount)"
                    Write-Host "  Total files: $($result.ExportedFiles.Count + 1) (including summary)"
                }
                catch {
                    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
                }
            }
            
            "6" {
                Write-Host "`nAuthentication Status" -ForegroundColor Yellow
                Write-Host "==================================================" -ForegroundColor Gray
                try {
                    $context = Get-MgContext
                    if ($context) {
                        Write-Host "Status:   " -NoNewline -ForegroundColor White
                        Write-Host "Connected to Microsoft Graph" -ForegroundColor Green
                        Write-Host "Account:  " -NoNewline -ForegroundColor White
                        Write-Host "$($context.Account)" -ForegroundColor Cyan
                        Write-Host "Tenant:   " -NoNewline -ForegroundColor White
                        Write-Host "$($context.TenantId)" -ForegroundColor Cyan
                        Write-Host ""
                        Write-Host "Scopes:" -ForegroundColor White
                        Write-Host "------------------------------" -ForegroundColor Gray
                        
                        # Group scopes for better readability
                        $scopes = $context.Scopes | Sort-Object
                        $groupedScopes = @{
                            'Policy'      = @()
                            'Directory'   = @()
                            'User'        = @()
                            'Device'      = @()
                            'Group'       = @()
                            'Application' = @()
                            'Reports'     = @()
                            'Other'       = @()
                        }
                        
                        foreach ($scope in $scopes) {
                            if ($scope -like "Policy.*") { $groupedScopes['Policy'] += $scope }
                            elseif ($scope -like "Directory.*") { $groupedScopes['Directory'] += $scope }
                            elseif ($scope -like "User.*") { $groupedScopes['User'] += $scope }
                            elseif ($scope -like "Device*") { $groupedScopes['Device'] += $scope }
                            elseif ($scope -like "Group.*") { $groupedScopes['Group'] += $scope }
                            elseif ($scope -like "Application.*") { $groupedScopes['Application'] += $scope }
                            elseif ($scope -like "Reports.*") { $groupedScopes['Reports'] += $scope }
                            else { $groupedScopes['Other'] += $scope }
                        }
                        
                        foreach ($category in $groupedScopes.Keys | Sort-Object) {
                            if ($groupedScopes[$category].Count -gt 0) {
                                Write-Host "$category Permissions:" -ForegroundColor Yellow
                                foreach ($scope in $groupedScopes[$category]) {
                                    Write-Host "  - $scope" -ForegroundColor Gray
                                }
                                Write-Host ""
                            }
                        }
                    }
                    else {
                        Write-Host "Status:   " -NoNewline -ForegroundColor White
                        Write-Host "Not connected to Microsoft Graph" -ForegroundColor Red
                        Write-Host ""
                        Write-Host "Use Connect-MgGraph to authenticate" -ForegroundColor Yellow
                    }
                }
                catch {
                    Write-Host "Error checking authentication: $($_.Exception.Message)" -ForegroundColor Red
                }
                Write-Host "==================================================" -ForegroundColor Gray
            }
            
            "0" {
                Write-Host "Exiting..." -ForegroundColor Green
                return
            }
            
            default {
                Write-Host "Invalid option. Please select 0-6." -ForegroundColor Red
            }
        }
        
        if ($choice -ne "0") {
            Read-Host "`nPress Enter to continue"
        }
        
    } while ($choice -ne "0")
}