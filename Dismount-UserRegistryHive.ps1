function Dismount-UserRegistryHive {
    <#
    .SYNOPSIS
        Dismounts designated User Registry Hive
    .DESCRIPTION
        Works in conjunction with Function Mount-UserRegistryHive. will dismount a mounted user registry hive and the PSDrive created for it from the Mounting function.
    .EXAMPLE
        PS C:\> Dismount-UserRegistryHive -Name TempHive -Location "C:\temp\packages"
        Sets the location to the provided location, or uses the default, and looks for and if found removes the PSDrive called TempHive that links to the mounted user hive. Will then Look up and remove the mounted user hive with the same name.
    .INPUTS
        Name <String> Is Not Required - by Default is called UserHive - if not using the defualt name provided in the related Mount function, provided name will be used to find user hive and dismount as well as find and remove related PSDrive  
        Location <String> Is Not Required - by Default is C:\Windows\System32 - Location is used to ensure powershell is not sitting inside the mounted user hive to allow for a smooth dismounting
    .OUTPUTS
        Success or Failure, Exit Codes, Exit Messages, etc.
    .NOTES
        Created by Nick Welter
        Exit Codes -
        0: Successfully unmounted user registry hive
        1: Generic Uncaught Error
        100: User hive unmounted successfully. PSDrive was not successfully removed
        69001: Hive Remains to be mounted. Highly recommend stopping and restarting machine.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$False)]
        [string]$Name = "UserHive",
        [Parameter(Mandatory=$False)]
        [string]$Location = "C:\Windows\System32"
    )

    #Checking Location Parameter, making sure it's somewhere in the C: Drive
    if (($Location -notlike "C:\*") -or (!(Test-Path -Path $Location -ErrorAction SilentlyContinue))){
        Write-Verbose -Message "Given Location is not in a viable location or is not outside of the HKU and/or PSDrive. Resetting Location to C:\Windows\System32"
        $Location = "C:\Windows\System32"
    }
    #cd outside of PSDrive
    try {
        Write-Verbose -Message "Setting working directory to $($Location) to ensure Powershell is not inside the Mounted User Registery"
        Set-Location -Path $Location
    }
    catch {
        Write-Error -Message "Was unable to move working directory to new location. Will attempt to continue dismounting registry hive"
        Write-Error -Message "$($Error[0].Exception.Message)"
    }
    #checking to see if PSDrive exists and removing PSDrive
    if (Get-PSDrive -PSProvider Registry -Name $Name -ErrorAction SilentlyContinue) {
        Write-Verbose -Message "PSDrive Found. Attempting to Remove PSDrive."
        try {
            Remove-PSDrive -Name $Name -Force -ErrorAction Stop
            Write-Verbose -Message "Successfully removed PSDrive."
        }
        catch {
            Write-Error -Message "Failed to Remove PSDrive."
            Write-Error -Message "$($Error[0].Exception.Message)"
        }
    }else {
        Write-Verbose -Message "No PSDrive found with provided Name. Checking for PSDrive using default name."
        if (!(Get-PSDrive -PSProvider Registry -Name "UserHive" -ErrorAction SilentlyContinue)) {
            Write-Verbose -Message "No PSDrive found with Default name either."
        }else {
            Write-Verbose -Message "PSDrive Found using default name. Attempting to remove PSDrive"
            try {
                Remove-PSDrive -Name "UserHive" -Force -ErrorAction Stop
                Write-Verbose -Message "Successfully removed PSDrive"
            }
            catch {
                Write-Error -Message "Failed to Remove PSDrive."
                Write-Error -Message "$($Error[0].Exception.Message)"
            }
        }
    }
    #Running garbage removal
    try {
        Write-Verbose -Message "Running garbage collect to ensure nothing is potentially being used in the user hive still."
        [gc]::Collect()
    }
    catch {
        Write-Error -Message "Failed to clear/Collect Garbage. Will continue attempting to dismount user hive"
        Write-Error -Message "$($Error[0].Exception.Message)"
    }
    #unloading user registry hive
    try {
        Write-Verbose -Message "Attempting to dismount user registry hive."
        Execute-Process -Path "C:\Windows\System32\reg.exe" -CreateNoWindow -Parameters "unload HKU\$($Name)" -ErrorAction Stop
        Write-Verbose -Message "Successfully dismounted user registry hive."

        if (!(Get-PSDrive -PSProvider Registry -Name $Name -ErrorAction SilentlyContinue) -or !(Get-PSDrive -PSProvider Registry -Name "UserHive" -ErrorAction SilentlyContinue)) {
            #returns if the mount and PSDrive creation were successful
            $Properties = @{
                ExitCode = 0
                Message = "Successfully unmounted user registry hive and removed PSDrive named $($Name)."
                WasSuccessful = $true
            }
            $Results = New-Object -TypeName psobject -Property $Properties
            return $Results
        }else {
            #returns if the mount was successful but PSDrive creation was not
            $Properties = @{
                ExitCode = 100
                Message = "User hive unmounted successfully. PSDrive named $($Name) was not successfully removed"
                WasSuccessful = $true
            }
            $Results = New-Object -TypeName psobject -Property $Properties
            return $Results
        }
    }
    catch {
        Write-Verbose -Message "Failed to dismount user registry hive. Will reattempt dismounting over next 2-3 minutes. Error printed below."
        Write-Error -Message "$($Error[0].Exception.Message)"
        Write-Verbose -Message "Running garbage collect again"
        try {
            [gc]::Collect()
        }
        catch {
            Write-Verbose -Message "Failed to collect garbage"
        }
        Write-Verbose -Message "Reattempting to dismount User Registry Hive"
        $Unloaded = $false
        $Attempts = 0
        while (!($Unloaded) -and ($Attempts -lt 5)) {
            if (!(Get-Item -Path Registry::HKEY_USERS\$Name -ErrorAction SilentlyContinue)) {
                $Unloaded = $true
                break
            }
            try {
                Execute-Process -Path "C:\Windows\System32\reg.exe" -CreateNoWindow -Parameters "unload HKU\$($Name)" -ErrorAction Stop
            }
            catch {
                Write-Verbose -Message "Failed to unload Hive"
                Write-Error -Message "$($Error[0].Exception.Message)"
                Write-Verbose -Message "Reattempting dismount in 30 secs"
            }
            $Attempts++
            Start-Sleep -Seconds 30
            Write-Verbose -Message "Running garbage collect again"
            try {
                [gc]::Collect()
            }
            catch {
                Write-Verbose -Message "Failed to collect garbage"
            }
        }
        #final check on if hive is unloaded or not
        if ($Unloaded) {
            Write-Verbose -Message "Hive Successfully Unloaded."
            $Properties = @{
                ExitCode = 0
                Message = "User hive dismounted successfully."
                WasSuccessful = $true
            }
            $Results = New-Object -TypeName psobject -Property $Properties
            return $Results
        }else {
            Write-Verbose -Message "Hive Remains to be mounted. Highly recommend stopping and restarting machine."
            $Properties = @{
                ExitCode = 69001
                Message = "Hive Remains to be mounted. Highly recommend stopping and restarting machine."
                WasSuccessful = $false
            }
            $Results = New-Object -TypeName psobject -Property $Properties
            return $Results
        }
    }
}