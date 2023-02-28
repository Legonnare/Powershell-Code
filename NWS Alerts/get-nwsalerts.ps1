[CmdletBinding()]
param (
  $State = "MN",
  $County = "Hennepin"
)

if($IsMacOS){
  $CSVPath = "/Users/g561109/Library/CloudStorage/OneDrive-GeneralMills/Documents/GitHub/Powershell-Code-1/NWS Alerts/all-geocodes-v2019.csv"
}
elseif($IsWindows){
  $CSVPath = "C:\Users\legon\OneDrive\Documents\GitHub\Powershell-Code\NWS Alerts\all-geocodes-v2019.csv"
}

$ZoneIDs = Import-CSV -Path $CSVPath

$CountyID = $ZoneIDs | Where-Object -Property Name -Like "$($County) County"

$AlertURI = "https://api.weather.gov/alerts/active?zone=$($State)C0$($CountyID.CountyCode)"

$id = ""

do{
  Write-Verbose "++++++++++++++++++++++++  Starting script run at $(get-date)  ++++++++++++++++++++++++"
  $NWSalerts = @()
  $NWSalerts = Invoke-RestMethod -Uri $AlertURI

  If ( ($NWSalerts.features.count -gt 0) -and ("$($NWSalerts.features.id)" -notlike "$($id)") ){
    $AlertArray = @()
    Foreach ($Alert in $NWSalerts.features){
      If ($Alert.properties.areaDesc -like "*$($County)*"){
        $Array = New-Object -TypeName pscustomobject
        $Array | Add-Member -MemberType NoteProperty -Name "Location" -Value $Alert.properties.areaDesc
        $Array | Add-Member -MemberType NoteProperty -Name "Sent" -Value $Alert.properties.Sent
        $Array | Add-Member -MemberType NoteProperty -Name "Effective" -Value $Alert.properties.Effective
        $Array | Add-Member -MemberType NoteProperty -Name "Ends" -Value $Alert.properties.Ends
        $Array | Add-Member -MemberType NoteProperty -Name "Certainty" -Value $Alert.properties.Certainty
        $Array | Add-Member -MemberType NoteProperty -Name "Severity" -Value $Alert.properties.severity
        $Array | Add-Member -MemberType NoteProperty -Name "Headline" -Value $Alert.properties.Headline
        $Array | Add-Member -MemberType NoteProperty -Name "Description" -Value $Alert.properties.Description
        $Array | Add-Member -MemberType NoteProperty -Name "Instructions" -Value $Alert.properties.Instruction
        $Array | Add-Member -MemberType NoteProperty -Name "Reported By" -Value $Alert.properties.senderName
      }
      $AlertArray += $Array
    }
    $id = $NWSalerts.features.id
    $Message = $AlertArray | Out-String
    if ($IsWindows){
      Add-Type -AssemblyName PresentationFramework
      [System.Windows.MessageBox]::Show("$Message `n `n Acknowledge?",'+++++  NWS ALERT +++++','OK','Warning')
    }
    elseif($IsMacOS){
      $appleScript = "display alert `"+++++  NWS ALERT +++++`" message `"$Message`""
      $appleScript | osascript
    }

  }
  Start-Sleep -Seconds 5
} Until ($NWSalerts.count -eq 0)
