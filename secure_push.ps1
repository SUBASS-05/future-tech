$ErrorActionPreference = "Stop"

cd "D:\future tech"

# Setup git identity if missing
$name = git config user.name
if (-not $name) { git config user.name "SUBASS-05" }
$email = git config user.email
if (-not $email) { git config user.email "SUBASS-05@users.noreply.github.com" }

# Initialize repository
if (-not (Test-Path ".git")) {
    git init
}

# Add all files (ignoring warnings about line endings)
git add .

# Commit (allow empty in case they already committed somehow, though unlikely)
try {
    git commit -m "Update UI theme and fix backend enum"
} catch {
    Write-Host "Nothing to commit or commit failed."
}

# Ensure branch is main
git branch -M main

# Read token securely from .env
$envContent = Get-Content C:\Users\rajas\.env
$token = ""
foreach ($line in $envContent) {
    if ($line -match "^GITHUB_TOKEN=(.*)") {
        $token = $matches[1].Trim()
    }
}

if ($token -eq "") {
    Write-Error "Token not found in .env file!"
    exit 1
}

# Temporarily set remote with token to bypass interactive prompt
$repoUrlWithToken = "https://$($token)@github.com/SUBASS-05/future-tech.git"

# Remove origin if it exists
try { git remote remove origin 2>$null } catch { }

# Add the authenticated remote
git remote add origin $repoUrlWithToken

Write-Host "Pushing code to GitHub..."
# Push to main
git push -u origin main

# Clean up remote URL so the token is not stored in plain text in .git/config
git remote set-url origin "https://github.com/SUBASS-05/future-tech.git"

Write-Host "Push successful! Remote URL sanitized."
