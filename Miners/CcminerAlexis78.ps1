﻿using module ..\Include.psm1

param(
    [PSCustomObject]$Pools,
    [Bool]$InfoOnly
)

$Path = ".\Bin\NVIDIA-Alexis78\ccminer.exe"
$Uri = "https://github.com/RainbowMiner/miner-binaries/releases/download/v1.2-ccmineralexis78/ccmineralexis78_1.2.7z"
$Port = "102{0:d2}"
$DevFee = 0.0
$Cuda = "9.0"

if (-not $Session.DevicesByTypes.NVIDIA -and -not $InfoOnly) {return} # No NVIDIA present in system

$Commands = [PSCustomObject[]]@(
    #GPU - profitable 20/04/2018
    #[PSCustomObject]@{MainAlgorithm = "c11"; Params = "-N 1"} #c11 (CcminerSupr fastest)
    [PSCustomObject]@{MainAlgorithm = "hsr"; Params = "-N 1"} #HSR, HShare
    #[PSCustomObject]@{MainAlgorithm = "keccak"; Params = "-N 1"} #Keccak
    #[PSCustomObject]@{MainAlgorithm = "keccakc"; Params = "-N 1"} #Keccakc
    #[PSCustomObject]@{MainAlgorithm = "lyra2"; Params = ""} #Lyra2
    #[PSCustomObject]@{MainAlgorithm = "lyra2v2"; Params = "-N 1"} #lyra2v2
    #[PSCustomObject]@{MainAlgorithm = "lyra2z"; Params = "-N 1"} #lyra2z
    #[PSCustomObject]@{MainAlgorithm = "neoscrypt"; Params = ""} #NeoScrypt
    [PSCustomObject]@{MainAlgorithm = "poly"; Params = "-N 1"} #Polytimos
    #[PSCustomObject]@{MainAlgorithm = "skein"; Params = "-N 1"} #Skein
    #[PSCustomObject]@{MainAlgorithm = "skein2"; Params = "-N 1"} #skein2
    #[PSCustomObject]@{MainAlgorithm = "veltor"; Params = "-N 1"} #Veltor
    #[PSCustomObject]@{MainAlgorithm = "whirlcoin"; Params = ""} #WhirlCoin
    #[PSCustomObject]@{MainAlgorithm = "whirlpool"; Params = ""} #Whirlpool
    #[PSCustomObject]@{MainAlgorithm = "whirlpoolx"; Params = ""} #whirlpoolx
    #[PSCustomObject]@{MainAlgorithm = "x11evo"; Params = "-N 1"} #X11evo
    [PSCustomObject]@{MainAlgorithm = "x17"; Params = "-N 1"} #X17

    # ASIC - never profitable 20/04/2018
    #[PSCustomObject]@{MainAlgorithm = "blake2s"; Params = ""} #Blake2s
    #[PSCustomObject]@{MainAlgorithm = "blake"; Params = ""} #blake
    #[PSCustomObject]@{MainAlgorithm = "blakecoin"; Params = ""} #Blakecoin
    #[PSCustomObject]@{MainAlgorithm = "cryptolight"; Params = ""} #cryptolight
    #[PSCustomObject]@{MainAlgorithm = "cryptonight"; Params = ""} #CryptoNight
    #[PSCustomObject]@{MainAlgorithm = "decred"; Params = ""} #Decred
    #[PSCustomObject]@{MainAlgorithm = "lbry"; Params = " -N 1"} #Lbry (fastest)
    #[PSCustomObject]@{MainAlgorithm = "myr-gr"; Params = " -N 1"} #MyriadGroestl (fastest)
    #[PSCustomObject]@{MainAlgorithm = "nist5"; Params = " -N 1"} #Nist5 (fastest)
    #[PSCustomObject]@{MainAlgorithm = "quark"; Params = ""} #Quark
    #[PSCustomObject]@{MainAlgorithm = "qubit"; Params = ""} #Qubit
    #[PSCustomObject]@{MainAlgorithm = "scrypt"; Params = ""} #Scrypt
    #[PSCustomObject]@{MainAlgorithm = "scrypt:N"; Params = ""} #scrypt:N
    #[PSCustomObject]@{MainAlgorithm = "sha256d"; Params = ""} #sha256d
    #[PSCustomObject]@{MainAlgorithm = "sia"; Params = ""} #SiaCoin
    #[PSCustomObject]@{MainAlgorithm = "sib"; Params = ""} #Sib
    #[PSCustomObject]@{MainAlgorithm = "x11"; Params = ""} #X11
    #[PSCustomObject]@{MainAlgorithm = "x13"; Params = ""} #x13
    #[PSCustomObject]@{MainAlgorithm = "x14"; Params = ""} #x14
    #[PSCustomObject]@{MainAlgorithm = "x15"; Params = ""} #x15
    #[PSCustomObject]@{MainAlgorithm = "bitcore"; Params = ""} #Bitcore
)

$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName

if ($InfoOnly) {
    [PSCustomObject]@{
        Type      = @("NVIDIA")
        Name      = $Name
        Path      = $Path
        Port      = $Miner_Port
        Uri       = $Uri
        DevFee    = $DevFee
        ManualUri = $ManualUri
        Commands  = $Commands
    }
    return
}

if (-not (Confirm-Cuda -ActualVersion $Session.Config.CUDAVersion -RequiredVersion $Cuda -Warning $Name)) {return}

$Session.DevicesByTypes.NVIDIA | Select-Object Vendor, Model -Unique | ForEach-Object {
    $Miner_Device = $Session.Devices | Where-Object Vendor -EQ $_.Vendor | Where-Object Model -EQ $_.Model
    $Miner_Port = $Port -f ($Miner_Device | Select-Object -First 1 -ExpandProperty Index)
    $Miner_Model = $_.Model
    $Miner_Name = (@($Name) + @($Miner_Device.Name | Sort-Object) | Select-Object) -join '-'
    $Miner_Port = Get-MinerPort -MinerName $Name -DeviceName @($Miner_Device.Name) -Port $Miner_Port

    $DeviceIDsAll = $Miner_Device.Type_Vendor_Index -join ','

    $Commands | ForEach-Object {

        $Algorithm_Norm = Get-Algorithm $_.MainAlgorithm

        if ($Pools.$Algorithm_Norm.Host -and $Miner_Device) {
            [PSCustomObject]@{
                Name = $Miner_Name
                DeviceName = $Miner_Device.Name
                DeviceModel = $Miner_Model
                Path = $Path
                Arguments = "-R 1 -b $($Miner_Port) -d $($DeviceIDsAll) -a $($_.MainAlgorithm) -q -o $($Pools.$Algorithm_Norm.Protocol)://$($Pools.$Algorithm_Norm.Host):$($Pools.$Algorithm_Norm.Port) -u $($Pools.$Algorithm_Norm.User) -p $($Pools.$Algorithm_Norm.Pass) $($_.Params)"
                HashRates = [PSCustomObject]@{$Algorithm_Norm = $Session.Stats."$($Miner_Name)_$($Algorithm_Norm)_HashRate"."$(if ($_.HashrateDuration){$_.HashrateDuration}else{"Week"})"}
                API = "Ccminer"
                Port = $Miner_Port
                Uri = $Uri
				DevFee = $DevFee
                FaultTolerance = $_.FaultTolerance
                ExtendInterval = $_.ExtendInterval
                ManualUri = $ManualUri
            }
        }
    }
}
