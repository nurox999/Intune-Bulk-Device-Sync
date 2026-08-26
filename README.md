# Intune Bulk Device Sync

A PowerShell utility that allows Microsoft Intune administrators to trigger bulk synchronization for managed devices through Microsoft Graph.

## Why was this created?

Microsoft Intune does not provide a simple option in the admin portal to trigger a **bulk device sync** for multiple managed devices at once.

When managing a large number of devices, administrators may need to open devices individually and manually trigger a sync operation. This can become especially time-consuming in large environments.

This script was created to provide a simple way to perform bulk synchronization using the Microsoft Graph PowerShell SDK.

Instead of manually synchronizing devices one by one, administrators can authenticate to their Intune tenant, review the device inventory, select a platform, and trigger synchronization for all devices matching that platform.

---

## Features

- Bulk synchronization of Intune managed devices
- Interactive Microsoft Graph authentication
- Multi-tenant support
- No hard-coded tenant or user information
- Displays the authenticated Microsoft account
- Displays the Tenant ID
- Retrieves Intune managed devices
- Displays device counts by operating system
- Platform-based device selection
- Supports:
  - iOS
  - iPadOS
  - Android
  - Windows
  - macOS
  - All devices
- Shows the number of devices that will be synchronized
- Requires explicit confirmation before synchronization starts
- Displays per-device synchronization status
- Displays successful and failed device counts
- Automatically disconnects the Microsoft Graph session
- Checks required PowerShell modules before execution

---

## How it works

The script connects to Microsoft Graph using interactive authentication.

After authentication, it retrieves the managed devices from the connected Intune tenant and displays an overview of the device inventory.

Example:

```text
==================================================
 INTUNE TENANT INFORMATION
==================================================

Account              : admin@example.com
Tenant ID            : xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx

---------------- DEVICE COUNTS ----------------

Total Intune devices : 1250
iOS                  : 500
iPadOS               : 100
Windows              : 300
macOS                : 150
Android              : 180
Other                : 20

The administrator can then select which device platform should be synchronized.

==================================================
 SYNC DEVICE SELECTION
==================================================

Select which devices you want to sync:

[1] iOS
[2] iPadOS
[3] Android
[4] Windows
[5] macOS
[6] All devices
[7] Cancel

Enter your selection:

After selecting a platform, the script displays the number of devices that will be affected.

For example:

Selected device type : iOS
Devices to sync      : 500

The synchronization does not start immediately.

The script displays the tenant, account, selected platform and device count and waits for administrator confirmation.

==================================================
 SYNC HAS NOT STARTED
==================================================

Please review the information before continuing.

Account        : admin@example.com
Tenant ID      : xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
Device type    : iOS
Devices        : 500

Press ENTER to start the sync:

This confirmation step is intentional and helps prevent accidental bulk synchronization against the wrong tenant or platform.
