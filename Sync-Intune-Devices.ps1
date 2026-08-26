# ==========================================================
# https://github.com/nurox999
# ==========================================================



$ErrorActionPreference = "Stop"

Clear-Host

# ==========================================================
# CONFIGURATION
# ==========================================================

$RequiredModules = @(
    "Microsoft.Graph.Authentication",
    "Microsoft.Graph.DeviceManagement"
)

$RequiredCommands = @(
    "Connect-MgGraph",
    "Disconnect-MgGraph",
    "Get-MgContext",
    "Get-MgDeviceManagementManagedDevice",
    "Sync-MgDeviceManagementManagedDevice"
)

# ==========================================================
# FUNCTIONS
# ==========================================================

function Write-Header {
    param (
        [string]$Title
    )

    Write-Host ""
    Write-Host "==================================================" -ForegroundColor Cyan
    Write-Host " $Title" -ForegroundColor Cyan
    Write-Host "==================================================" -ForegroundColor Cyan
    Write-Host ""
}

function Stop-Script {
    param (
        [string]$Message
    )

    Write-Host ""
    Write-Host "ERROR:" -ForegroundColor Red
    Write-Host $Message -ForegroundColor Red
    Write-Host ""

    Read-Host "Press ENTER to exit"
    exit 1
}

# ==========================================================
# START
# ==========================================================

Write-Header "INTUNE DEVICE SYNC"

Write-Host "Running prerequisite checks..."
Write-Host ""

# ==========================================================
# CHECK POWERSHELL
# ==========================================================

Write-Host "[1/3] Checking PowerShell..."

if (-not $PSVersionTable) {
    Stop-Script "PowerShell was not found."
}

Write-Host "      PowerShell : $($PSVersionTable.PSVersion)"
Write-Host "      Status     : OK" -ForegroundColor Green

# ==========================================================
# CHECK MODULES
# ==========================================================

Write-Host ""
Write-Host "[2/3] Checking Microsoft Graph modules..."

foreach ($module in $RequiredModules) {

    $installedModule = Get-Module -ListAvailable -Name $module

    if (-not $installedModule) {

        Write-Host ""
        Write-Host "Missing module: $module" -ForegroundColor Red
        Write-Host ""
        Write-Host "Install it using:"
        Write-Host ""
        Write-Host "Install-Module $module -Scope CurrentUser" -ForegroundColor Yellow
        Write-Host ""

        Stop-Script "A required PowerShell module is missing."
    }

    Write-Host "      $module : OK" -ForegroundColor Green
}

# ==========================================================
# IMPORT MODULES
# ==========================================================

Write-Host ""
Write-Host "[3/3] Loading required modules..."

foreach ($module in $RequiredModules) {

    try {

        Import-Module $module -ErrorAction Stop

        Write-Host "      $module : OK" -ForegroundColor Green

    }
    catch {

        Stop-Script "Failed to load module: $module`n`n$($_.Exception.Message)"
    }
}

# ==========================================================
# CHECK COMMANDS
# ==========================================================

foreach ($command in $RequiredCommands) {

    if (-not (Get-Command $command -ErrorAction SilentlyContinue)) {

        Stop-Script "Required PowerShell command was not found: $command"
    }
}

Write-Host ""
Write-Host "All prerequisite checks completed successfully." -ForegroundColor Green

# ==========================================================
# DISCONNECT EXISTING GRAPH SESSION
# ==========================================================

Write-Host ""
Write-Host "Closing any existing Microsoft Graph session..."

try {
    Disconnect-MgGraph -ErrorAction SilentlyContinue
}
catch {
}

# ==========================================================
# GRAPH LOGIN
# ==========================================================

Write-Header "MICROSOFT GRAPH LOGIN"

Write-Host "Sign in with your Microsoft account."
Write-Host ""
Write-Host "A new Graph session will be created for this run."
Write-Host ""

