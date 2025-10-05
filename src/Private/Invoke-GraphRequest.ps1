function Invoke-GraphRequest {
    <#
    .SYNOPSIS
    Internal helper function to make Microsoft Graph API requests with retry logic
    
    .DESCRIPTION
    Wraps Invoke-MgGraphRequest with error handling, beta endpoint support, and built-in retry logic
    for 429 "Too Many Requests" and 5xx server errors with exponential backoff and jitter
    
    .PARAMETER Uri
    The Graph API endpoint URI
    
    .PARAMETER Method
    HTTP method (GET, POST, DELETE, etc.)
    
    .PARAMETER Body
    Request body for POST/PUT operations
    
    .PARAMETER Beta
    Use beta endpoint instead of v1.0
    
    .PARAMETER MaxRetries
    Maximum number of retry attempts (default: 5)
    
    .PARAMETER BaseDelaySeconds
    Base delay in seconds for exponential backoff (default: 1)
    
    .EXAMPLE
    Invoke-GraphRequest -Uri "https://graph.microsoft.com/v1.0/me" -Method GET
    
    .EXAMPLE
    Invoke-GraphRequest -Uri "https://graph.microsoft.com/v1.0/policies" -Method GET -Beta
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Uri,        
        [string]$Method = 'GET',        
        [object]$Body,        
        [switch]$Beta,
        [int]$MaxRetries = 5,
        [int]$BaseDelaySeconds = 1
    )
    
    # Ensure beta endpoint if requested
    if ($Beta -and $Uri -notmatch '/beta/') {
        $Uri = $Uri -replace '/v1\.0/', '/beta/'
        if ($Uri -notmatch '/beta/') {
            $Uri = $Uri -replace 'https://graph\.microsoft\.com/', 'https://graph.microsoft.com/beta/'
        }
    }
    
    $attempt = 0
    $maxAttempts = $MaxRetries + 1
    
    while ($attempt -lt $maxAttempts) {
        try {
            $requestParams = @{
                Method = $Method
                Uri    = $Uri
            }
            
            if ($Body) {
                $requestParams.Body = $Body | ConvertTo-Json -Depth 20
            }
            
            Write-Verbose "Attempt $($attempt + 1)/$maxAttempts for $Method $Uri"
            $response = Invoke-MgGraphRequest @requestParams
            
            # Success - return the response
            return $response
        }
        catch {
            $attempt++
            $statusCode = $null
            $retryAfter = $null
            
            # Extract status code from different error types
            if ($_.Exception.Response) {
                $statusCode = [int]$_.Exception.Response.StatusCode
            }
            elseif ($_.Exception.Message -match 'TooManyRequests|429') {
                $statusCode = 429
            }
            elseif ($_.Exception.Message -match '5\d{2}') {
                # Extract 5xx status codes
                if ($_.Exception.Message -match '(\d{3})') {
                    $statusCode = [int]$matches[1]
                }
            }
            
            # Extract Retry-After header if available
            if ($_.Exception.Response.Headers -and $_.Exception.Response.Headers['Retry-After']) {
                $retryAfterValue = $_.Exception.Response.Headers['Retry-After']
                if ($retryAfterValue -match '^\d+$') {
                    $retryAfter = [int]$retryAfterValue
                }
            }
            
            # Check if we should retry (429 or 5xx errors)
            $shouldRetry = ($statusCode -eq 429) -or ($statusCode -ge 500 -and $statusCode -lt 600)
            
            if ($shouldRetry -and $attempt -lt $maxAttempts) {
                # Calculate delay with exponential backoff and jitter
                if ($retryAfter) {
                    $delay = $retryAfter
                    Write-Warning "Rate limited (429). Retrying in $delay seconds (from Retry-After header)..."
                } else {
                    # Exponential backoff: 2^attempt * base delay + random jitter
                    $baseDelay = [Math]::Pow(2, $attempt - 1) * $BaseDelaySeconds
                    $jitter = Get-Random -Minimum 0 -Maximum ($baseDelay * 0.1) # 10% jitter
                    $delay = [Math]::Round($baseDelay + $jitter, 2)
                    
                    $errorType = if ($statusCode -eq 429) { "Rate limited" } else { "Server error ($statusCode)" }
                    Write-Warning "$errorType. Retrying in $delay seconds (attempt $attempt/$MaxRetries)..."
                }
                
                Start-Sleep -Seconds $delay
            }
            else {
                # No more retries or non-retryable error
                if ($attempt -ge $maxAttempts) {
                    Write-Error "Graph API request failed after $MaxRetries retries for $Method $Uri : $($_.Exception.Message)"
                } else {
                    Write-Error "Graph API request failed for $Method $Uri : $($_.Exception.Message)"
                }
                throw
            }
        }
    }
}