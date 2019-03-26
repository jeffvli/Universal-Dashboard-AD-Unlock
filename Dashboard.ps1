$Theme = Get-UDTheme Default
$Credential = Get-Credential
$Server = ''
$Port = 10000
$RefreshInterval = 3
#$AllAccounts = Get-ADUser -Server $Server -Credential $Credential -Filter 'Enabled -eq $true' -Properties LockedOut, AccountExpirationDate
#$AllUsers = $AllAccounts |  Select-Object LockedOut, SamAccountName, Name, AccountExpirationDate
#$Cache:AllUsers = $AllUsers

$ADPage = New-UDPage -Name "AD" -Icon home -Content {
	New-UDRow -Columns {
		New-UDColumn -Size 12 {
			New-UDTable -Title "Locked Users" -Headers @("Name", "DistinguishedName", "Unlock") -AutoRefresh -RefreshInterval $RefreshInterval -Endpoint {
				Search-ADAccount -LockedOut -Server $Server -Credential $Credential | Select-Object SamAccountName, PasswordExpired, @{name="LastLogonDate";expression={($_.LastLogonDate).ToString("MM-dd-yyyy HH:mm:ss")}}, DistinguishedName, AccountExpirationDate |ForEach-Object {
					[PSCustomObject]@{
						Name = $_.SamAccountName
						DistinguishedNAme = $_.DistinguishedName
						Unlock = New-UDButton -Floating -Icon unlock_alt -OnClick {Unlock-ADAccount -Identity $_.SamAccountName -Server $Server -Credential $Credential; Show-UDToast -Message "User unlocked"} 
					} | Out-UDTableData -Property @("Name", "DistinguishedName", "Unlock")
				}
			}

			New-UDButton -Text "Unlock all" -OnClick {
				Search-ADAccount -LockedOut -Server $Server -Credential $Credential | Unlock-ADAccount
				Show-UDToast -Message "All users unlocked"
			}
		}
	}
}

Get-UDDashboard | Stop-UDDashboard
$Dashboard = New-UDDashboard -Title "AD Unlock Dashboard" -Theme $Theme -Pages @($ADPage)
Start-UDDashboard -Port $Port -Dashboard $Dashboard 