try {

    Connect-MgGraph `
        -ContextScope Process `
        -Scopes @(
            "DeviceManagementManagedDevices.ReadWrite.All",
            "DeviceManagementManagedDevices.PrivilegedOperations.All"
        ) `
        -ErrorAction Stop
}
catch {

    Stop-Script "Microsoft Graph authentication failed.`n`n$($_.Exception.Message)"
}

# ==========================================================
# GET CONTEXT
# ==========================================================

$context = Get-MgContext

if (-not $context) {
    Stop-Script "Graph authentication succeeded, but the session information could not be retrieved."
}

# ==========================================================
# CONNECTION INFORMATION
# ==========================================================

Write-Header "CONNECTION INFORMATION"

Write-Host "Account : " -NoNewline
Write-Host $context.Account -ForegroundColor Green

Write-Host "Tenant  : " -NoNewline
Write-Host $context.TenantId -ForegroundColor Green

Write-Host ""

# ==========================================================
# GET ALL DEVICES
# ==========================================================

Write-Host "Retrieving Intune managed devices..."
Write-Host ""

try {

    $allDevices = @(Get-MgDeviceManagementManagedDevice -All -ErrorAction Stop)

}
catch {

    Stop-Script "Failed to retrieve Intune managed devices.`n`n$($_.Exception.Message)"
}

# ==========================================================
# DEVICE COUNTS
# ==========================================================

$totalIntune = $allDevices.Count

$iosCount = @(
    $allDevices |
    Where-Object {
        $_.OperatingSystem -eq "iOS"
    }
).Count

$iPadOSCount = @(
    $allDevices |
    Where-Object {
        $_.OperatingSystem -eq "iPadOS"
    }
).Count

$windowsCount = @(
    $allDevices |
    Where-Object {
        $_.OperatingSystem -like "Windows*"
    }
).Count

$macOSCount = @(
    $allDevices |
    Where-Object {
        $_.OperatingSystem -eq "macOS"
    }
).Count

$androidCount = @(
    $allDevices |
    Where-Object {
        $_.OperatingSystem -like "Android*"
    }
).Count

$knownCount =
    $iosCount +
    $iPadOSCount +
    $windowsCount +
    $macOSCount +
    $androidCount

$otherCount = $totalIntune - $knownCount

# ==========================================================
# DISPLAY TENANT INFORMATION
# ==========================================================

Write-Header "INTUNE TENANT INFORMATION"

Write-Host "Account              : $($context.Account)"
Write-Host "Tenant ID            : $($context.TenantId)"
Write-Host ""

Write-Host "---------------- DEVICE COUNTS ----------------"
Write-Host ""

Write-Host ("Total Intune devices : {0}" -f $totalIntune)
Write-Host ("iOS                  : {0}" -f $iosCount)
Write-Host ("iPadOS               : {0}" -f $iPadOSCount)
Write-Host ("Windows              : {0}" -f $windowsCount)
Write-Host ("macOS                : {0}" -f $macOSCount)
Write-Host ("Android              : {0}" -f $androidCount)
Write-Host ("Other                : {0}" -f $otherCount)

Write-Host ""

# ==========================================================
# DEVICE TYPE SELECTION
# ==========================================================

Write-Header "SYNC DEVICE SELECTION"

Write-Host "Select which devices you want to sync:"
Write-Host ""
Write-Host "[1] iOS"
Write-Host "[2] iPadOS"
Write-Host "[3] Android"
Write-Host "[4] Windows"
Write-Host "[5] macOS"
Write-Host "[6] All devices"
Write-Host "[7] Cancel"
Write-Host ""

$selection = Read-Host "Enter your selection"

switch ($selection) {

    "1" {

        $syncDevices = @(
            $allDevices |
            Where-Object {
                $_.OperatingSystem -eq "iOS"
            }
        )

        $selectionName = "iOS"
    }

    "2" {

        $syncDevices = @(
            $allDevices |
            Where-Object {
                $_.OperatingSystem -eq "iPadOS"
            }
        )

        $selectionName = "iPadOS"
    }

    "3" {

        $syncDevices = @(
            $allDevices |
            Where-Object {
                $_.OperatingSystem -like "Android*"
            }
        )

        $selectionName = "Android"
    }

    "4" {

        $syncDevices = @(
            $allDevices |
            Where-Object {
                $_.OperatingSystem -like "Windows*"
            }
        )

        $selectionName = "Windows"
    }

    "5" {

        $syncDevices = @(
            $allDevices |
            Where-Object {
                $_.OperatingSystem -eq "macOS"
            }
        )

        $selectionName = "macOS"
    }

    "6" {

        $syncDevices = @($allDevices)

        $selectionName = "All devices"
    }

    "7" {

        Write-Host ""
        Write-Host "Operation cancelled." -ForegroundColor Yellow

        Disconnect-MgGraph -ErrorAction SilentlyContinue

        Read-Host "Press ENTER to exit"
        exit 0
    }

    default {

        Write-Host ""
        Write-Host "Invalid selection." -ForegroundColor Red

        Disconnect-MgGraph -ErrorAction SilentlyContinue

        Read-Host "Press ENTER to exit"
        exit 1
    }
}

# ==========================================================
# SELECTED DEVICE COUNT
# ==========================================================

$syncCount = $syncDevices.Count

Write-Host ""
Write-Host "Selected device type : $selectionName"
Write-Host "Devices to sync      : " -NoNewline

if ($syncCount -gt 0) {
    Write-Host $syncCount -ForegroundColor Green
}
else {
    Write-Host "0" -ForegroundColor Yellow
}

Write-Host ""

# ==========================================================
# NO DEVICES
# ==========================================================

if ($syncCount -eq 0) {

    Write-Host "No devices were found for the selected platform." -ForegroundColor Yellow
    Write-Host ""

    Disconnect-MgGraph -ErrorAction SilentlyContinue

    Read-Host "Press ENTER to exit"
    exit 0
}

# ==========================================================
# FINAL CONFIRMATION
# ==========================================================

Write-Host "==================================================" -ForegroundColor Yellow
Write-Host " SYNC HAS NOT STARTED" -ForegroundColor Yellow
Write-Host "==================================================" -ForegroundColor Yellow
Write-Host ""

Write-Host "Please review the information before continuing."
Write-Host ""

Write-Host "Account        : $($context.Account)"
Write-Host "Tenant ID      : $($context.TenantId)"
Write-Host "Device type    : $selectionName"
Write-Host "Devices        : $syncCount"
Write-Host ""

Read-Host "Press ENTER to start the sync"

# ==========================================================
# START SYNC
# ==========================================================

Write-Header "SYNC STARTED"

$success = 0
$failed = 0

foreach ($device in $syncDevices) {

    Write-Host "Syncing: $($device.DeviceName) [$($device.OperatingSystem)]"

    try {

        Sync-MgDeviceManagementManagedDevice `
            -ManagedDeviceId $device.Id `
            -ErrorAction Stop

        Write-Host "  SUCCESS" -ForegroundColor Green

        $success++

    }
    catch {

        Write-Host "  FAILED: $($_.Exception.Message)" -ForegroundColor Red

        $failed++
    }
}

# ==========================================================
# FINAL RESULT
# ==========================================================

Write-Header "SYNC COMPLETED"

Write-Host "Account        : $($context.Account)"
Write-Host "Tenant ID      : $($context.TenantId)"
Write-Host "Device type    : $selectionName"
Write-Host ""

Write-Host "Devices        : $syncCount"

Write-Host "Successful     : " -NoNewline
Write-Host $success -ForegroundColor Green

Write-Host "Failed         : " -NoNewline

if ($failed -gt 0) {
    Write-Host $failed -ForegroundColor Red
}
else {
    Write-Host $failed -ForegroundColor Green
}

Write-Host ""

# ==========================================================
# DISCONNECT
# ==========================================================

Disconnect-MgGraph -ErrorAction SilentlyContinue

Write-Host "Microsoft Graph session closed." -ForegroundColor Green
Write-Host ""

Read-Host "Press ENTER to exit"
