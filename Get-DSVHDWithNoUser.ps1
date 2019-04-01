[CmdletBinding()]
Param()

$Items = Get-ChildItem -Recurse:$false | Where-Object { $_.Extension -eq ".vhdx" }

$TotalCount = 0
$TotalSize = 0
$ValidCount = 0
$ValidSize = 0
$InValidCount = 0
$InValidSize = 0
$Skipped = 0
$SkippedSize = 0

foreach ($Item in $Items) {
    $TotalCount++
    $TotalSize += $Item.Length
    $Matches = $null
    $User = $null
    Write-Verbose "Starting with $($Item.Name)"
    if($Item.Name -match "^VHD-(?<USID>S-1-5-21(-\d{1,10}){1,10}).vhdx$") {
        Write-Verbose "`t### SID: $($Matches.USID)"
        $User = [ADSI]"LDAP://<SID=$($Matches.USID)>"
        if (!$User.DistinguishedName) {
            $InValidCount++
            $InValidSize += $Item.Length
            Write-Verbose "`### No match on SID"
            $Item
        } else {
            $ValidCount++
            $ValidSize += $Item.Length
            Write-Verbose "`t### User: $($User.Name)"
        }
    } else {
        $Skipped++
        $SkippedSize += $Item.Length
        Write-Verbose "`t### Incorrect Naming"
    }
    Write-Verbose "Done with $($Item.Name)`n"
}
Write-Verbose "VHDX Files Parsed: $TotalCount // $([math]::Round($($TotalSize / 1gb),2)) GB"
Write-Verbose "Validated Users: $ValidCount // $([math]::Round($($ValidSize / 1gb),2)) GB"
Write-Verbose "Not Valid Users: $InValidCount // $([math]::Round($($InValidSize / 1gb),2)) GB"
Write-Verbose "Wrong Naming: $Skipped // $([math]::Round($($SkippedSize / 1gb),2)) GB"
