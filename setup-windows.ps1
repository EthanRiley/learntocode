# =====================================================================
#  Java lab setup for Windows
#  Installs: Java 25 (Temurin), Git, VS Code, VS Code Java extensions
#
#  HOW TO RUN: right-click the Start button, open "Terminal", then run:
#      powershell -ExecutionPolicy Bypass -File setup-windows.ps1
# =====================================================================

$ErrorActionPreference = 'Stop'

function Step($msg) { Write-Host "`n==> $msg" -ForegroundColor Cyan }
function Ok($msg)   { Write-Host "    OK   $msg" -ForegroundColor Green }
function Bad($msg)  { Write-Host "    FAIL $msg" -ForegroundColor Red }

function Refresh-Path {
    $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' +
                [Environment]::GetEnvironmentVariable('Path', 'User')
}

# --- winget -----------------------------------------------------------
Step 'Checking for winget'
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Bad 'winget was not found.'
    Write-Host '    Install "App Installer" from the Microsoft Store, then run this script again.'
    Write-Host '    https://apps.microsoft.com/detail/9NBLGGH4NNS1'
    exit 1
}
Ok 'winget is available'

# --- Install packages ---------------------------------------------------
$packages = @(
    @{ Id = 'EclipseAdoptium.Temurin.25.JDK'; Name = 'Java 25 (Temurin JDK)' },
    @{ Id = 'Git.Git';                        Name = 'Git' },
    @{ Id = 'Microsoft.VisualStudioCode';     Name = 'VS Code' }
)

foreach ($pkg in $packages) {
    Step "Installing $($pkg.Name)"
    winget list --id $pkg.Id --exact --accept-source-agreements *> $null
    if ($LASTEXITCODE -eq 0) {
        Ok "$($pkg.Name) is already installed"
        continue
    }
    winget install --id $pkg.Id --exact --silent `
        --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -ne 0) {
        Bad "Could not install $($pkg.Name) (winget exit code $LASTEXITCODE)"
        exit 1
    }
    Ok "$($pkg.Name) installed"
}

Refresh-Path

# --- JAVA_HOME ----------------------------------------------------------
Step 'Setting JAVA_HOME'
$jdk = Get-ChildItem 'C:\Program Files\Eclipse Adoptium' -Directory -Filter 'jdk-25*' -ErrorAction SilentlyContinue |
       Sort-Object Name -Descending | Select-Object -First 1
if ($jdk) {
    [Environment]::SetEnvironmentVariable('JAVA_HOME', $jdk.FullName, 'User')
    $env:JAVA_HOME = $jdk.FullName
    Ok "JAVA_HOME = $($jdk.FullName)"
} else {
    Bad 'Could not find the Java 25 folder under C:\Program Files\Eclipse Adoptium'
}

# --- VS Code extensions -------------------------------------------------
Step 'Installing VS Code Java extensions'
$code = Get-Command code -ErrorAction SilentlyContinue
if (-not $code) {
    foreach ($p in "$env:LOCALAPPDATA\Programs\Microsoft VS Code\bin\code.cmd",
                   "$env:ProgramFiles\Microsoft VS Code\bin\code.cmd") {
        if (Test-Path $p) { $code = $p; break }
    }
}
if ($code) {
    & $code --install-extension vscjava.vscode-java-pack --force
    Ok 'Extension Pack for Java installed'
} else {
    Bad 'Could not find the "code" command. Open VS Code and install "Extension Pack for Java" manually.'
}

# --- Check everything ---------------------------------------------------
Step 'Checking your setup'
$allGood = $true

foreach ($tool in @(
    @{ Name = 'java';  Args = '--version' },
    @{ Name = 'javac'; Args = '--version' },
    @{ Name = 'git';   Args = '--version' }
)) {
    try {
        $out = & $tool.Name $tool.Args 2>&1 | Select-Object -First 1
        Ok "$($tool.Name): $out"
    } catch {
        Bad "$($tool.Name) not found"
        $allGood = $false
    }
}

if ($code) {
    Ok "code: $(& $code --version | Select-Object -First 1)"
} else {
    Bad 'code not found'
    $allGood = $false
}

$testDir = Join-Path $env:TEMP 'java-setup-check'
New-Item -ItemType Directory -Force $testDir | Out-Null
$testFile = Join-Path $testDir 'Hello.java'
Set-Content -Path $testFile -Encoding ascii -Value @'
class Hello {
    public static void main(String[] args) {
        System.out.println("Hello from Java!");
    }
}
'@
try {
    $result = & java $testFile 2>&1
    if ($result -match 'Hello from Java!') { Ok 'Compiled and ran a test Java program' }
    else { Bad "Test program output: $result"; $allGood = $false }
} catch {
    Bad 'Could not run a test Java program'
    $allGood = $false
}
Remove-Item -Recurse -Force $testDir

Write-Host ''
if ($allGood) {
    Write-Host 'All set! Close this window and open a NEW terminal before you start.' -ForegroundColor Green
} else {
    Write-Host 'Some checks failed. Show this window to your instructor.' -ForegroundColor Red
    exit 1
}
