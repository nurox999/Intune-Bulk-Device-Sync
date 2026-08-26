# Intune-Sync-All-Devices Powershell
# Intune Device Sync

A PowerShell utility for synchronizing Microsoft Intune managed devices on demand using Microsoft Graph PowerShell.

The script is designed for Intune administrators who need a simple way to authenticate to different Microsoft Entra ID tenants, review device inventory, select a device platform, and trigger a device sync operation.

## Features

- Interactive Microsoft Graph authentication
- Multi-tenant support
- Displays authenticated account
- Displays Tenant ID
- Retrieves Intune managed devices
- Displays device counts by operating system
- Platform-specific synchronization
- Supports:
  - iOS
  - iPadOS
  - Android
  - Windows
  - macOS
  - All devices
- Confirmation required before synchronization
- Per-device sync status
- Success and failure counters
- Automatic Microsoft Graph session cleanup
- Dependency and prerequisite checks
- No stored credentials or hard-coded tenant information

## Requirements

### Operating System

Supported environments:

- macOS
- Windows
- Linux

### PowerShell

PowerShell 7 or later is required.

Verify the installation:

```powershell
$PSVersionTable.PSVersion
