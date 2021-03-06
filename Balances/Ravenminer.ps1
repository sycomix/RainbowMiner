﻿param(
    $Config
)

$Ravenminer_Regions = "eu", "us"

$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName
$PoolConfig = $Config.Pools.$Name

if (!$PoolConfig.RVN) {
    Write-Log -Level Verbose "Pool Balance API ($Name) has failed - no wallet address specified."
    return
}

$Request = [PSCustomObject]@{}

$Out = [PSCustomObject]@{
            Caption     = "$($Name) (RVN)"
            Currency    = 'RVN'
            Balance     = 0
            Pending     = 0
            Total       = 0
            Paid        = 0
            Earned      = 0
            Payouts     = @()
            LastUpdated = $null
        }

$Ravenminer_Regions | ForEach-Object {
    if ( $_ -eq "eu" ) {$Ravenminer_Host = "eu.ravenminer.com"}
    else {$Ravenminer_Host = "ravenminer.com"}

    $Success = $true
    try {
        if (-not ($Request = Invoke-RestMethod "https://$($Ravenminer_Host)/api/wallet?address=$($PoolConfig.RVN)" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop)){$Success = $false}
    }
    catch {
        if ($Error.Count){$Error.RemoveAt(0)}
        $Success=$false
    }

    if (-not $Success) {
        $Success = $true
        try {
            $Request = Invoke-WebRequest -UseBasicParsing "https://$($Ravenminer_Host)/site/wallet_results?address=$($PoolConfig.RVN)" -UserAgent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/66.0.3359.181 Safari/537.36" -TimeoutSec 10 -ErrorAction Stop
            if (-not ($Values = ([regex]'([\d\.]+?)\s+RVN').Matches($Request.Content).Groups | Where-Object Name -eq 1)){$Success=$false}
            else {
                $Request = [PSCustomObject]@{
                    "currency" = "RVN"
                    "balance" = [Double]($Values | Select-Object -Index 1).Value
                    "unsold"  = [Double]($Values | Select-Object -Index 0).Value
                    "unpaid"  = [Double]($Values | Select-Object -Index 2).Value                
                    "total"  = [Double]($Values | Select-Object -Index 4).Value
                }
            }
        }
        catch {
            if ($Error.Count){$Error.RemoveAt(0)}
            $Success=$false
        }
    }

    if (-not $Success) {
        Write-Log -Level Warn "Pool Balance API ($Name) for Region $($_) has failed. "
    }

    if (($Request | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Measure-Object Name).Count -le 1) {
        Write-Log -Level Warn "Pool Balance API ($Name) for Region $($_) returned nothing. "
        return
    }

    if ($Request.total) {
        $Out.Currency     = $Request.currency
        $Out.Balance     += $Request.balance
        $Out.Pending     += $Request.unsold
        $Out.Total       += $Request.unpaid
        $Out.Paid        += $Request.total - $Request.unpaid
        $Out.Earned      += $Request.total
        $Out.Payouts     += @($Request.payouts | Select-Object)
        $Out.lastupdated  = (Get-Date).ToUniversalTime()
    }
}

if ($Out.earned) {$Out}