#
# I used powershell to get the member list.  The CSV is attached.  If it didn’t make it through let me know.  The SAExchange user should be able to do the same.
# 
# pwsh  
# > Get-DistributionGroupMember -Identity "UIS Employee - Official Information DL" -ResultSize Unlimited | Select DisplayName, PrimarySmtpAddress | Export-csv "UIS Employee - Official Information DL Members.csv" -NoTypeInformation
#
# -Credential : arg to pass username and password;   ...set wtih  $cred = Get-Credential , and pass $cred to this arg.
#
$WakeUpTypes = DATA {ConvertFrom-StringData -StringData @’
    0 = Reserved          (0)
    1 = Other             (1)
    2 = Unknown           (2)
    3 = APM Timer         (3)
    4 = Modem Ring        (4)
    5 = LAN Remote        (5)
    6 = Power Switch      (6)
    7 = PCI PME#          (7)
    8 = AC Power Restored (8)
   na = ? unreachable ? (N/A)
‘@}

$computers  = ".", "$env:COMPUTERNAME", ### I *know* that these are the same 
              "bububu"                  ### and this is fake name for debugging

$namespace = "ROOT\CIMV2"
$classname = "Win32_ComputerSystem"

ForEach ( $computer in $computers ) {
    Try {
          $WakeUpType = Get-WmiObject `
            -Class $classname -ComputerName $computer -Namespace $namespace `
            -ErrorAction SilentlyContinue
          $WakeUpName = $WakeUpTypes.Item("$($WakeUpType.WakeUpType)")
    } Catch {
          $WakeUpName = $WakeUpTypes.Item("na") 
    }
    If ( $WakeUpName -eq $null ) { $WakeUpName = "Undefined as yet ($WakeUpType)" }
    "{0,-20} {1}" -f $computer, $WakeUpName
}
