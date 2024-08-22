# User Registry Hive Management

## Overview

This repository contains two PowerShell functions, `Mount-UserRegistryHive` and `Dismount-UserRegistryHive`, designed to simplify the process of mounting and dismounting user registry hives. These functions are particularly useful for administrators who need to manipulate the registry hive files of users without logging into their accounts directly.

### Functions Included

- **Mount-UserRegistryHive**: Mounts a designated user registry hive (NTUSER.DAT) and creates a script-wide PSDrive for easy manipulation of the hive's contents.
- **Dismount-UserRegistryHive**: Dismounts the user registry hive and removes the associated PSDrive.

## Mount-UserRegistryHive

### Synopsis

Mounts the designated user registry hive and creates a PSDrive for easy access.

### Syntax

```powershell
Mount-UserRegistryHive -FilePath <string> [-Name <string>]
```

#### Parameters
- FilePath (string): Mandatory. The full path to the NTUSER.DAT file to be mounted.
- Name (string): Optional. The name to be used for the mounted hive and the PSDrive. Defaults to "UserHive".

#### Example
```powershell
PS C:\> Mount-UserRegistryHive -FilePath "C:\Users\testertont\ntuser.dat" -Name TempHive
This command mounts the NTUSER.DAT file located at C:\Users\testertont\ into HKU:\ with the name TempHive and creates a PSDrive to that location with the same name.
```

### Outputs
Returns a PSObject containing:
- Success or Failure status
- Exit Codes
- Exit Messages

### Exit Codes
- 0: Successfully mounted user registry hive and created PSDrive.
- 1: Generic uncaught error.
- 100: Hive mounted, but PSDrive creation failed.
- 101: Issue occurred during mounting; hive was dismounted, but PSDrive still exists.
- 1001: File path provided not found.
- 1002: PSDrive with that name already exists.
- 1003: Issue occurred during mounting; hive was dismounted.
- 69001: Issue occurred; hive was not dismounted. Restarting the machine is recommended.

## Dismount-UserRegistryHive

### Synopsis
Dismounts a mounted user registry hive and removes the associated PSDrive.

### Syntax
```powershell
Dismount-UserRegistryHive [-Name <string>] [-Location <string>]
```

#### Parameters
- Name (string): Optional. The name of the mounted hive and PSDrive. Defaults to "UserHive".
- Location (string): Optional. The location to ensure PowerShell is not in the mounted hive during dismounting. Defaults to C:\Windows\System32.

#### Example
```powershell
PS C:\> Dismount-UserRegistryHive -Name TempHive -Location "C:\temp\packages"
This command dismounts the user registry hive named TempHive and removes the associated PSDrive, ensuring the current directory is set to C:\temp\packages.
```

### Outputs
Returns a PSObject containing:
- Success or Failure status
- Exit Codes
- Exit Messages

### Exit Codes
- 0: Successfully unmounted user registry hive and removed PSDrive.
- 1: Generic uncaught error.
- 100: Hive unmounted, but PSDrive removal failed.
- 69001: Hive remains mounted; restarting the machine is recommended.

## License
This project is licensed under the GNU General Public License v3.0. See the LICENSE file for details.


## Contributions
Contributions are welcome! If you encounter any issues or have suggestions for improvements, feel free to submit a pull request or open an issue in the repository.
