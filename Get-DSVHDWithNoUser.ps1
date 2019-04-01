<#
   .SYNOPSIS
    Script for looking up SID for VHDX-files used with ie. RDS-Solution
   .EXAMPLE
    ./Get-DSVHDWithNoUser.ps1
    Will parse the current directory for files with the extension .vhdx and
    use a regular expression to identify the files, and grap the User's SID
    and do a lookup to verify if the user exists, if the user don't exist,
    the file will be passed on.
    Using -Verbose will make a overview in the end, and show the process of
    the function.
   .Notes
    Name:       Get-DSVHDWithNoUser.ps1
    Author:     Tom Stryhn (@dotStryhn)
   .Link
    https://github.com/dotStryhn/Get-DSVHDWithNoUser
    http://dotstryhn.dk
#>

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
