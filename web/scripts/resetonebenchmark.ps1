﻿param($Parameters)

$text = ''
$count = 0

if ($Parameters.name -and $Parameters.algorithm -and $Parameters.DeviceModel) {
	$Algorithm = $Parameters.algorithm
	if (($Parameters.name -replace '-GPU.+$' -split '-').Count -gt 2) {
		$Algorithm = "*"
	}

    $Miners_Path = ".\Stats\$($Parameters.name)_$($Algorithm)_HashRate.txt"

	Get-ChildItem $Miners_Path -ErrorAction Ignore | Foreach-Object {
		$count++
		Remove-Item $_ -ErrorAction Ignore
		$text += "$($_.BaseName -replace '-GPU.+$')/$($DeviceModel)/$($_.BaseName -split '_' | Select-Object -Index 1)`n"
	}
}

Write-Output "Removed $($count) stat files:"
Write-Output "<pre>"
$text | Write-Output
Write-Output "</pre>"