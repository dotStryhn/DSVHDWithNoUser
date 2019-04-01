<#
   .SYNOPSIS
    Script for looking up SID for VHDX-files used with ie. RDS-Solution
   .EXAMPLE
    ./DSVHDWithNoUser.ps1
    Will parse the current directory for files with the extension .vhdx and
    use a regular expression to identify the files, and grap the User's SID
    and do a lookup to verify if the user exists, if the user don't exist,
    the file will be passed on.
    Using -Verbose will make a overview in the end, and show the process of
    the function.
   .Notes
    Name:       DSVHDWithNoUser.ps1
    Author:     Tom Stryhn (@dotStryhn)
   .Link
    https://github.com/dotStryhn/Get-DSVHDWithNoUser
    http://dotstryhn.dk
#>

[CmdletBinding()]
Param()

# Parses the current folder for vhdx files.
$Items = Get-ChildItem -Recurse:$false | Where-Object { $_.Extension -eq ".vhdx" }

# Sets variables to 0
$TotalCount = 0
$TotalSize = 0
$ValidCount = 0
$ValidSize = 0
$InValidCount = 0
$InValidSize = 0
$Skipped = 0
$SkippedSize = 0

# Checks the files found in $Items
foreach ($Item in $Items) {
    # Total count & adds current filesize to totals
    $TotalCount++
    $TotalSize += $Item.Length
    # Clears any earlier Matches & Users
    $Matches = $null
    $User = $null
    Write-Verbose "Starting with $($Item.Name)"
    # Uses a regular expression to match, and graps the SID to a variable for later use
    if($Item.Name -match "^UVHD-(?<USID>S-1-5-21(-\d{1,10}){1,10}).vhdx$") {
        Write-Verbose "`t### SID: $($Matches.USID)"
        # Does a ADSI check, for the SID to see if it exists
        $User = [ADSI]"LDAP://<SID=$($Matches.USID)>"
        if (!$User.DistinguishedName) { # If the user dont exist
            # InValid count & adds current filesize to InValid totals
            $InValidCount++
            $InValidSize += $Item.Length
            Write-Verbose "`### No match on SID"
            # Returns the Object
            $Item
        } else { # If user exists
            # Valid count & adds current filesize to Valid totals
            $ValidCount++
            $ValidSize += $Item.Length
            Write-Verbose "`t### User: $($User.Name)"
        }
    } else { # If not matching the regular expression
        # Skip count & adds current filesize to Skipped totals
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
