$base = "http://localhost:3006"
$pass = 0
$fail = 0
$results = @()

function Test-Route {
    param(
        [string]$Name,
        [string]$Method,
        [string]$Url,
        [string]$Body,
        [int]$ExpectedStatus,
        [string]$ExpectedContains
    )
    
    try {
        $params = @{
            Uri = "$base$Url"
            Method = $Method
            UseBasicParsing = $true
        }
        if ($Body) {
            $params.ContentType = "application/json"
            $params.Body = $Body
        }

        $response = $null
        $content = ""
        $status = 0
        
        try {
            $response = Invoke-WebRequest @params -ErrorAction Stop
            $status = $response.StatusCode
            $content = $response.Content
        } catch {
            if ($_.Exception.Response) {
                $status = [int]$_.Exception.Response.StatusCode
                $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
                $content = $reader.ReadToEnd()
            } else {
                $status = -1
                $content = $_.Exception.Message
            }
        }

        $statusOk = ($status -eq $ExpectedStatus)
        $containsOk = if ($ExpectedContains) { $content.Contains($ExpectedContains) } else { $true }
        $passed = $statusOk -and $containsOk

        if ($passed) {
            $script:pass++
            Write-Host "[PASS] $Name" -ForegroundColor Green
        } else {
            $script:fail++
            Write-Host "[FAIL] $Name | Got $status, expected $ExpectedStatus | Contains '$ExpectedContains': $containsOk" -ForegroundColor Red
            Write-Host "       Body: $content" -ForegroundColor DarkGray
        }

        $script:results += [PSCustomObject]@{
            Test = $Name
            Status = if ($passed) { "PASS" } else { "FAIL" }
            HTTP = $status
            Response = if ($content.Length -gt 120) { $content.Substring(0, 120) + "..." } else { $content }
        }
    } catch {
        $script:fail++
        Write-Host "[FAIL] $Name | Exception: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "   kronix FRAMEWORK - MEGA TEST SUITE" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# ═══════════════════════════════════════════
# GROUP 1: ROUTING
# ═══════════════════════════════════════════
Write-Host "--- ROUTING ---" -ForegroundColor Yellow
Test-Route -Name "GET /ping (JSON)" -Method GET -Url "/ping" -ExpectedStatus 200 -ExpectedContains '"pong"'
Test-Route -Name "GET /text (Plain Text)" -Method GET -Url "/text" -ExpectedStatus 200 -ExpectedContains "Hello kronix"
Test-Route -Name "GET /html (HTML)" -Method GET -Url "/html" -ExpectedStatus 200 -ExpectedContains "<h1>kronix</h1>"
Test-Route -Name "GET /users/:id (Named Param)" -Method GET -Url "/users/42" -ExpectedStatus 200 -ExpectedContains "42"
Test-Route -Name "GET /search?q=dart (Query Params)" -Method GET -Url "/search?q=dart&page=2" -ExpectedStatus 200 -ExpectedContains "dart"
Test-Route -Name "GET /api/v1/status (Nested Group)" -Method GET -Url "/api/v1/status" -ExpectedStatus 200 -ExpectedContains "v1"
Test-Route -Name "GET /api/v2/status (Nested Group)" -Method GET -Url "/api/v2/status" -ExpectedStatus 200 -ExpectedContains "v2"
Test-Route -Name "GET /nonexistent (404 fallback)" -Method GET -Url "/this-does-not-exist" -ExpectedStatus 404 -ExpectedContains ""
Test-Route -Name "GET /health (Built-in)" -Method GET -Url "/health" -ExpectedStatus 200 -ExpectedContains "ok"

# ═══════════════════════════════════════════
# GROUP 2: VALIDATION
# ═══════════════════════════════════════════
Write-Host "`n--- VALIDATION ---" -ForegroundColor Yellow
Test-Route -Name "Login: Missing all fields" -Method POST -Url "/validate/login" -Body '{}' -ExpectedStatus 422 -ExpectedContains "Email is mandatory"
Test-Route -Name "Login: Bad email" -Method POST -Url "/validate/login" -Body '{"email":"notanemail","password":"short"}' -ExpectedStatus 422 -ExpectedContains "email"
Test-Route -Name "Login: Short password" -Method POST -Url "/validate/login" -Body '{"email":"g@d.com","password":"abc"}' -ExpectedStatus 422 -ExpectedContains "Password too short"
Test-Route -Name "Login: Valid" -Method POST -Url "/validate/login" -Body '{"email":"garv@kronix.dev","password":"secret123"}' -ExpectedStatus 200 -ExpectedContains "valid"
Test-Route -Name "Product: Missing name" -Method POST -Url "/validate/product" -Body '{"price":10}' -ExpectedStatus 422 -ExpectedContains "required"
Test-Route -Name "Product: Non-numeric price" -Method POST -Url "/validate/product" -Body '{"name":"Widget","price":"abc"}' -ExpectedStatus 422 -ExpectedContains "must be a number"
Test-Route -Name "Product: Valid" -Method POST -Url "/validate/product" -Body '{"name":"Widget","price":25,"active":true}' -ExpectedStatus 200 -ExpectedContains "Widget"
Test-Route -Name "Inline validation: Valid" -Method POST -Url "/validate/inline" -Body '{"age":25,"name":"Garv"}' -ExpectedStatus 200 -ExpectedContains "valid"
Test-Route -Name "Inline validation: Fail" -Method POST -Url "/validate/inline" -Body '{"age":"abc"}' -ExpectedStatus 422 -ExpectedContains "must be a number"

# ═══════════════════════════════════════════
# GROUP 3: EXCEPTION HIERARCHY
# ═══════════════════════════════════════════
Write-Host "`n--- EXCEPTION TRANSFORMER ---" -ForegroundColor Yellow
Test-Route -Name "401 Unauthorized" -Method GET -Url "/err/401" -ExpectedStatus 401 -ExpectedContains "Token expired"
Test-Route -Name "403 Forbidden" -Method GET -Url "/err/403" -ExpectedStatus 403 -ExpectedContains "Admin only"
Test-Route -Name "404 Not Found" -Method GET -Url "/err/404" -ExpectedStatus 404 -ExpectedContains "User #99"
Test-Route -Name "409 Conflict" -Method GET -Url "/err/409" -ExpectedStatus 409 -ExpectedContains "Email already taken"
Test-Route -Name "500 Unhandled (dev mode)" -Method GET -Url "/err/500" -ExpectedStatus 500 -ExpectedContains "StateError"
Test-Route -Name "418 Abort (custom)" -Method GET -Url "/err/abort" -ExpectedStatus 418 -ExpectedContains "abort response"

# ═══════════════════════════════════════════
# GROUP 4: DI & SCOPING
# ═══════════════════════════════════════════
Write-Host "`n--- DEPENDENCY INJECTION ---" -ForegroundColor Yellow
Test-Route -Name "Singleton identity" -Method GET -Url "/di/singleton" -ExpectedStatus 200 -ExpectedContains "true"
Test-Route -Name "Scoped per-request counter" -Method GET -Url "/di/scoped" -ExpectedStatus 200 -ExpectedContains '"count":'

# ═══════════════════════════════════════════
# GROUP 5: DATABASE / ORM
# ═══════════════════════════════════════════
Write-Host "`n--- DATABASE & ORM ---" -ForegroundColor Yellow
Test-Route -Name "Query Builder SELECT" -Method GET -Url "/db/select" -ExpectedStatus 200 -ExpectedContains "users"
Test-Route -Name "Query Builder INSERT" -Method POST -Url "/db/insert" -Body '{}' -ExpectedStatus 200 -ExpectedContains "inserted"
Test-Route -Name "Transaction flow" -Method POST -Url "/db/transaction" -Body '{}' -ExpectedStatus 200 -ExpectedContains "COMMIT"

# ═══════════════════════════════════════════
# GROUP 6: MIDDLEWARE
# ═══════════════════════════════════════════
Write-Host "`n--- MIDDLEWARE ---" -ForegroundColor Yellow
Test-Route -Name "Guarded route: no token" -Method GET -Url "/guarded" -ExpectedStatus 401 -ExpectedContains "Bad token"
Test-Route -Name "Guarded route: valid token" -Method GET -Url "/guarded?token=secret" -ExpectedStatus 200 -ExpectedContains "granted"

# ═══════════════════════════════════════════
# GROUP 7: CONFIG
# ═══════════════════════════════════════════
Write-Host "`n--- CONFIG ---" -ForegroundColor Yellow
Test-Route -Name "Config system" -Method GET -Url "/config" -ExpectedStatus 200 -ExpectedContains "fallback_value"

# ═══════════════════════════════════════════
# SUMMARY
# ═══════════════════════════════════════════
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "   RESULTS: $pass PASSED / $fail FAILED / $($pass+$fail) TOTAL" -ForegroundColor $(if ($fail -eq 0) { "Green" } else { "Red" })
Write-Host "========================================`n" -ForegroundColor Cyan

$results | Format-Table -AutoSize
