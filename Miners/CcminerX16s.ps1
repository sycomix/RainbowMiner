﻿using module ..\Include.psm1

$Path = ".\Bin\NVIDIA-X16s\ccminer.exe"
$Uri = "https://github.com/RainbowMiner/miner-binaries/releases/download/v1.0-ccminerx16s-cuda9.2/ccminerx16sa1cuda9.2_v1.0.7z"

$Type = "NVIDIA"
if (-not $Devices.$Type -or $Config.InfoOnly) {return} # No NVIDIA present in system

$Commands = [PSCustomObject]@{
    #"x16r"  = " -N 10" #X16R RavenCoin
    "x16s"  = "" #X16S PigeonCoin
}

$Default_Profile = 2
$Profiles = [PSCustomObject]@{
    "x16r" = 4
    "x16s" = 4
}

$Default_Tolerance = 0.1
$Tolerances = [PSCustomObject]@{
    "x16r" = 0.5
}

$Default_HashRates_Duration = "Week"
$HashRates_Durations = [PSCustomObject]@{
    "x16r" = "Day"
}

$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName

$DeviceIDsAll = (Get-GPUlist $Type) -join ','

$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | Where-Object {$Pools.(Get-Algorithm $_).Protocol -eq "stratum+tcp" <#temp fix#>} | ForEach-Object {

    $Algorithm_Norm = Get-Algorithm $_
    $HashRates_Duration = if ( $HashRates_Durations.$_ ) { $HashRates_Durations.$_ } else { $Default_HashRates_Duration }

    [PSCustomObject]@{
        Type = $Type
        Path = $Path
        Arguments = "-r 0 -d $($DeviceIDsAll) -a $_ -o $($Pools.$Algorithm_Norm.Protocol)://$($Pools.$Algorithm_Norm.Host):$($Pools.$Algorithm_Norm.Port) -u $($Pools.$Algorithm_Norm.User) -p $($Pools.$Algorithm_Norm.Pass)$($Commands.$_)"
        HashRates = [PSCustomObject]@{$Algorithm_Norm = $Stats."$($Name)_$($Algorithm_Norm)_HashRate".$HashRates_Duration}
        API = "Ccminer"
        Port = 4068
        URI = $Uri
        MSIAprofile = if ( $Profiles.$_ ) { $Profiles.$_ } else { $Default_Profile }
        FaultTolerance = if ( $Tolerances.$_ ) { $Tolerances.$_ } else { $Default_Tolerance }
    }
}