function Mount-UserRegistryHive {
    <#
    .SYNOPSIS
        Mounts designated User Registry Hive
    .DESCRIPTION
        Will Mount desginated User Registry Hive as well as create a script wide PSDrive to be used for easy manipulation of the contents inside of the mounted hive.
    .EXAMPLE
        PS C:\> Mount-UserRegistryHive -FilePath "C:\Users\testertont\ntuser.dat" -Name TempHive
        Mounts the NTUSER.DAT file located at C:\Users\testertont\ into HKU: with the name TempHive and creates a script scoped PSDrive to that location with the name TempHive
    .INPUTS
        FilePath <String> Is Required - No Default - Full path to the user's NTUSER.DAT file you want to be mounted
        Name <String> Is Not Required - By Default is UserHive - The Name to be used for the NTUSER.DAT file when mounting and to be used for the PSDrive created.
    .OUTPUTS
        PSObject containing Success or Failure, Exit Codes, and Exit Messages
    .NOTES
        Created by Nick Welter
        Exit Codes -
        0: Successfully mounted user registry hive and created PSDrive for it
        1: Generic Uncaught Error
        100: Successfully mounted user registry hive but PSDrive creation failed
        101: Issue occured while attempting to mount registry hive. Was able to dismount hive but PSDrive still exists.
        1001: File path provided not found
        1002: PSDrive with that name already exists
        1003: Issue occured while attempting to mount registry hive. Was able to dismount
        69001: Issue occured while attempting to mount registry hive. Was unable to dismount user registry hive. Highly recommend stopping and restarting machine.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$FilePath,
        [Parameter(Mandatory=$false)]
        [string]$Name = "UserHive"
    )

    #Test Path exisits and that file is a ntuser.dat file
    if (!(Test-Path -Path $FilePath -ErrorAction SilentlyContinue)){
        Write-Verbose -Message "$($FilePath) does not exist."
        $Properties = @{
            ExitCode = 1001
            Message = "$($FilePath) does not exist."
            WasSuccessful = $false
        }
        $Results = New-Object -TypeName psobject -Property $Properties
        return $Results
    }

    #Setting Root to HKEY_USERS with Name provided
    $Root = "HKU\$Name"

    #check to see if PSDrive already exists, just in case
    try{
        Get-PSDrive -PSProvider Registry -Name $Name -ErrorAction Stop
    }catch{
        if($Error[0].Exception -like "*already exists*"){
            $Properties = @{
                ExitCode = 1002
                Message = "PSDrive with name $($Name) Already exists."
                WasSuccessful = $false
            }
            $Results = New-Object -TypeName psobject -Property $Properties
            return $Results
        }
    }

    #loading User Registry Hive
    try {
        Write-Verbose -Message "Loading User Registry Hive"
        Execute-Process -Path "C:\Windows\System32\reg.exe" -CreateNoWindow -Parameters "load $($Root) $($FilePath)" -ErrorAction Stop
        Write-Verbose -Message "Succesfully loaded User Registry Hive"

        #Create PS Drive here, use -Scope Script to allow usage outside the function
        try {
            New-PSDrive -PSProvider Registry -Name $Name -Root $Root -Scope Script -ErrorAction Stop
        }
        catch {
            Write-Verbose -Message "Was unable to Create PSDrive named $($Name) located at $($Root)"
        }
    }
    catch {
        Write-Error -Message "Was unable to load User Registry Hive. Printing error below."
        Write-Error -Message "$($Error[0].Exception.Message)"

        #Running Dismount sequence to make sure hive is not loaded and to unload if it is.
        $Dismount = Dismount-UserRegistryHive -Name $Name

        #switch to see what the results were and act accordingly
        switch ($Dismount.ExitCode) {
            0 { $Properties = @{
                ExitCode = 1003
                Message = "Issue occured while attempting to mount registry hive. Was able to dismount."
                WasSuccessful = $false
                    }
                $Results = New-Object -TypeName psobject -Property $Properties
                return $Results }
            1 { $Properties = @{
                ExitCode = 1
                Message = "Issue occured while attempting to mount registry hive. Received generic/uncaught error while attempting to dismount."
                WasSuccessful = $false
                    }
                $Results = New-Object -TypeName psobject -Property $Properties
                return $Results  }
            100 {
                $Properties = @{
                    ExitCode = 101
                    Message = "Issue occured while attempting to mount registry hive. Was able to dismount hive but PSDrive still exists."
                    WasSuccessful = $false
                        }
                    $Results = New-Object -TypeName psobject -Property $Properties
                    return $Results }
            69001 { $Properties = @{
                ExitCode = 69001
                Message = "Issue occured while attempting to mount registry hive. Was unable to dismount user registry hive. Highly recommend stopping and restarting machine."
                WasSuccessful = $false
                    }
                $Results = New-Object -TypeName psobject -Property $Properties
                return $Results  }
            Default { $Properties = @{
                ExitCode = $Dismount.ExitCode
                Message = $Dismount.Message
                WasSuccessful = $Dismount.WasSuccessful
                    }
                $Results = New-Object -TypeName psobject -Property $Properties
                return $Results }
        }
    }

    #recheck if PSDrive was created, return if output if not there
    if (Get-PSDrive -PSProvider Registry -Name $Name -ErrorAction SilentlyContinue) {
        #returns if the mount and PSDrive creation were successful
        $Properties = @{
            ExitCode = 0
            Message = "User hive mounted successfully. PSDrive named $($Name) successfully created"
            WasSuccessful = $true
        }
        $Results = New-Object -TypeName psobject -Property $Properties
        return $Results
    }else {
        #returns if the mount was successful but PSDrive creation was not
        $Properties = @{
            ExitCode = 100
            Message = "User hive mounted successfully. PSDrive named $($Name) was not successfully created"
            WasSuccessful = $true
        }
        $Results = New-Object -TypeName psobject -Property $Properties
        return $Results
    }
}