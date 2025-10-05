function Export-ConditionalAccessPolicies {
    <#
    .SYNOPSIS
    Exports Conditional Access policies to individual JSON files
    
    .DESCRIPTION
    Exports active or deleted Conditional Access policies to individual JSON files in a specified folder for backup or analysis
    
    .PARAMETER OutputFolder
    Folder where the JSON files will be saved (will be created if it doesn't exist)
    
    .PARAMETER IncludeDeleted
    Include deleted policies in the export
    
    .PARAMETER IncludeActive
    Include active policies in the export (default: true)
    
    .EXAMPLE
    Export-ConditionalAccessPolicies -OutputFolder "C:\temp\ca-policies"
    
    .EXAMPLE
    Export-ConditionalAccessPolicies -OutputFolder "C:\temp\all-policies" -IncludeDeleted -IncludeActive
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$OutputFolder,
        [switch]$IncludeDeleted,
        [switch]$IncludeActive
    )
    
    try {
        # Check authentication and connect if needed
        if (-not (Test-GraphAuthentication)) {
            return
        }
        
        # Ensure output folder exists and resolve to absolute path
        try {
            if (Test-Path -Path $OutputFolder) {
                $OutputFolder = Resolve-Path -Path $OutputFolder
            } else {
                $OutputFolder = $PSCmdlet.GetUnresolvedProviderPathFromPSPath($OutputFolder)
            }
        }
        catch {
            # Fallback to convert relative path to absolute
            if (-not [System.IO.Path]::IsPathRooted($OutputFolder)) {
                $OutputFolder = Join-Path -Path $PWD -ChildPath $OutputFolder
            }
        }
        
        if (-not (Test-Path -Path $OutputFolder)) {
            New-Item -ItemType Directory -Path $OutputFolder -Force | Out-Null
            Write-Host "Created output folder: $OutputFolder" -ForegroundColor Green
        }
        
        $exportSummary = @{
            ExportDate           = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            OutputFolder         = $OutputFolder
            PoliciesCount        = 0
            DeletedPoliciesCount = 0
            ExportedFiles        = @()
        }
        
        # Default to including active policies if neither is specified
        if (-not $IncludeDeleted -and -not $IncludeActive) {
            $IncludeActive = $true
        }
        
        # Function to sanitize filename
        function Get-SafeFileName {
            param([string]$Name)
            if ([string]::IsNullOrWhiteSpace($Name)) {
                return "UnknownPolicy"
            }
            
            # Replace problematic characters with safe alternatives
            $safeName = $Name -replace '[\[\]]', ''  # Remove square brackets
            $safeName = $safeName -replace '[<>:"/\\|?*]', '_'  # Replace other invalid chars
            $safeName = $safeName -replace '\s+', '_'  # Replace multiple spaces with single underscore
            $safeName = $safeName -replace '_+', '_'   # Replace multiple underscores with single
            $safeName = $safeName.Trim('_')            # Remove leading/trailing underscores
            
            # Ensure the name isn't too long (Windows has 255 char limit, leave room for ID and extension)
            if ($safeName.Length -gt 100) {
                $safeName = $safeName.Substring(0, 100)
            }
            
            # Ensure we have a valid name
            if ([string]::IsNullOrWhiteSpace($safeName)) {
                return "UnknownPolicy"
            }
            
            return $safeName
        }
        
        if ($IncludeActive) {
            Write-Host "Retrieving Conditional Access policies..." -ForegroundColor Yellow
            $activeUri = "https://graph.microsoft.com/beta/identity/conditionalAccess/policies"
            $activeResponse = Invoke-GraphRequest -Uri $activeUri -Method GET
            
            if ($activeResponse.value) {
                Write-Host "Found $($activeResponse.value.Count) policies" -ForegroundColor Green
                
                foreach ($policy in $activeResponse.value) {
                    try {
                        $safeDisplayName = Get-SafeFileName -Name $policy.displayName
                        $fileName = "$($safeDisplayName)_$($policy.id).json"
                        $filePath = Join-Path -Path $OutputFolder -ChildPath $fileName
                        
                        Write-Verbose "Original name: '$($policy.displayName)'"
                        Write-Verbose "Safe name: '$safeDisplayName'"
                        Write-Verbose "Creating file: $filePath"
                        
                        # Validate the file path before attempting to create
                        $directory = Split-Path -Path $filePath -Parent
                        if (-not (Test-Path -Path $directory)) {
                            throw "Directory does not exist: $directory"
                        }
                        
                        $policyData = @{
                            ExportDate = $exportSummary.ExportDate
                            PolicyType = "All"
                            Policy     = $policy
                        }
                        
                        $jsonOutput = $policyData | ConvertTo-Json -Depth 20
                        $jsonOutput | Out-File -FilePath $filePath -Encoding UTF8 -Force
                        
                        $exportSummary.ExportedFiles += $fileName
                        $exportSummary.PoliciesCount++
                        
                        Write-Host "  Exported: $fileName" -ForegroundColor Gray
                    }
                    catch {
                        Write-Warning "Failed to export policy '$($policy.displayName)': $($_.Exception.Message)"
                        Write-Verbose "Error details: $($_.Exception)"
                        continue
                    }
                }
            }
        }
        
        if ($IncludeDeleted) {
            Write-Host "Retrieving deleted Conditional Access policies..." -ForegroundColor Yellow
            $deletedUri = "https://graph.microsoft.com/beta/identity/conditionalAccess/deletedItems/policies"
            $deletedResponse = Invoke-GraphRequest -Uri $deletedUri -Method GET
            
            if ($deletedResponse.value) {
                Write-Host "Found $($deletedResponse.value.Count) deleted policies" -ForegroundColor Green
                
                foreach ($policy in $deletedResponse.value) {
                    try {
                        Write-Verbose "Processing deleted policy: '$($policy.displayName)' with ID: '$($policy.id)'"
                        
                        $safeDisplayName = Get-SafeFileName -Name $policy.displayName
                        $fileName = "DELETED_$($safeDisplayName)_$($policy.id).json"
                        $filePath = Join-Path -Path $OutputFolder -ChildPath $fileName
                        
                        Write-Verbose "Original name: '$($policy.displayName)'"
                        Write-Verbose "Safe name: '$safeDisplayName'"
                        Write-Verbose "File name: '$fileName'"
                        Write-Verbose "Creating file: $filePath"
                        
                        # Validate the file path before attempting to create
                        $directory = Split-Path -Path $filePath -Parent
                        if (-not (Test-Path -Path $directory)) {
                            throw "Directory does not exist: $directory"
                        }
                        
                        # Test if we can create a file with this name
                        $testPath = "$filePath.test"
                        try {
                            "test" | Out-File -FilePath $testPath -Force
                            Remove-Item -Path $testPath -Force
                        }
                        catch {
                            throw "Cannot create file with name '$fileName': $($_.Exception.Message)"
                        }
                        
                        $policyData = @{
                            ExportDate = $exportSummary.ExportDate
                            PolicyType = "Deleted"
                            Policy     = $policy
                        }
                        
                        $jsonOutput = $policyData | ConvertTo-Json -Depth 20
                        $jsonOutput | Out-File -FilePath $filePath -Encoding UTF8 -Force
                        
                        $exportSummary.ExportedFiles += $fileName
                        $exportSummary.DeletedPoliciesCount++
                        
                        Write-Host "  Exported: $fileName" -ForegroundColor Gray
                    }
                    catch {
                        Write-Warning "Failed to export deleted policy '$($policy.displayName)': $($_.Exception.Message)"
                        Write-Verbose "Full error details: $($_.Exception | Format-List * | Out-String)"
                        continue
                    }
                }
            }
        }
        
        # Create summary file
        try {
            $summaryPath = Join-Path -Path $OutputFolder -ChildPath "_ExportSummary.json"
            Write-Verbose "Creating summary file: $summaryPath"
            $exportSummary | ConvertTo-Json -Depth 5 | Out-File -FilePath $summaryPath -Encoding UTF8 -Force
        }
        catch {
            Write-Warning "Failed to create summary file: $($_.Exception.Message)"
        }
        
        Write-Host "`nExport completed successfully!" -ForegroundColor Green
        Write-Host "Output folder: $OutputFolder" -ForegroundColor Cyan
        Write-Host "Total policies: $($exportSummary.PoliciesCount)" -ForegroundColor Cyan
        Write-Host "Deleted policies: $($exportSummary.DeletedPoliciesCount)" -ForegroundColor Cyan
        Write-Host "Total files: $($exportSummary.ExportedFiles.Count + 1) (including summary)" -ForegroundColor Cyan
        
        return $exportSummary
    }
    catch {
        Write-Error "Failed to export policies: $($_.Exception.Message)"
        throw
    }
}