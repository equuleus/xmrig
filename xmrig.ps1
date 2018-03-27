PARAM (
	[string]$address,
#	[string]$address = $(Read-Host "Input address, please: "),
	[string]$port,
	[string]$token,
	[string]$process,
	[string]$refresh
)
Set-ExecutionPolicy Unrestricted -Scope CurrentUser -Force

Function API_Get ($address, $port, $token) {
	$URI		= "http://" + $address + ":" + $port
	$Method		= "GET"
	$Headers	= @{
		"Content-type" = "Application/json"
#		"Authorization" = ("Bearer " + $token)
	}
	If ($token -ne "") {
		$Headers["Authorization"] = ("Bearer " + $token)
	}
	$ContentType	= "Application/json"
#	$Body		= ConvertTo-Json @{
#		"url" = $address
#	}
	Try {
#		$WebRequest = Invoke-WebRequest -Uri $URI -Method $Method -Headers $Headers -ContentType $ContentType -Body $Body -TimeoutSec 10
		$WebRequest = Invoke-WebRequest -Uri $URI -Method $Method -Headers $Headers -ContentType $ContentType -TimeoutSec 3
	} Catch {
		$StatusCode = $_.Exception.Response
	} Finally {
		If ($WebRequest -ne $null) {
			$Content = $WebRequest.Content | ConvertFrom-JSON
		} Else {
			$Content = $null
		}
	}
	Return $Content
}

Function GetType ($Content) {
	If ($Content -ne $null) {
		If ($Content.kind -eq "cpu") {
			$Type = "CPU"
		} ElseIf ($Content.kind -eq "nvidia") {
			$Type = "NVIDIA"
		} ElseIf ($Content.kind -eq "amd") {
			$Type = "AMD"
		} Else {
			$Type = "UNKNOWN"
		}
	} Else {
		$Type = "UNKNOWN"
	}
	Return $Type
}

Function FormDimensions ($Content) {

	$FormDimensions = @{}

	$FormDimensions["objFormHorizontalBorder"] = 20
	$FormDimensions["objFormVerticalBorder"] = 20

	$FormDimensions["objTabControlHorizontalPosition"] = 0
	$FormDimensions["objTabControlVerticalPosition"] = 0
	$FormDimensions["objTabControlHorizontalBorder"] = 10
	$FormDimensions["objTabControlVerticalBorder"] = 10
	$FormDimensions["objTabControlMenuHeight"] = 20

	$FormDimensions["objTabPageMonitorHorizontalPosition"] = 0
	$FormDimensions["objTabPageMonitorVerticalPosition"] = 0

	$FormDimensions["objTabPageMonitorInformationWidth"] = 625
	$FormDimensions["objTabPageMonitorInformationHeight"] = 125

	$FormDimensions["objTabPageMonitorCPUWidth"] = 625
	$FormDimensions["objTabPageMonitorCPUHeight"] = 50

	$FormDimensions["objTabPageMonitorNVIDIAWidth"] = 625
	$FormDimensions["objTabPageMonitorNVIDIAHeight"] = 110

	$FormDimensions["objTabPageMonitorConnectionWidth"] = 625
	$FormDimensions["objTabPageMonitorConnectionHeight"] = 50
	$FormDimensions["objTabPageMonitorConnectionErrorLogHeight"] = 100

	$FormDimensions["objTabPageMonitorHashrateWidth"] = 625
	$FormDimensions["objTabPageMonitorHashrateHeight"] = 130

	$FormDimensions["objTabPageMonitorResultsWidth"] = 625
	$FormDimensions["objTabPageMonitorResultsHeight"] = 110
	$FormDimensions["objTabPageMonitorResultsErrorLogHeight"] = 100

	$FormDimensions["objTabPageOptionsHorizontalPosition"] = 0
	$FormDimensions["objTabPageOptionsVerticalPosition"] = 0

	$FormDimensions["objTabPageSettingsHorizontalPosition"] = 0
	$FormDimensions["objTabPageSettingsVerticalPosition"] = 0

	$FormDimensions["objTabPageSettingsUpdateWidth"] = 625
	$FormDimensions["objTabPageSettingsUpdateHeight"] = 50

	$FormDimensions["objTabPageSettingsManualConnectionWidth"] = 625
	$FormDimensions["objTabPageSettingsManualConnectionHeight"] = 75

	$FormDimensions["objTabPageMonitorInformationHorizontalPosition"] = $FormDimensions["objTabPageMonitorHorizontalPosition"]
	$FormDimensions["objTabPageMonitorInformationVerticalPosition"] = $FormDimensions["objTabPageMonitorVerticalPosition"]

	$FormDimensions["objTabPageMonitorCPUHorizontalPosition"] = $FormDimensions["objTabPageMonitorHorizontalPosition"]
	$FormDimensions["objTabPageMonitorCPUVerticalPosition"] = $FormDimensions["objTabPageMonitorInformationVerticalPosition"] + $FormDimensions["objTabPageMonitorInformationHeight"]

	$FormDimensions["objTabPageMonitorNVIDIAHorizontalPosition"] = $FormDimensions["objTabPageMonitorHorizontalPosition"]
	$FormDimensions["objTabPageMonitorNVIDIAVerticalPosition"] = $FormDimensions["objTabPageMonitorCPUVerticalPosition"] + $FormDimensions["objTabPageMonitorCPUHeight"]
	If ((GetType $Content) -eq "NVIDIA") {
		$Script:FormFieldNVIDIAVisible = $True
		If ($Content.health.Count -eq 1) {
			$FormDimensions["objTabPageMonitorNVIDIAHeight"] = 60
		}
	} Else {
		$Script:FormFieldNVIDIAVisible = $False
		$FormDimensions["objTabPageMonitorNVIDIAHeight"] = 0
	}

	$FormDimensions["objTabPageMonitorConnectionHorizontalPosition"] = $FormDimensions["objTabPageMonitorHorizontalPosition"]
	$FormDimensions["objTabPageMonitorConnectionVerticalPosition"] = $FormDimensions["objTabPageMonitorNVIDIAVerticalPosition"] + $FormDimensions["objTabPageMonitorNVIDIAHeight"]
	If ($Content.connection.error_log.Count -gt 0) {
		$Script:FormFieldConnectionErrorLogVisible = $True
		$FormDimensions["objTabPageMonitorConnectionHeight"] = $FormDimensions["objTabPageMonitorConnectionHeight"] + $FormDimensions["objTabPageMonitorConnectionErrorLogHeight"]
	} Else {
		$Script:FormFieldConnectionErrorLogVisible = $False
	}

	$FormDimensions["objTabPageMonitorHashrateHorizontalPosition"] = $FormDimensions["objTabPageMonitorHorizontalPosition"]
	$FormDimensions["objTabPageMonitorHashrateVerticalPosition"] = $FormDimensions["objTabPageMonitorConnectionVerticalPosition"] + $FormDimensions["objTabPageMonitorConnectionHeight"]

	$FormDimensions["objTabPageMonitorResultsHorizontalPosition"] = $FormDimensions["objTabPageMonitorHorizontalPosition"]
	$FormDimensions["objTabPageMonitorResultsVerticalPosition"] = $FormDimensions["objTabPageMonitorHashrateVerticalPosition"] + $FormDimensions["objTabPageMonitorHashrateHeight"]
	If ($Content.results.error_log.Count -gt 0) {
		$Script:FormFieldResultsErrorLogVisible = $True
		$FormDimensions["objTabPageMonitorResultsHeight"] = $FormDimensions["objTabPageMonitorResultsHeight"] + $FormDimensions["objTabPageMonitorResultsErrorLogHeight"]
	} Else {
		$Script:FormFieldResultsErrorLogVisible = $False
	}

	$FormDimensions["objTabPageMonitorWidth"] = $FormDimensions["objTabPageMonitorResultsHorizontalPosition"] + $FormDimensions["objTabPageMonitorResultsWidth"]
	$FormDimensions["objTabPageMonitorHeight"] = $FormDimensions["objTabPageMonitorResultsVerticalPosition"] + $FormDimensions["objTabPageMonitorResultsHeight"]

	$FormDimensions["objTabPageOptionsWidth"] = $FormDimensions["objTabPageMonitorWidth"]
	$FormDimensions["objTabPageOptionsHeight"] = $FormDimensions["objTabPageMonitorHeight"]

	$FormDimensions["objTabPageSettingsWidth"] = $FormDimensions["objTabPageMonitorWidth"]
	$FormDimensions["objTabPageSettingsHeight"] = $FormDimensions["objTabPageMonitorHeight"]

	$FormDimensions["objTabPageSettingsUpdateHorizontalPosition"] = $FormDimensions["objTabPageSettingsHorizontalPosition"]
	$FormDimensions["objTabPageSettingsUpdateVerticalPosition"] = $FormDimensions["objTabPageSettingsVerticalPosition"]

	$FormDimensions["objTabPageSettingsManualConnectionHorizontalPosition"] = $FormDimensions["objTabPageSettingsHorizontalPosition"]
	$FormDimensions["objTabPageSettingsManualConnectionVerticalPosition"] = $FormDimensions["objTabPageSettingsUpdateVerticalPosition"] + $FormDimensions["objTabPageSettingsUpdateHeight"]

	$FormDimensions["objTabControlWidth"] = $FormDimensions["objTabPageMonitorWidth"] + $FormDimensions["objTabControlHorizontalBorder"]
	$FormDimensions["objTabControlHeight"] = $FormDimensions["objTabPageMonitorHeight"] + $FormDimensions["objTabControlVerticalBorder"] + $FormDimensions["objTabControlMenuHeight"]

	$FormDimensions["FormSizeWidth"] = $FormDimensions["objTabControlWidth"] + $FormDimensions["objFormHorizontalBorder"]
	$FormDimensions["FormSizeHeight"] = $FormDimensions["objTabControlHeight"] + $FormDimensions["objFormVerticalBorder"] + $FormDimensions["objTabControlMenuHeight"] + 3

	Return $FormDimensions
}

Function RefreshInterval ($hours, $minutes, $seconds) {
	$objTabPageSettingsGroupBoxUpdateComboBoxHours.SelectedIndex = $objTabPageSettingsGroupBoxUpdateComboBoxHours.Items.IndexOf($hours)
	$objTabPageSettingsGroupBoxUpdateComboBoxMinutes.SelectedIndex = $objTabPageSettingsGroupBoxUpdateComboBoxMinutes.Items.IndexOf($minutes)
	$objTabPageSettingsGroupBoxUpdateComboBoxSeconds.SelectedIndex = $objTabPageSettingsGroupBoxUpdateComboBoxSeconds.Items.IndexOf($seconds)
	$Script:RefreshInterval = ([timespan]($hours.ToString() + ":" + $minutes.ToString() + ":" + $seconds.ToString())).TotalSeconds
}

Function TabControl ($objTabControl, $objTabPages, $Status) {
	If ($Status -eq $True) {
		$objTabControl.SuspendLayout()
		$objTabControl.TabPages.Clear()
		$i = 0
		ForEach ($objTabPage in $objTabPages) {
#			$objTabControl.TabPages.Add($objTabPage)
			$objTabControl.TabPages.Insert($i, $objTabPage)
			$i = $i + 1
		}
		$objTabControl.ResumeLayout()
	}
	If ($Status -eq $False) {
		$objTabControl.SuspendLayout()
		ForEach ($objTabPage in $objTabPages) {
			$objTabControl.TabPages.Remove($objTabPage)
		}
		$objTabControl.ResumeLayout()
	}
}

Function SortListView ($ListView, $Column) {
# Determine how to sort
        $Numeric = $true
# If the user clicked the same column that was clicked last time, reverse its sort order. otherwise, reset for normal ascending sort
	If ($Script:LastColumnClicked -eq $Column) {
		$Script:LastColumnAscending = -not $Script:LastColumnAscending
	} Else {
		$Script:LastColumnAscending = $true
	}
	$Script:LastColumnClicked = $Column
# Three-dimensional array; column 1 indexes the other columns, column 2 is the value to be sorted on, and column 3 is the System.Windows.Forms.ListViewItem object
	$ListItems = @(@(@()))
	Foreach ($ListItem in $ListView.Items) {
# If all items are numeric, can use a numeric sort
		If ($Numeric -ne $false) {
# Nothing can set this back to true, so don't process unnecessarily
			Try {
				$Test = [Double]$ListItem.SubItems[[int]$Column].Text
			} Catch {
# A non-numeric item was found, so sort will occur as a string
				$Numeric = $false
			}
		}
		$ListItems += ,@($ListItem.SubItems[[int]$Column].Text,$ListItem)
	}
# Create the expression that will be evaluated for sorting
	$EvalExpression = {
		If ($Numeric) {
			return [Double]$_[0]
		} Else {
			return [String]$_[0]
		}
	}
# All information is gathered; perform the sort
	$ListItems = $ListItems | Sort-Object -Property @{Expression=$EvalExpression; Ascending=$Script:LastColumnAscending}
# The list is sorted; display it in the listview
	$ListView.BeginUpdate()
	$ListView.Items.Clear()
	Foreach ($ListItem in $ListItems) {
		$ListView.Items.Add($ListItem[1])
	}
	$ListView.EndUpdate()
}

Function Show_Dialog ($address, $port, $token, $process, $refresh) {

	$Script:AddressDefault = $address
	$Script:PortDefault = $port
	$Script:TokenDefault = $token
	$Script:ProcessDefault = $process

	$Script:AddressCurrent = $Script:AddressDefault
	$Script:PortCurrent = $Script:PortDefault
	$Script:TokenCurrent = $Script:TokenDefault
	$Script:ProcessCurrent = $Script:ProcessDefault

	[int]$RefreshIntervalDefault = 3
	If ([int]$refresh -le 0) {
		$Script:RefreshInterval = $RefreshIntervalDefault
	} Else {
		$Script:RefreshInterval = [int]$refresh
	}

	$Content = API_Get $address $port $token

	$FormDimensions = FormDimensions ($Content)

#	[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null
	Add-Type -AssemblyName System.Windows.Forms

#	$objArray = New-Object -TypeName PSCustomObject

	$objTimer = New-Object System.Windows.Forms.Timer
	$objTimer.Interval = 1000
	$objTimer.Add_Tick({

		If ($Script:RefreshTimeStart) {
			$RefreshTimeFinish = ($Script:RefreshTimeStart + (new-timespan -seconds $Script:RefreshInterval))
			$RefreshTimeLeft = ((New-TimeSpan -Start (get-date) -End $RefreshTimeFinish).TotalSeconds).ToString("#.")
			If (($RefreshTimeLeft -lt 1) -or ([math]::Sign($RefreshTimeLeft) -eq -1)) {
				$RefreshReload = $True
				$RefreshTimeLeft = 0
			} Else {
				If ($Script:TryToReconnect -eq $True) {
					$RefreshReload = $True
				} Else {
					$RefreshReload = $False
				}
			}
		} Else {
			$RefreshReload = $True
			$RefreshTimeLeft = 0
		}
		$objTabPageSettingsGroupBoxUpdateTextBoxTimeLeft.text = $RefreshTimeLeft
		$ToolTip.SetToolTip($objTabPageSettingsGroupBoxUpdateTextBoxTimeLeft, "Time until next refresh: " + ("{0:HH:mm:ss}" -f ([datetime]([timespan]::FromSeconds($RefreshTimeLeft)).Ticks)))

		If ($RefreshReload -eq $True) {
			$Script:RefreshTimeStart = (get-date)

			If (($Script:AddressCurrent -eq "127.0.0.1") -and ($Script:ProcessCurrent -ne "")) {
				If (((Get-Process -name $Script:ProcessCurrent -ErrorAction SilentlyContinue).Responding) -eq $True) {
					$ProcessLoadedCurrentStatus = $True
				} Else {
					$ProcessLoadedCurrentStatus = $False
				}
				If ($Script:ProcessLoadedLastStatus -ne $null) {
					If ($ProcessLoadedCurrentStatus -ne $Script:ProcessLoadedLastStatus) {
						$Script:ProcessLoadedLastStatus = $ProcessLoadedCurrentStatus
						If ($ProcessLoadedCurrentStatus -eq $True) {
							[System.Windows.Forms.MessageBox]::Show("INFO: Process `"" + $Script:ProcessCurrent + "`" was loaded", "XMRig API Monitor", 0, [System.Windows.Forms.MessageBoxIcon]::Information) | out-null
						} Else {
							If ($Script:ProcessCurrent -eq $Script:ProcessDefault) {
								TabControl $objTabControl @($objTabPageMonitor, $objTabPageOptions) $False
								[System.Windows.Forms.MessageBox]::Show("ERROR: Process `"" + $Script:ProcessCurrent + "`" was unloaded", "XMRig API Monitor", 0, [System.Windows.Forms.MessageBoxIcon]::Warning) | out-null
							}
						}
					}
				} Else {
					$Script:ProcessLoadedLastStatus = $ProcessLoadedCurrentStatus
					If ($ProcessLoadedCurrentStatus -ne $True) {
						TabControl $objTabControl @($objTabPageMonitor, $objTabPageOptions) $False
						[System.Windows.Forms.MessageBox]::Show("ERROR: Process `"" + $Script:ProcessCurrent + "`" is not loaded", "XMRig API Monitor", 0, [System.Windows.Forms.MessageBoxIcon]::Error) | out-null
					}
				}
			}

			If (
				(($ProcessLoadedCurrentStatus -ne $False) -and (($Script:AddressCurrent -eq $Script:AddressDefault) -and ($Script:PortCurrent -eq $Script:PortDefault) -and ($Script:TokenCurrent -eq $Script:TokenDefault))) -or
				(($Script:AddressCurrent -ne $Script:AddressDefault) -or ($Script:PortCurrent -ne $Script:PortDefault) -or ($Script:TokenCurrent -ne $Script:TokenDefault))
			) {
				$Content = API_Get $Script:AddressCurrent $Script:PortCurrent $Script:TokenCurrent
				If (($Content -ne $null) -and ($Content -ne "")) {

					If ($Script:TryToReconnect -eq $True) {
						$FormDimensions = FormDimensions ($Content)

						$objTabPageSettingsGroupBoxInformation.Location = New-Object System.Drawing.Point($FormDimensions["objTabPageMonitorInformationHorizontalPosition"],$FormDimensions["objTabPageMonitorInformationVerticalPosition"])
						$objTabPageSettingsGroupBoxCPU.Location = New-Object System.Drawing.Point($FormDimensions["objTabPageMonitorCPUHorizontalPosition"],$FormDimensions["objTabPageMonitorCPUVerticalPosition"])
						If ((GetType $Content) -eq "NVIDIA") {
							$objTabPageSettingsGroupBoxNVIDIA.Location = New-Object System.Drawing.Point($FormDimensions["objTabPageMonitorNVIDIAHorizontalPosition"],$FormDimensions["objTabPageMonitorNVIDIAVerticalPosition"])
							$objTabPageSettingsGroupBoxNVIDIA.Size = New-Object System.Drawing.Size($FormDimensions["objTabPageMonitorNVIDIAWidth"],$FormDimensions["objTabPageMonitorNVIDIAHeight"])
							$objTabPageSettingsGroupBoxNVIDIAListView.Size = New-Object System.Drawing.Size(620,($FormDimensions["objTabPageMonitorNVIDIAHeight"] - 15))
						}
						$objTabPageSettingsGroupBoxConnection.Location = New-Object System.Drawing.Point($FormDimensions["objTabPageMonitorConnectionHorizontalPosition"],$FormDimensions["objTabPageMonitorConnectionVerticalPosition"])
						$objTabPageSettingsGroupBoxHashrate.Location = New-Object System.Drawing.Point($FormDimensions["objTabPageMonitorHashrateHorizontalPosition"],$FormDimensions["objTabPageMonitorHashrateVerticalPosition"])
						$objTabPageSettingsGroupBoxResults.Location = New-Object System.Drawing.Point($FormDimensions["objTabPageMonitorResultsHorizontalPosition"],$FormDimensions["objTabPageMonitorResultsVerticalPosition"])
						$objTabPageMonitor.Size = New-Object System.Drawing.Size($FormDimensions["objTabPageMonitorWidth"],$FormDimensions["objTabPageMonitorHeight"])

						$objTabPageOptions.Size = New-Object System.Drawing.Size($FormDimensions["objTabPageOptionsWidth"],$FormDimensions["objTabPageOptionsHeight"])

						$objTabPageSettingsGroupBoxUpdate.Location = New-Object System.Drawing.Point($FormDimensions["objTabPageSettingsUpdateHorizontalPosition"],$FormDimensions["objTabPageSettingsUpdateVerticalPosition"])
						$objTabPageSettingsGroupBoxManualConnection.Location = New-Object System.Drawing.Point($FormDimensions["objTabPageSettingsManualConnectionHorizontalPosition"],$FormDimensions["objTabPageSettingsManualConnectionVerticalPosition"])
						$objTabPageSettings.Size = New-Object System.Drawing.Size($FormDimensions["objTabPageSettingsWidth"],$FormDimensions["objTabPageSettingsHeight"])

						$objTabControl.Size = New-Object System.Drawing.Size($FormDimensions["objTabControlWidth"],$FormDimensions["objTabControlHeight"])
						$objForm.Size = New-Object System.Drawing.Size($FormDimensions["FormSizeWidth"],$FormDimensions["FormSizeHeight"])
					}

					If (($objTabControl.TabPages.Contains($objTabPageMonitor) -ne $True) -or ($objTabControl.TabPages.Contains($objTabPageOptions) -ne $True) -or ($objTabControl.TabPages.Contains($objTabPageSettings) -ne $True)) {
						TabControl $objTabControl @($objTabPageMonitor, $objTabPageOptions, $objTabPageSettings) $True
						RefreshInterval ("{0:HH}" -f ([datetime]([timespan]::FromSeconds($Script:RefreshInterval)).Ticks)) ("{0:mm}" -f ([datetime]([timespan]::FromSeconds($Script:RefreshInterval)).Ticks)) ("{0:ss}" -f ([datetime]([timespan]::FromSeconds($Script:RefreshInterval)).Ticks))
					}

					If ($Content.ua) {
						$objTabPageSettingsGroupBoxInformationLabelUA.Text = $Content.ua
					}

					If ($Content.worker_id) {
						$objTabPageSettingsGroupBoxInformationTextBoxWorkerID.Text = $Content.worker_id
					}
					If ($Content.id) {
						$objTabPageSettingsGroupBoxInformationTextBoxID.Text = $Content.id
					}

					If ($Content.version) {
						$objTabPageSettingsGroupBoxInformationTextBoxVersion.Text = $Content.version
					}
					If ($Content.donate_level) {
						$objTabPageSettingsGroupBoxInformationTextBoxDonateLevel.Text = $Content.donate_level
					}

					If ($Content.kind) {
						$objTabPageSettingsGroupBoxInformationTextBoxKind.Text = $Content.kind
					}
					If ($Content.hugepages -eq "true") {
						$objTabPageSettingsGroupBoxInformationCheckBoxHugepages.Checked = $True
						$objTabPageSettingsGroupBoxInformationCheckBoxHugepages.Text = "Available"
					} Else {
						$objTabPageSettingsGroupBoxInformationCheckBoxHugepages.Checked = $False
						$objTabPageSettingsGroupBoxInformationCheckBoxHugepages.Text = "Not available"
					}
					If ($Content.algo) {
						$objTabPageSettingsGroupBoxInformationTextBoxAlgo.Text = $Content.algo
					}

					If ($Content.cpu.brand) {
						$objTabPageSettingsGroupBoxCPUTextBoxBrand.Text = $Content.cpu.brand
					}
					If ($Content.cpu.aes -eq "true") {
						$objTabPageSettingsGroupBoxCPUCheckBoxAES.Checked = $True
					} Else {
						$objTabPageSettingsGroupBoxCPUCheckBoxAES.Checked = $False
					}
					If ($Content.cpu.x64 -eq "true") {
						$objTabPageSettingsGroupBoxCPUCheckBoxX64.Checked = $True
					} Else {
						$objTabPageSettingsGroupBoxCPUCheckBoxX64.Checked = $False
					}
					If ($Content.cpu.sockets) {
						$objTabPageSettingsGroupBoxCPUTextBoxSockets.Text = $Content.cpu.sockets
					}

					$objTabPageSettingsGroupBoxNVIDIAListView.Items.Clear()
					If ($Content.kind -eq "nvidia") {
						$Script:FormFieldNVIDIAVisible = $True
						$i = 0
						ForEach ($nvidia in $Content.health) {
							$i = $i + 1
							$ListViewItem = New-Object System.Windows.Forms.ListViewItem($i)
							$ListViewItem.Subitems.Add($nvidia.name.ToString()) | Out-Null
							$ListViewItem.Subitems.Add($nvidia.clock.ToString()) | Out-Null
							$ListViewItem.Subitems.Add($nvidia.mem_clock.ToString()) | Out-Null
							$ListViewItem.Subitems.Add($nvidia.power.ToString()) | Out-Null
							$ListViewItem.Subitems.Add($nvidia.temp.ToString()) | Out-Null
							$ListViewItem.Subitems.Add($nvidia.fan.ToString()) | Out-Null
							$objTabPageSettingsGroupBoxNVIDIAListView.Items.Add($ListViewItem) | Out-Null
							Remove-Variable -Name ListViewItem | Out-Null
						}
					} Else {
						$Script:FormFieldNVIDIAVisible = $False
					}
					$objTabPageSettingsGroupBoxNVIDIA.Visible = $Script:FormFieldNVIDIAVisible

					If ($Content.connection.pool) {
						$objTabPageSettingsGroupBoxConnectionTextBoxPool.Text = $Content.connection.pool
					}
					If ($Content.connection.ping) {
						$objTabPageSettingsGroupBoxConnectionTextBoxPing.Text = $Content.connection.ping
					}
					If ($Content.connection.uptime) {
						$objTabPageSettingsGroupBoxConnectionTextBoxUptime.Text = $Content.connection.uptime
						$ToolTip.SetToolTip($objTabPageSettingsGroupBoxConnectionTextBoxUptime, ("{0:dd,HH:mm:ss}" -f ([datetime]([timespan]::FromSeconds($Content.connection.uptime)).Ticks)))
					}
					If ($Content.connection.failures) {
						$objTabPageSettingsGroupBoxConnectionTextBoxFailures.Text = $Content.connection.failures
					}
					$objTabPageSettingsGroupBoxConnectionListBoxErrorLog.Items.Clear()
					If ($Content.connection.error_log.Count -gt 0) {
						If ($objTabPageSettingsGroupBoxConnectionErrorLog.Visible -eq $False) {
							$objTabPageMonitor.Size = $objTabPageMonitor.Size.Width.ToString() + ", " + ($objTabPageMonitor.Size.Height + $FormDimensions["objTabPageMonitorConnectionErrorLogHeight"]).ToString()
							$objTabPageSettingsGroupBoxConnection.Size = $FormDimensions["objTabPageMonitorConnectionWidth"].ToString() + ", " + ($FormDimensions["objTabPageMonitorConnectionHeight"] + $FormDimensions["objTabPageMonitorConnectionErrorLogHeight"]).ToString()
							$objTabPageSettingsGroupBoxHashrate.Location = $FormDimensions["objTabPageMonitorHashrateHorizontalPosition"].ToString() + ", " + ($FormDimensions["objTabPageMonitorHashrateVerticalPosition"] + $FormDimensions["objTabPageMonitorConnectionErrorLogHeight"]).ToString()
							$objTabPageSettingsGroupBoxResults.Location = $FormDimensions["objTabPageMonitorResultsHorizontalPosition"].ToString() + ", " + ($FormDimensions["objTabPageMonitorResultsVerticalPosition"] + $FormDimensions["objTabPageMonitorConnectionErrorLogHeight"]).ToString()
							$objTabPageSettingsGroupBoxConnectionErrorLog.Visible = $True
						}
						ForEach ($error_log in $Content.connection.error_log) {
							$objTabPageSettingsGroupBoxConnectionListBoxErrorLog.Items.Add($error_log) | Out-Null
						}
					}

					If ($Content.hashrate.total) {
						$objTabPageSettingsGroupBoxHashrateTextBoxTotal1.Text = $Content.hashrate.total[0]
						$ToolTip.SetToolTip($objTabPageSettingsGroupBoxHashrateTextBoxTotal1, ($Content.hashrate.total[0].ToString() + " hashes per second in a last 2,5 seconds"))
						$objTabPageSettingsGroupBoxHashrateTextBoxTotal2.Text = $Content.hashrate.total[1]
						$ToolTip.SetToolTip($objTabPageSettingsGroupBoxHashrateTextBoxTotal2, ($Content.hashrate.total[1].ToString() + " hashes per second in a last 60 seconds"))
						$objTabPageSettingsGroupBoxHashrateTextBoxTotal3.Text = $Content.hashrate.total[2]
						$ToolTip.SetToolTip($objTabPageSettingsGroupBoxHashrateTextBoxTotal3, ($Content.hashrate.total[2].ToString() + " hashes per second in a last 15 minutes"))
					}
					If ($Content.hashrate.highest) {
						$objTabPageSettingsGroupBoxHashrateTextBoxHighest.Text = $Content.hashrate.highest
						$ToolTip.SetToolTip($objTabPageSettingsGroupBoxHashrateTextBoxHighest, ($Content.hashrate.highest.ToString() + " hashes per second is a highest value since start"))
					}
					$objTabPageSettingsGroupBoxHashrateListViewThreads.Items.Clear()
					$i = 0
					ForEach ($thread in $Content.hashrate.threads) {
						$i = $i + 1
						$ListViewItem = New-Object System.Windows.Forms.ListViewItem($i)
						$ListViewItem.Subitems.Add($thread[0].ToString()) | Out-Null
						$ListViewItem.Subitems.Add($thread[1].ToString()) | Out-Null
						$ListViewItem.Subitems.Add($thread[2].ToString()) | Out-Null
						$objTabPageSettingsGroupBoxHashrateListViewThreads.Items.Add($ListViewItem) | Out-Null
					}

					If ($Content.results.hashes_total) {
						$objTabPageSettingsGroupBoxResultsTextBoxHashes.Text = $Content.results.hashes_total
						$ToolTip.SetToolTip($objTabPageSettingsGroupBoxResultsTextBoxHashes, ($Content.results.hashes_total.ToString() + " total hashes found"))
					}
					If ($Content.results.shares_total) {
						$objTabPageSettingsGroupBoxResultsTextBoxSharesTotal.Text = $Content.results.shares_total
						$ToolTip.SetToolTip($objTabPageSettingsGroupBoxResultsTextBoxSharesTotal, ($Content.results.shares_total.ToString() + " total shares found"))
					}
					If ($Content.results.shares_good) {
						$objTabPageSettingsGroupBoxResultsTextBoxSharesGood.Text = $Content.results.shares_good
						$ToolTip.SetToolTip($objTabPageSettingsGroupBoxResultsTextBoxSharesGood, ($Content.results.shares_good.ToString() + " good shares found"))
					}
					If ($Content.results.avg_time) {
						$objTabPageSettingsGroupBoxResultsTextBoxTime.Text = $Content.results.avg_time
						$ToolTip.SetToolTip($objTabPageSettingsGroupBoxResultsTextBoxTime, ($Content.results.avg_time.ToString() + " seconds (" + ("{0:HH:mm:ss}" -f ([datetime]([timespan]::FromSeconds($Content.results.avg_time)).Ticks)) + ") - average time to find a share"))
					}
					If ($Content.results.diff_current) {
						$objTabPageSettingsGroupBoxResultsTextBoxDifficulty.Text = $Content.results.diff_current
						$ToolTip.SetToolTip($objTabPageSettingsGroupBoxResultsTextBoxDifficulty, ($Content.results.diff_current.ToString() + " current difficulty for worker"))
					}
					$objTabPageSettingsGroupBoxResultsListViewTop10Shares.Items.Clear()
					If ($Content.results.best) {
						$ListViewItem = New-Object System.Windows.Forms.ListViewItem(0)
						ForEach ($result in $Content.results.best) {
							$ListViewItem.Subitems.Add($result.ToString()) | Out-Null
						}
						$objTabPageSettingsGroupBoxResultsListViewTop10Shares.Items.Add($ListViewItem) | Out-Null
					}

					$objTabPageSettingsGroupBoxResultsListBoxErrorLog.Items.Clear()
					If ($Content.results.error_log.Count -gt 0) {
						If ($objTabPageSettingsGroupBoxResultsErrorLog.Visible -eq $False) {
							$objTabPageMonitor.Size = $objTabPageMonitor.Size.Width.ToString() + ", " + ($objTabPageMonitor.Size.Height + $FormDimensions["objTabPageMonitorResultsErrorLogHeight"]).ToString()
							$objTabPageSettingsGroupBoxResults.Size = $FormDimensions["objTabPageMonitorResultsWidth"].ToString() + ", " + ($FormDimensions["objTabPageMonitorResultsHeight"] + $FormDimensions["objTabPageMonitorResultsErrorLogHeight"]).ToString()
							$objTabPageSettingsGroupBoxResultsErrorLog.Visible = $True
						}
						ForEach ($error_log in $Content.results.error_log) {
							$objTabPageSettingsGroupBoxResultsListBoxErrorLog.Items.Add($error_log) | Out-Null
						}
					}

					If (($Script:AddressCurrent -ne $Script:AddressLastChange) -or ($Script:PortCurrent -ne $Script:PortLastChange)) {
						$Script:AddressLastChange = $Script:AddressCurrent
						$Script:PortLastChange = $Script:PortCurrent
						$Script:ConnectionLastAttemptStatus = ""
					}
					If ($Script:ConnectionLastAttemptStatus -ne $True) {
						$Script:ConnectionLastAttemptStatus = $True
						$objTabControl.SelectedIndex = 0
						If (($ProcessLoadedCurrentStatus -ne $True) -or (($Script:AddressCurrent -ne $Script:AddressDefault) -or ($Script:PortCurrent -ne $Script:PortDefault))) {
							[System.Windows.Forms.MessageBox]::Show("INFO: Connection is successful`r`n`r`n`tIP: $Script:AddressCurrent`r`n`r`n`tPORT: $Script:PortCurrent", "XMRig API Monitor", 0, [System.Windows.Forms.MessageBoxIcon]::Information) | out-null
						}
					}

					$objTabPageMonitor.Refresh()
				} Else {
					If ($Script:TryToReconnect -eq $True) {
						TabControl $objTabControl @($objTabPageMonitor, $objTabPageOptions) $False
						$Script:TryToReconnect = $False
						If (($Script:AddressCurrent -ne "") -and ($Script:PortCurrent -ne "")) {
							$Script:AddressLastChange = $Script:AddressCurrent
							$Script:PortLastChange = $Script:PortCurrent
							[System.Windows.Forms.MessageBox]::Show("ERROR: Can not get content from`r`n`r`n`tIP: $Script:AddressCurrent`r`n`r`n`tPORT: $Script:PortCurrent", "XMRig API Monitor", 0, [System.Windows.Forms.MessageBoxIcon]::Warning) | out-null
						}
					}
					$Script:ConnectionLastAttemptStatus = $False
				}
			} Else {
				If ($Script:TryToReconnect -eq $True) {
					TabControl $objTabControl @($objTabPageMonitor, $objTabPageOptions) $False
					$Script:TryToReconnect = $False
					[System.Windows.Forms.MessageBox]::Show("ERROR: Process `"" + $Script:ProcessCurrent + "`" is not loaded", "XMRig API Monitor", 0, [System.Windows.Forms.MessageBoxIcon]::Error) | out-null
				}
				$Script:ConnectionLastAttemptStatus = $False
			}
		}
		If ($Script:TryToReconnect -eq $True) {
			$Script:TryToReconnect = $False
		}
	})

	$ToolTip = New-Object System.Windows.Forms.ToolTip
	$ToolTip.BackColor = [System.Drawing.Color]::LightGoldenrodYellow
	$ToolTip.IsBalloon = $true
#	$ToolTip.InitialDelay = 500
#	$ToolTip.ReshowDelay = 500

	$objForm = New-Object System.Windows.Forms.Form
	$objForm.Icon = [system.drawing.icon]::ExtractAssociatedIcon($PSHOME + "\powershell.exe")
	$objForm.Text = "XMRig API Monitor"
	$objForm.StartPosition = "CenterScreen"
# CenterScreen, Manual, WindowsDefaultLocation, WindowsDefaultBounds, CenterParent
#	$objForm.AutoSize = $True
	$objForm.Size = New-Object System.Drawing.Size($FormDimensions["FormSizeWidth"],$FormDimensions["FormSizeHeight"])
	$objForm.FormBorderStyle = "Fixed3D"
	$objForm.AutoScroll = $True
	$objForm.MinimizeBox = $True
	$objForm.MaximizeBox = $False
	$objForm.WindowState = "Normal"
# Maximized, Minimized, Normal
	$objForm.SizeGripStyle = "Hide"
# Auto, Hide, Show
	$objForm.Opacity = 1.0
# 1.0 is fully opaque; 0.0 is invisible

#$Image = [system.drawing.image]::FromFile("$($Env:Public)\Pictures\Sample Pictures\Oryx Antelope.jpg")
#$Form.BackgroundImage = $Image
#$Form.BackgroundImageLayout = "None"
# None, Tile, Center, Stretch, Zoom

#	$objLabel = New-Object System.Windows.Forms.Label
#	$objLabel.Location = New-Object System.Drawing.Size(10,10)
#	$objLabel.Size = New-Object System.Drawing.Size(200,20)
#	$objLabel.Text = "XMRig API Parameters:"
#	$objLabel.Font = New-Object System.Drawing.Font("Times New Roman",12,[System.Drawing.FontStyle]::Bold)
#	$objLabel.BackColor = "Transparent"
#	$objForm.Controls.Add($objLabel)

	$objTabControl = New-Object System.Windows.Forms.TabControl
	$objTabControl.Location  = New-Object System.Drawing.Point($FormDimensions["objTabControlHorizontalPosition"],$FormDimensions["objTabControlVerticalPosition"])
	$objTabControl.Size = New-Object System.Drawing.Size($FormDimensions["objTabControlWidth"],$FormDimensions["objTabControlHeight"])
	$objTabControl.Font = New-Object System.Drawing.Font("Times New Roman",11,[System.Drawing.FontStyle]::Regular)

	$objTabPageMonitor = New-Object System.Windows.Forms.TabPage
	$objTabPageMonitor.TabIndex = 0
	$objTabPageMonitor.Location = New-Object System.Drawing.Point($FormDimensions["objTabPageMonitorHorizontalPosition"],$FormDimensions["objTabPageMonitorVerticalPosition"])
	$objTabPageMonitor.Size = New-Object System.Drawing.Size($FormDimensions["objTabPageMonitorWidth"],$FormDimensions["objTabPageMonitorHeight"])
	$objTabPageMonitor.Padding = "0, 0, 0, 0"
	$objTabPageMonitor.Text = "Monitor"

		$objTabPageSettingsGroupBoxInformation = New-Object System.Windows.Forms.GroupBox
		$objTabPageSettingsGroupBoxInformation.Location = New-Object System.Drawing.Point($FormDimensions["objTabPageMonitorInformationHorizontalPosition"],$FormDimensions["objTabPageMonitorInformationVerticalPosition"])
		$objTabPageSettingsGroupBoxInformation.Size = New-Object System.Drawing.Size($FormDimensions["objTabPageMonitorInformationWidth"],$FormDimensions["objTabPageMonitorInformationHeight"])
		$objTabPageSettingsGroupBoxInformation.Font = New-Object System.Drawing.Font("Times New Roman",10,[System.Drawing.FontStyle]::Regular)
		$objTabPageSettingsGroupBoxInformation.Text = "Information:"
#		$objTabPageSettingsGroupBoxInformation.AutoSize = $true

			$objTabPageSettingsGroupBoxInformationLabelUA = New-Object System.Windows.Forms.Label
			$objTabPageSettingsGroupBoxInformationLabelUA.Location = New-Object System.Drawing.Size(5,20)
			$objTabPageSettingsGroupBoxInformationLabelUA.Size = New-Object System.Drawing.Size(490,20)
			$objTabPageSettingsGroupBoxInformationLabelUA.Text = ""
			$objTabPageSettingsGroupBoxInformationLabelUA.Font = New-Object System.Drawing.Font("Times New Roman",10,[System.Drawing.FontStyle]::Bold)
			$objTabPageSettingsGroupBoxInformationLabelUA.BackColor = "Transparent"
			$objTabPageSettingsGroupBoxInformation.Controls.Add($objTabPageSettingsGroupBoxInformationLabelUA)

			$objTabPageSettingsGroupBoxInformationLabelWorkerID = New-Object System.Windows.Forms.Label
			$objTabPageSettingsGroupBoxInformationLabelWorkerID.Location = New-Object System.Drawing.Size(5,45)
			$objTabPageSettingsGroupBoxInformationLabelWorkerID.Size = New-Object System.Drawing.Size(80,20)
			$objTabPageSettingsGroupBoxInformationLabelWorkerID.Text = "Worker ID:"
			$objTabPageSettingsGroupBoxInformationLabelWorkerID.Font = New-Object System.Drawing.Font("Times New Roman",11,[System.Drawing.FontStyle]::Regular)
			$objTabPageSettingsGroupBoxInformationLabelWorkerID.BackColor = "Transparent"
			$objTabPageSettingsGroupBoxInformation.Controls.Add($objTabPageSettingsGroupBoxInformationLabelWorkerID)
			$objTabPageSettingsGroupBoxInformationTextBoxWorkerID = New-Object System.Windows.Forms.TextBox
			$objTabPageSettingsGroupBoxInformationTextBoxWorkerID.Location = New-Object System.Drawing.Point(85,45)
			$objTabPageSettingsGroupBoxInformationTextBoxWorkerID.Size = New-Object System.Drawing.Size(150,20)
			$objTabPageSettingsGroupBoxInformationTextBoxWorkerID.Cursor = [System.Windows.Forms.Cursors]::Default
			$objTabPageSettingsGroupBoxInformationTextBoxWorkerID.ReadOnly = $True
			$objTabPageSettingsGroupBoxInformationTextBoxWorkerID.Text = ""
			$objTabPageSettingsGroupBoxInformation.Controls.Add($objTabPageSettingsGroupBoxInformationTextBoxWorkerID)
			$objTabPageSettingsGroupBoxInformationLabelID = New-Object System.Windows.Forms.Label
			$objTabPageSettingsGroupBoxInformationLabelID.Location = New-Object System.Drawing.Size(310,45)
			$objTabPageSettingsGroupBoxInformationLabelID.Size = New-Object System.Drawing.Size(80,20)
			$objTabPageSettingsGroupBoxInformationLabelID.Text = "ID:"
			$objTabPageSettingsGroupBoxInformationLabelID.Font = New-Object System.Drawing.Font("Times New Roman",11,[System.Drawing.FontStyle]::Regular)
			$objTabPageSettingsGroupBoxInformationLabelID.BackColor = "Transparent"
			$objTabPageSettingsGroupBoxInformation.Controls.Add($objTabPageSettingsGroupBoxInformationLabelID)
			$objTabPageSettingsGroupBoxInformationTextBoxID = New-Object System.Windows.Forms.TextBox
			$objTabPageSettingsGroupBoxInformationTextBoxID.Location = New-Object System.Drawing.Point(390,45)
			$objTabPageSettingsGroupBoxInformationTextBoxID.Size = New-Object System.Drawing.Size(150,20)
			$objTabPageSettingsGroupBoxInformationTextBoxID.Cursor = [System.Windows.Forms.Cursors]::Default
			$objTabPageSettingsGroupBoxInformationTextBoxID.ReadOnly = $True
			$objTabPageSettingsGroupBoxInformationTextBoxID.Text = ""
			$objTabPageSettingsGroupBoxInformation.Controls.Add($objTabPageSettingsGroupBoxInformationTextBoxID)

			$objTabPageSettingsGroupBoxInformationLabelVersion = New-Object System.Windows.Forms.Label
			$objTabPageSettingsGroupBoxInformationLabelVersion.Location = New-Object System.Drawing.Size(5,70)
			$objTabPageSettingsGroupBoxInformationLabelVersion.Size = New-Object System.Drawing.Size(80,20)
			$objTabPageSettingsGroupBoxInformationLabelVersion.Text = "Version:"
			$objTabPageSettingsGroupBoxInformationLabelVersion.Font = New-Object System.Drawing.Font("Times New Roman",11,[System.Drawing.FontStyle]::Regular)
			$objTabPageSettingsGroupBoxInformationLabelVersion.BackColor = "Transparent"
			$objTabPageSettingsGroupBoxInformation.Controls.Add($objTabPageSettingsGroupBoxInformationLabelVersion)
			$objTabPageSettingsGroupBoxInformationTextBoxVersion = New-Object System.Windows.Forms.TextBox
			$objTabPageSettingsGroupBoxInformationTextBoxVersion.Location = New-Object System.Drawing.Point(85,70)
			$objTabPageSettingsGroupBoxInformationTextBoxVersion.Size = New-Object System.Drawing.Size(50,20)
			$objTabPageSettingsGroupBoxInformationTextBoxVersion.Cursor = [System.Windows.Forms.Cursors]::Default
			$objTabPageSettingsGroupBoxInformationTextBoxVersion.ReadOnly = $True
			$objTabPageSettingsGroupBoxInformationTextBoxVersion.Text = ""
			$objTabPageSettingsGroupBoxInformation.Controls.Add($objTabPageSettingsGroupBoxInformationTextBoxVersion)

			$objTabPageSettingsGroupBoxInformationLabelKind = New-Object System.Windows.Forms.Label
			$objTabPageSettingsGroupBoxInformationLabelKind.Location = New-Object System.Drawing.Size(310,70)
			$objTabPageSettingsGroupBoxInformationLabelKind.Size = New-Object System.Drawing.Size(80,20)
			$objTabPageSettingsGroupBoxInformationLabelKind.Text = "Type:"
			$objTabPageSettingsGroupBoxInformationLabelKind.Font = New-Object System.Drawing.Font("Times New Roman",11,[System.Drawing.FontStyle]::Regular)
			$objTabPageSettingsGroupBoxInformationLabelKind.BackColor = "Transparent"
			$objTabPageSettingsGroupBoxInformation.Controls.Add($objTabPageSettingsGroupBoxInformationLabelKind)
			$objTabPageSettingsGroupBoxInformationTextBoxKind = New-Object System.Windows.Forms.TextBox
			$objTabPageSettingsGroupBoxInformationTextBoxKind.Location = New-Object System.Drawing.Point(390,70)
			$objTabPageSettingsGroupBoxInformationTextBoxKind.Size = New-Object System.Drawing.Size(50,20)
			$objTabPageSettingsGroupBoxInformationTextBoxKind.Cursor = [System.Windows.Forms.Cursors]::Default
			$objTabPageSettingsGroupBoxInformationTextBoxKind.ReadOnly = $True
			$objTabPageSettingsGroupBoxInformationTextBoxKind.Text = ""

			$objTabPageSettingsGroupBoxInformationLabelDonateLevel = New-Object System.Windows.Forms.Label
			$objTabPageSettingsGroupBoxInformationLabelDonateLevel.Location = New-Object System.Drawing.Size(520,70)
			$objTabPageSettingsGroupBoxInformationLabelDonateLevel.Size = New-Object System.Drawing.Size(50,20)
			$objTabPageSettingsGroupBoxInformationLabelDonateLevel.Text = "Donate:"
			$objTabPageSettingsGroupBoxInformationLabelDonateLevel.Font = New-Object System.Drawing.Font("Times New Roman",11,[System.Drawing.FontStyle]::Regular)
			$objTabPageSettingsGroupBoxInformationLabelDonateLevel.BackColor = "Transparent"
			$objTabPageSettingsGroupBoxInformation.Controls.Add($objTabPageSettingsGroupBoxInformationLabelDonateLevel)
			$objTabPageSettingsGroupBoxInformationTextBoxDonateLevel = New-Object System.Windows.Forms.TextBox
			$objTabPageSettingsGroupBoxInformationTextBoxDonateLevel.Location = New-Object System.Drawing.Point(570,70)
			$objTabPageSettingsGroupBoxInformationTextBoxDonateLevel.Size = New-Object System.Drawing.Size(30,20)
			$objTabPageSettingsGroupBoxInformationTextBoxDonateLevel.Cursor = [System.Windows.Forms.Cursors]::Default
			$objTabPageSettingsGroupBoxInformationTextBoxDonateLevel.ReadOnly = $True
			$objTabPageSettingsGroupBoxInformationTextBoxDonateLevel.TextAlign = "Center";
			$objTabPageSettingsGroupBoxInformationTextBoxDonateLevel.Text = ""
			$objTabPageSettingsGroupBoxInformation.Controls.Add($objTabPageSettingsGroupBoxInformationTextBoxDonateLevel)
			$objTabPageSettingsGroupBoxInformationLabelDonateLevelPercent = New-Object System.Windows.Forms.Label
			$objTabPageSettingsGroupBoxInformationLabelDonateLevelPercent.Location = New-Object System.Drawing.Size(600,70)
			$objTabPageSettingsGroupBoxInformationLabelDonateLevelPercent.Size = New-Object System.Drawing.Size(20,20)
			$objTabPageSettingsGroupBoxInformationLabelDonateLevelPercent.Text = "%"
			$objTabPageSettingsGroupBoxInformationLabelDonateLevelPercent.Font = New-Object System.Drawing.Font("Times New Roman",11,[System.Drawing.FontStyle]::Regular)
			$objTabPageSettingsGroupBoxInformationLabelDonateLevelPercent.BackColor = "Transparent"
			$objTabPageSettingsGroupBoxInformation.Controls.Add($objTabPageSettingsGroupBoxInformationLabelDonateLevelPercent)

			$objTabPageSettingsGroupBoxInformationLabelAlgo = New-Object System.Windows.Forms.Label
			$objTabPageSettingsGroupBoxInformationLabelAlgo.Location = New-Object System.Drawing.Size(5,95)
			$objTabPageSettingsGroupBoxInformationLabelAlgo.Size = New-Object System.Drawing.Size(80,20)
			$objTabPageSettingsGroupBoxInformationLabelAlgo.Text = "Algorytm:"
			$objTabPageSettingsGroupBoxInformationLabelAlgo.Font = New-Object System.Drawing.Font("Times New Roman",11,[System.Drawing.FontStyle]::Regular)
			$objTabPageSettingsGroupBoxInformationLabelAlgo.BackColor = "Transparent"
			$objTabPageSettingsGroupBoxInformation.Controls.Add($objTabPageSettingsGroupBoxInformationLabelAlgo)
			$objTabPageSettingsGroupBoxInformationTextBoxAlgo = New-Object System.Windows.Forms.TextBox
			$objTabPageSettingsGroupBoxInformationTextBoxAlgo.Location = New-Object System.Drawing.Point(85,95)
			$objTabPageSettingsGroupBoxInformationTextBoxAlgo.Size = New-Object System.Drawing.Size(150,20)
			$objTabPageSettingsGroupBoxInformationTextBoxAlgo.Cursor = [System.Windows.Forms.Cursors]::Default
			$objTabPageSettingsGroupBoxInformationTextBoxAlgo.ReadOnly = $True
			$objTabPageSettingsGroupBoxInformationTextBoxAlgo.Text = ""
			$objTabPageSettingsGroupBoxInformation.Controls.Add($objTabPageSettingsGroupBoxInformationTextBoxAlgo)

			$objTabPageSettingsGroupBoxInformation.Controls.Add($objTabPageSettingsGroupBoxInformationTextBoxKind)
			$objTabPageSettingsGroupBoxInformationLabelHugepages = New-Object System.Windows.Forms.Label
			$objTabPageSettingsGroupBoxInformationLabelHugepages.Location = New-Object System.Drawing.Size(310,95)
			$objTabPageSettingsGroupBoxInformationLabelHugepages.Size = New-Object System.Drawing.Size(80,20)
			$objTabPageSettingsGroupBoxInformationLabelHugepages.Text = "Hugepages:"
			$objTabPageSettingsGroupBoxInformationLabelHugepages.Font = New-Object System.Drawing.Font("Times New Roman",11,[System.Drawing.FontStyle]::Regular)
			$objTabPageSettingsGroupBoxInformationLabelHugepages.BackColor = "Transparent"
			$objTabPageSettingsGroupBoxInformation.Controls.Add($objTabPageSettingsGroupBoxInformationLabelHugepages)
			$objTabPageSettingsGroupBoxInformationCheckBoxHugepages = New-Object System.Windows.Forms.CheckBox
			$objTabPageSettingsGroupBoxInformationCheckBoxHugepages.Location = New-Object System.Drawing.Point(390,95)
			$objTabPageSettingsGroupBoxInformationCheckBoxHugepages.AutoSize = $True
			$objTabPageSettingsGroupBoxInformationCheckBoxHugepages.Checked = $False
			$objTabPageSettingsGroupBoxInformationCheckBoxHugepages.Enabled = $False
			$objTabPageSettingsGroupBoxInformationCheckBoxHugepages.Text = ""
			$objTabPageSettingsGroupBoxInformation.Controls.Add($objTabPageSettingsGroupBoxInformationCheckBoxHugepages)

		$objTabPageMonitor.Controls.Add($objTabPageSettingsGroupBoxInformation)

		$objTabPageSettingsGroupBoxCPU = New-Object System.Windows.Forms.GroupBox
		$objTabPageSettingsGroupBoxCPU.Location = New-Object System.Drawing.Point($FormDimensions["objTabPageMonitorCPUHorizontalPosition"],$FormDimensions["objTabPageMonitorCPUVerticalPosition"])
		$objTabPageSettingsGroupBoxCPU.Size = New-Object System.Drawing.Size($FormDimensions["objTabPageMonitorCPUWidth"],$FormDimensions["objTabPageMonitorCPUHeight"])
		$objTabPageSettingsGroupBoxCPU.Font = New-Object System.Drawing.Font("Times New Roman",10,[System.Drawing.FontStyle]::Regular)
		$objTabPageSettingsGroupBoxCPU.Text = "CPU:"

			$objTabPageSettingsGroupBoxCPULabelBrand = New-Object System.Windows.Forms.Label
			$objTabPageSettingsGroupBoxCPULabelBrand.Location = New-Object System.Drawing.Size(5,20)
			$objTabPageSettingsGroupBoxCPULabelBrand.Size = New-Object System.Drawing.Size(50,20)
			$objTabPageSettingsGroupBoxCPULabelBrand.Text = "Brand:"
			$objTabPageSettingsGroupBoxCPULabelBrand.Font = New-Object System.Drawing.Font("Times New Roman",11,[System.Drawing.FontStyle]::Regular)
			$objTabPageSettingsGroupBoxCPULabelBrand.BackColor = "Transparent"
			$objTabPageSettingsGroupBoxCPU.Controls.Add($objTabPageSettingsGroupBoxCPULabelBrand)
			$objTabPageSettingsGroupBoxCPUTextBoxBrand = New-Object System.Windows.Forms.TextBox
			$objTabPageSettingsGroupBoxCPUTextBoxBrand.Location = New-Object System.Drawing.Point(55,20)
			$objTabPageSettingsGroupBoxCPUTextBoxBrand.Size = New-Object System.Drawing.Size(320,20)
			$objTabPageSettingsGroupBoxCPUTextBoxBrand.Cursor = [System.Windows.Forms.Cursors]::Default
			$objTabPageSettingsGroupBoxCPUTextBoxBrand.ReadOnly = $True
			$objTabPageSettingsGroupBoxCPUTextBoxBrand.Text = ""
			$objTabPageSettingsGroupBoxCPU.Controls.Add($objTabPageSettingsGroupBoxCPUTextBoxBrand)

			$objTabPageSettingsGroupBoxCPULabelAES = New-Object System.Windows.Forms.Label
			$objTabPageSettingsGroupBoxCPULabelAES.Location = New-Object System.Drawing.Size(390,20)
			$objTabPageSettingsGroupBoxCPULabelAES.Size = New-Object System.Drawing.Size(40,20)
			$objTabPageSettingsGroupBoxCPULabelAES.Text = "AES:"
			$objTabPageSettingsGroupBoxCPULabelAES.Font = New-Object System.Drawing.Font("Times New Roman",11,[System.Drawing.FontStyle]::Regular)
			$objTabPageSettingsGroupBoxCPULabelAES.BackColor = "Transparent"
			$objTabPageSettingsGroupBoxCPU.Controls.Add($objTabPageSettingsGroupBoxCPULabelAES)
			$objTabPageSettingsGroupBoxCPUCheckBoxAES = New-Object System.Windows.Forms.CheckBox
			$objTabPageSettingsGroupBoxCPUCheckBoxAES.Location = New-Object System.Drawing.Point(430,20)
			$objTabPageSettingsGroupBoxCPUCheckBoxAES.AutoSize = $True
			$objTabPageSettingsGroupBoxCPUCheckBoxAES.Checked = $False
			$objTabPageSettingsGroupBoxCPUCheckBoxAES.Enabled = $False
			$objTabPageSettingsGroupBoxCPU.Controls.Add($objTabPageSettingsGroupBoxCPUCheckBoxAES)

			$objTabPageSettingsGroupBoxCPULabelX64 = New-Object System.Windows.Forms.Label
			$objTabPageSettingsGroupBoxCPULabelX64.Location = New-Object System.Drawing.Size(460,20)
			$objTabPageSettingsGroupBoxCPULabelX64.Size = New-Object System.Drawing.Size(40,20)
			$objTabPageSettingsGroupBoxCPULabelX64.Text = "X64:"
			$objTabPageSettingsGroupBoxCPULabelX64.Font = New-Object System.Drawing.Font("Times New Roman",11,[System.Drawing.FontStyle]::Regular)
			$objTabPageSettingsGroupBoxCPULabelX64.BackColor = "Transparent"
			$objTabPageSettingsGroupBoxCPU.Controls.Add($objTabPageSettingsGroupBoxCPULabelX64)
			$objTabPageSettingsGroupBoxCPUCheckBoxX64 = New-Object System.Windows.Forms.CheckBox
			$objTabPageSettingsGroupBoxCPUCheckBoxX64.Location = New-Object System.Drawing.Point(500,20)
			$objTabPageSettingsGroupBoxCPUCheckBoxX64.AutoSize = $True
			$objTabPageSettingsGroupBoxCPUCheckBoxX64.Checked = $False
			$objTabPageSettingsGroupBoxCPUCheckBoxX64.Enabled = $False
			$objTabPageSettingsGroupBoxCPU.Controls.Add($objTabPageSettingsGroupBoxCPUCheckBoxX64)

			$objTabPageSettingsGroupBoxCPULabelSockets = New-Object System.Windows.Forms.Label
			$objTabPageSettingsGroupBoxCPULabelSockets.Location = New-Object System.Drawing.Size(530,20)
			$objTabPageSettingsGroupBoxCPULabelSockets.Size = New-Object System.Drawing.Size(60,20)
			$objTabPageSettingsGroupBoxCPULabelSockets.Text = "Sockets:"
			$objTabPageSettingsGroupBoxCPULabelSockets.Font = New-Object System.Drawing.Font("Times New Roman",11,[System.Drawing.FontStyle]::Regular)
			$objTabPageSettingsGroupBoxCPULabelSockets.BackColor = "Transparent"
			$objTabPageSettingsGroupBoxCPU.Controls.Add($objTabPageSettingsGroupBoxCPULabelSockets)
			$objTabPageSettingsGroupBoxCPUTextBoxSockets = New-Object System.Windows.Forms.TextBox
			$objTabPageSettingsGroupBoxCPUTextBoxSockets.Location = New-Object System.Drawing.Point(590,20)
			$objTabPageSettingsGroupBoxCPUTextBoxSockets.Size = New-Object System.Drawing.Size(30,20)
			$objTabPageSettingsGroupBoxCPUTextBoxSockets.Cursor = [System.Windows.Forms.Cursors]::Default
			$objTabPageSettingsGroupBoxCPUTextBoxSockets.ReadOnly = $True
			$objTabPageSettingsGroupBoxCPUTextBoxSockets.TextAlign = "Center";
			$objTabPageSettingsGroupBoxCPUTextBoxSockets.Text = ""
			$objTabPageSettingsGroupBoxCPU.Controls.Add($objTabPageSettingsGroupBoxCPUTextBoxSockets)

		$objTabPageMonitor.Controls.Add($objTabPageSettingsGroupBoxCPU)

		$objTabPageSettingsGroupBoxNVIDIA = New-Object System.Windows.Forms.GroupBox
		$objTabPageSettingsGroupBoxNVIDIA.Location = New-Object System.Drawing.Point($FormDimensions["objTabPageMonitorNVIDIAHorizontalPosition"],$FormDimensions["objTabPageMonitorNVIDIAVerticalPosition"])
		$objTabPageSettingsGroupBoxNVIDIA.Size = New-Object System.Drawing.Size($FormDimensions["objTabPageMonitorNVIDIAWidth"],$FormDimensions["objTabPageMonitorNVIDIAHeight"])
		$objTabPageSettingsGroupBoxNVIDIA.Font = New-Object System.Drawing.Font("Times New Roman",10,[System.Drawing.FontStyle]::Regular)
		$objTabPageSettingsGroupBoxNVIDIA.Visible = $Script:FormFieldNVIDIAVisible
		$objTabPageSettingsGroupBoxNVIDIA.Text = "NVIDIA:"

			$objTabPageSettingsGroupBoxNVIDIAListView = New-Object System.Windows.Forms.ListView
			$objTabPageSettingsGroupBoxNVIDIAListView.Location = New-Object System.Drawing.Point(5,15)
			If ($FormDimensions["objTabPageMonitorNVIDIAHeight"] -lt 15) {
				$objTabPageSettingsGroupBoxNVIDIAListView.Size = New-Object System.Drawing.Size(620,0)
			} Else {
				$objTabPageSettingsGroupBoxNVIDIAListView.Size = New-Object System.Drawing.Size(620,($FormDimensions["objTabPageMonitorNVIDIAHeight"] - 15))
			}
			$objTabPageSettingsGroupBoxNVIDIAListView.View = [System.Windows.Forms.View]::Details
			$objTabPageSettingsGroupBoxNVIDIAListView.Anchor = "Top, Left, Right, Bottom"
			$objTabPageSettingsGroupBoxNVIDIAListView.Columns.Add("#", 20, "Center") | Out-Null
			$objTabPageSettingsGroupBoxNVIDIAListView.Columns.Add("Name", 125, "Center") | Out-Null
			$objTabPageSettingsGroupBoxNVIDIAListView.Columns.Add("GPU Clock", 90, "Center") | Out-Null
			$objTabPageSettingsGroupBoxNVIDIAListView.Columns.Add("Memory Clock", 90, "Center") | Out-Null
			$objTabPageSettingsGroupBoxNVIDIAListView.Columns.Add("Power", 90, "Center") | Out-Null
			$objTabPageSettingsGroupBoxNVIDIAListView.Columns.Add("Temperature", 90, "Center") | Out-Null
			$objTabPageSettingsGroupBoxNVIDIAListView.Columns.Add("Fan", 90, "Center") | Out-Null
			$objTabPageSettingsGroupBoxNVIDIAListView.Add_ColumnClick({SortListView $objTabPageSettingsGroupBoxNVIDIAListView $_.Column})
			$objTabPageSettingsGroupBoxNVIDIA.Controls.Add($objTabPageSettingsGroupBoxNVIDIAListView)

		$objTabPageMonitor.Controls.Add($objTabPageSettingsGroupBoxNVIDIA)

		$objTabPageSettingsGroupBoxConnection = New-Object System.Windows.Forms.GroupBox
		$objTabPageSettingsGroupBoxConnection.Location = New-Object System.Drawing.Point($FormDimensions["objTabPageMonitorConnectionHorizontalPosition"],$FormDimensions["objTabPageMonitorConnectionVerticalPosition"])
		$objTabPageSettingsGroupBoxConnection.Size = New-Object System.Drawing.Size($FormDimensions["objTabPageMonitorConnectionWidth"],$FormDimensions["objTabPageMonitorConnectionHeight"])
		$objTabPageSettingsGroupBoxConnection.Font = New-Object System.Drawing.Font("Times New Roman",10,[System.Drawing.FontStyle]::Regular)
		$objTabPageSettingsGroupBoxConnection.Text = "Connection:"

			$objTabPageSettingsGroupBoxConnectionLabelPool = New-Object System.Windows.Forms.Label
			$objTabPageSettingsGroupBoxConnectionLabelPool.Location = New-Object System.Drawing.Size(5,20)
			$objTabPageSettingsGroupBoxConnectionLabelPool.Size = New-Object System.Drawing.Size(40,20)
			$objTabPageSettingsGroupBoxConnectionLabelPool.Text = "Pool:"
			$objTabPageSettingsGroupBoxConnectionLabelPool.Font = New-Object System.Drawing.Font("Times New Roman",11,[System.Drawing.FontStyle]::Regular)
			$objTabPageSettingsGroupBoxConnectionLabelPool.BackColor = "Transparent"
			$objTabPageSettingsGroupBoxConnection.Controls.Add($objTabPageSettingsGroupBoxConnectionLabelPool)
			$objTabPageSettingsGroupBoxConnectionTextBoxPool = New-Object System.Windows.Forms.TextBox
			$objTabPageSettingsGroupBoxConnectionTextBoxPool.Location = New-Object System.Drawing.Point(45,20)
			$objTabPageSettingsGroupBoxConnectionTextBoxPool.Size = New-Object System.Drawing.Size(190,20)
			$objTabPageSettingsGroupBoxConnectionTextBoxPool.ReadOnly = $True
			$objTabPageSettingsGroupBoxConnectionTextBoxPool.Text = ""
			$objTabPageSettingsGroupBoxConnection.Controls.Add($objTabPageSettingsGroupBoxConnectionTextBoxPool)

			$objTabPageSettingsGroupBoxConnectionLabelPing = New-Object System.Windows.Forms.Label
			$objTabPageSettingsGroupBoxConnectionLabelPing.Location = New-Object System.Drawing.Size(245,20)
			$objTabPageSettingsGroupBoxConnectionLabelPing.Size = New-Object System.Drawing.Size(40,20)
			$objTabPageSettingsGroupBoxConnectionLabelPing.Text = "Ping:"
			$objTabPageSettingsGroupBoxConnectionLabelPing.Font = New-Object System.Drawing.Font("Times New Roman",11,[System.Drawing.FontStyle]::Regular)
			$objTabPageSettingsGroupBoxConnectionLabelPing.BackColor = "Transparent"
			$objTabPageSettingsGroupBoxConnection.Controls.Add($objTabPageSettingsGroupBoxConnectionLabelPing)
			$objTabPageSettingsGroupBoxConnectionTextBoxPing = New-Object System.Windows.Forms.TextBox
			$objTabPageSettingsGroupBoxConnectionTextBoxPing.Location = New-Object System.Drawing.Point(285,20)
			$objTabPageSettingsGroupBoxConnectionTextBoxPing.Size = New-Object System.Drawing.Size(40,20)
			$objTabPageSettingsGroupBoxConnectionTextBoxPing.Cursor = [System.Windows.Forms.Cursors]::Default
			$objTabPageSettingsGroupBoxConnectionTextBoxPing.ReadOnly = $True
			$objTabPageSettingsGroupBoxConnectionTextBoxPing.TextAlign = "Center";
			$objTabPageSettingsGroupBoxConnectionTextBoxPing.Text = ""
			$objTabPageSettingsGroupBoxConnection.Controls.Add($objTabPageSettingsGroupBoxConnectionTextBoxPing)
			$objTabPageSettingsGroupBoxConnectionLabelPingUnits = New-Object System.Windows.Forms.Label
			$objTabPageSettingsGroupBoxConnectionLabelPingUnits.Location = New-Object System.Drawing.Size(325,20)
			$objTabPageSettingsGroupBoxConnectionLabelPingUnits.Size = New-Object System.Drawing.Size(40,20)
			$objTabPageSettingsGroupBoxConnectionLabelPingUnits.Text = "[ms]"
			$objTabPageSettingsGroupBoxConnectionLabelPingUnits.Font = New-Object System.Drawing.Font("Times New Roman",11,[System.Drawing.FontStyle]::Regular)
			$objTabPageSettingsGroupBoxConnectionLabelPingUnits.BackColor = "Transparent"
			$objTabPageSettingsGroupBoxConnection.Controls.Add($objTabPageSettingsGroupBoxConnectionLabelPingUnits)

			$objTabPageSettingsGroupBoxConnectionLabelUptime = New-Object System.Windows.Forms.Label
			$objTabPageSettingsGroupBoxConnectionLabelUptime.Location = New-Object System.Drawing.Size(375,20)
			$objTabPageSettingsGroupBoxConnectionLabelUptime.Size = New-Object System.Drawing.Size(55,20)
			$objTabPageSettingsGroupBoxConnectionLabelUptime.Text = "Uptime:"
			$objTabPageSettingsGroupBoxConnectionLabelUptime.Font = New-Object System.Drawing.Font("Times New Roman",11,[System.Drawing.FontStyle]::Regular)
			$objTabPageSettingsGroupBoxConnectionLabelUptime.BackColor = "Transparent"
			$objTabPageSettingsGroupBoxConnection.Controls.Add($objTabPageSettingsGroupBoxConnectionLabelUptime)
			$objTabPageSettingsGroupBoxConnectionTextBoxUptime = New-Object System.Windows.Forms.TextBox
			$objTabPageSettingsGroupBoxConnectionTextBoxUptime.Location = New-Object System.Drawing.Point(430,20)
			$objTabPageSettingsGroupBoxConnectionTextBoxUptime.Size = New-Object System.Drawing.Size(60,20)
			$objTabPageSettingsGroupBoxConnectionTextBoxUptime.Cursor = [System.Windows.Forms.Cursors]::Default
			$objTabPageSettingsGroupBoxConnectionTextBoxUptime.ReadOnly = $True
			$objTabPageSettingsGroupBoxConnectionTextBoxUptime.TextAlign = "Center";
			$objTabPageSettingsGroupBoxConnectionTextBoxUptime.Text = ""
			$objTabPageSettingsGroupBoxConnection.Controls.Add($objTabPageSettingsGroupBoxConnectionTextBoxUptime)
			$objTabPageSettingsGroupBoxConnectionLabelUptimeUnits = New-Object System.Windows.Forms.Label
			$objTabPageSettingsGroupBoxConnectionLabelUptimeUnits.Location = New-Object System.Drawing.Size(490,20)
			$objTabPageSettingsGroupBoxConnectionLabelUptimeUnits.Size = New-Object System.Drawing.Size(30,20)
			$objTabPageSettingsGroupBoxConnectionLabelUptimeUnits.Text = "[s]"
			$objTabPageSettingsGroupBoxConnectionLabelUptimeUnits.Font = New-Object System.Drawing.Font("Times New Roman",11,[System.Drawing.FontStyle]::Regular)
			$objTabPageSettingsGroupBoxConnectionLabelUptimeUnits.BackColor = "Transparent"
			$objTabPageSettingsGroupBoxConnection.Controls.Add($objTabPageSettingsGroupBoxConnectionLabelUptimeUnits)

			$objTabPageSettingsGroupBoxConnectionLabelFailures = New-Object System.Windows.Forms.Label
			$objTabPageSettingsGroupBoxConnectionLabelFailures.Location = New-Object System.Drawing.Size(530,20)
			$objTabPageSettingsGroupBoxConnectionLabelFailures.Size = New-Object System.Drawing.Size(60,20)
			$objTabPageSettingsGroupBoxConnectionLabelFailures.Text = "Failures:"
			$objTabPageSettingsGroupBoxConnectionLabelFailures.Font = New-Object System.Drawing.Font("Times New Roman",11,[System.Drawing.FontStyle]::Regular)
			$objTabPageSettingsGroupBoxConnectionLabelFailures.BackColor = "Transparent"
			$objTabPageSettingsGroupBoxConnection.Controls.Add($objTabPageSettingsGroupBoxConnectionLabelFailures)
			$objTabPageSettingsGroupBoxConnectionTextBoxFailures = New-Object System.Windows.Forms.TextBox
			$objTabPageSettingsGroupBoxConnectionTextBoxFailures.Location = New-Object System.Drawing.Point(590,20)
			$objTabPageSettingsGroupBoxConnectionTextBoxFailures.Size = New-Object System.Drawing.Size(30,20)
			$objTabPageSettingsGroupBoxConnectionTextBoxFailures.Cursor = [System.Windows.Forms.Cursors]::Default
			$objTabPageSettingsGroupBoxConnectionTextBoxFailures.ReadOnly = $True
			$objTabPageSettingsGroupBoxConnectionTextBoxFailures.TextAlign = "Center";
			$objTabPageSettingsGroupBoxConnectionTextBoxFailures.Text = ""
			$objTabPageSettingsGroupBoxConnection.Controls.Add($objTabPageSettingsGroupBoxConnectionTextBoxFailures)

			$objTabPageSettingsGroupBoxConnectionErrorLog = New-Object System.Windows.Forms.GroupBox
			$objTabPageSettingsGroupBoxConnectionErrorLog.Location = New-Object System.Drawing.Point(5,45)
			$objTabPageSettingsGroupBoxConnectionErrorLog.Size = New-Object System.Drawing.Size(615,100)
			$objTabPageSettingsGroupBoxConnectionErrorLog.Font = New-Object System.Drawing.Font("Times New Roman",10,[System.Drawing.FontStyle]::Regular)
			$objTabPageSettingsGroupBoxConnectionErrorLog.Visible = $Script:FormFieldConnectionErrorLogVisible
			$objTabPageSettingsGroupBoxConnectionErrorLog.Text = "Error log:"

				$objTabPageSettingsGroupBoxConnectionListBoxErrorLog = New-Object System.Windows.Forms.ListBox
				$objTabPageSettingsGroupBoxConnectionListBoxErrorLog.Location = New-Object System.Drawing.Point(5,15)
				$objTabPageSettingsGroupBoxConnectionListBoxErrorLog.Size = New-Object System.Drawing.Size(605,80)
				$objTabPageSettingsGroupBoxConnectionErrorLog.Controls.Add($objTabPageSettingsGroupBoxConnectionListBoxErrorLog)

			$objTabPageSettingsGroupBoxConnection.Controls.Add($objTabPageSettingsGroupBoxConnectionErrorLog)

		$objTabPageMonitor.Controls.Add($objTabPageSettingsGroupBoxConnection)

		$objTabPageSettingsGroupBoxHashrate = New-Object System.Windows.Forms.GroupBox
		$objTabPageSettingsGroupBoxHashrate.Location = New-Object System.Drawing.Point($FormDimensions["objTabPageMonitorHashrateHorizontalPosition"],$FormDimensions["objTabPageMonitorHashrateVerticalPosition"])
		$objTabPageSettingsGroupBoxHashrate.Size = New-Object System.Drawing.Size($FormDimensions["objTabPageMonitorHashrateWidth"],$FormDimensions["objTabPageMonitorHashrateHeight"])
		$objTabPageSettingsGroupBoxHashrate.Font = New-Object System.Drawing.Font("Times New Roman",10,[System.Drawing.FontStyle]::Regular)
		$objTabPageSettingsGroupBoxHashrate.Text = "Hashrate:"

			$objTabPageSettingsGroupBoxHashrateLabelTotal1 = New-Object System.Windows.Forms.Label
			$objTabPageSettingsGroupBoxHashrateLabelTotal1.Location = New-Object System.Drawing.Size(5,20)
			$objTabPageSettingsGroupBoxHashrateLabelTotal1.Size = New-Object System.Drawing.Size(150,20)
			$objTabPageSettingsGroupBoxHashrateLabelTotal1.Text = "Total (in 2,5 seconds):"
			$objTabPageSettingsGroupBoxHashrateLabelTotal1.Font = New-Object System.Drawing.Font("Times New Roman",11,[System.Drawing.FontStyle]::Regular)
			$objTabPageSettingsGroupBoxHashrateLabelTotal1.BackColor = "Transparent"
			$objTabPageSettingsGroupBoxHashrate.Controls.Add($objTabPageSettingsGroupBoxHashrateLabelTotal1)
			$objTabPageSettingsGroupBoxHashrateTextBoxTotal1 = New-Object System.Windows.Forms.TextBox
			$objTabPageSettingsGroupBoxHashrateTextBoxTotal1.Location = New-Object System.Drawing.Point(155,20)
			$objTabPageSettingsGroupBoxHashrateTextBoxTotal1.Size = New-Object System.Drawing.Size(60,20)
			$objTabPageSettingsGroupBoxHashrateTextBoxTotal1.Cursor = [System.Windows.Forms.Cursors]::Default
			$objTabPageSettingsGroupBoxHashrateTextBoxTotal1.ReadOnly = $True
			$objTabPageSettingsGroupBoxHashrateTextBoxTotal1.TextAlign = "Center";
			$objTabPageSettingsGroupBoxHashrateTextBoxTotal1.Text = ""
			$objTabPageSettingsGroupBoxHashrate.Controls.Add($objTabPageSettingsGroupBoxHashrateTextBoxTotal1)
			$objTabPageSettingsGroupBoxHashrateLabelTotalUnits1 = New-Object System.Windows.Forms.Label
			$objTabPageSettingsGroupBoxHashrateLabelTotalUnits1.Location = New-Object System.Drawing.Size(215,20)
			$objTabPageSettingsGroupBoxHashrateLabelTotalUnits1.Size = New-Object System.Drawing.Size(40,20)
			$objTabPageSettingsGroupBoxHashrateLabelTotalUnits1.Text = "[H/s]"
			$objTabPageSettingsGroupBoxHashrateLabelTotalUnits1.Font = New-Object System.Drawing.Font("Times New Roman",11,[System.Drawing.FontStyle]::Regular)
			$objTabPageSettingsGroupBoxHashrateLabelTotalUnits1.BackColor = "Transparent"
			$objTabPageSettingsGroupBoxHashrate.Controls.Add($objTabPageSettingsGroupBoxHashrateLabelTotalUnits1)

			$objTabPageSettingsGroupBoxHashrateLabelTotal2 = New-Object System.Windows.Forms.Label
			$objTabPageSettingsGroupBoxHashrateLabelTotal2.Location = New-Object System.Drawing.Size(5,45)
			$objTabPageSettingsGroupBoxHashrateLabelTotal2.Size = New-Object System.Drawing.Size(150,20)
			$objTabPageSettingsGroupBoxHashrateLabelTotal2.Text = "Total (in 60 seconds):"
			$objTabPageSettingsGroupBoxHashrateLabelTotal2.Font = New-Object System.Drawing.Font("Times New Roman",11,[System.Drawing.FontStyle]::Regular)
			$objTabPageSettingsGroupBoxHashrateLabelTotal2.BackColor = "Transparent"
			$objTabPageSettingsGroupBoxHashrate.Controls.Add($objTabPageSettingsGroupBoxHashrateLabelTotal2)
			$objTabPageSettingsGroupBoxHashrateTextBoxTotal2 = New-Object System.Windows.Forms.TextBox
			$objTabPageSettingsGroupBoxHashrateTextBoxTotal2.Location = New-Object System.Drawing.Point(155,45)
			$objTabPageSettingsGroupBoxHashrateTextBoxTotal2.Size = New-Object System.Drawing.Size(60,20)
			$objTabPageSettingsGroupBoxHashrateTextBoxTotal2.Cursor = [System.Windows.Forms.Cursors]::Default
			$objTabPageSettingsGroupBoxHashrateTextBoxTotal2.ReadOnly = $True
			$objTabPageSettingsGroupBoxHashrateTextBoxTotal2.TextAlign = "Center";
			$objTabPageSettingsGroupBoxHashrateTextBoxTotal2.Text = ""
			$objTabPageSettingsGroupBoxHashrate.Controls.Add($objTabPageSettingsGroupBoxHashrateTextBoxTotal2)
			$objTabPageSettingsGroupBoxHashrateLabelTotalUnits2 = New-Object System.Windows.Forms.Label
			$objTabPageSettingsGroupBoxHashrateLabelTotalUnits2.Location = New-Object System.Drawing.Size(215,45)
			$objTabPageSettingsGroupBoxHashrateLabelTotalUnits2.Size = New-Object System.Drawing.Size(40,20)
			$objTabPageSettingsGroupBoxHashrateLabelTotalUnits2.Text = "[H/s]"
			$objTabPageSettingsGroupBoxHashrateLabelTotalUnits2.Font = New-Object System.Drawing.Font("Times New Roman",11,[System.Drawing.FontStyle]::Regular)
			$objTabPageSettingsGroupBoxHashrateLabelTotalUnits2.BackColor = "Transparent"
			$objTabPageSettingsGroupBoxHashrate.Controls.Add($objTabPageSettingsGroupBoxHashrateLabelTotalUnits2)

			$objTabPageSettingsGroupBoxHashrateLabelTotal3 = New-Object System.Windows.Forms.Label
			$objTabPageSettingsGroupBoxHashrateLabelTotal3.Location = New-Object System.Drawing.Size(5,70)
			$objTabPageSettingsGroupBoxHashrateLabelTotal3.Size = New-Object System.Drawing.Size(150,20)
			$objTabPageSettingsGroupBoxHashrateLabelTotal3.Text = "Total (in 15 minutes):"
			$objTabPageSettingsGroupBoxHashrateLabelTotal3.Font = New-Object System.Drawing.Font("Times New Roman",11,[System.Drawing.FontStyle]::Regular)
			$objTabPageSettingsGroupBoxHashrateLabelTotal3.BackColor = "Transparent"
			$objTabPageSettingsGroupBoxHashrate.Controls.Add($objTabPageSettingsGroupBoxHashrateLabelTotal3)
			$objTabPageSettingsGroupBoxHashrateTextBoxTotal3 = New-Object System.Windows.Forms.TextBox
			$objTabPageSettingsGroupBoxHashrateTextBoxTotal3.Location = New-Object System.Drawing.Point(155,70)
			$objTabPageSettingsGroupBoxHashrateTextBoxTotal3.Size = New-Object System.Drawing.Size(60,20)
			$objTabPageSettingsGroupBoxHashrateTextBoxTotal3.Cursor = [System.Windows.Forms.Cursors]::Default
			$objTabPageSettingsGroupBoxHashrateTextBoxTotal3.ReadOnly = $True
			$objTabPageSettingsGroupBoxHashrateTextBoxTotal3.TextAlign = "Center";
			$objTabPageSettingsGroupBoxHashrateTextBoxTotal3.Text = ""
			$objTabPageSettingsGroupBoxHashrate.Controls.Add($objTabPageSettingsGroupBoxHashrateTextBoxTotal3)
			$objTabPageSettingsGroupBoxHashrateLabelTotalUnits3 = New-Object System.Windows.Forms.Label
			$objTabPageSettingsGroupBoxHashrateLabelTotalUnits3.Location = New-Object System.Drawing.Size(215,70)
			$objTabPageSettingsGroupBoxHashrateLabelTotalUnits3.Size = New-Object System.Drawing.Size(40,20)
			$objTabPageSettingsGroupBoxHashrateLabelTotalUnits3.Text = "[H/s]"
			$objTabPageSettingsGroupBoxHashrateLabelTotalUnits3.Font = New-Object System.Drawing.Font("Times New Roman",11,[System.Drawing.FontStyle]::Regular)
			$objTabPageSettingsGroupBoxHashrateLabelTotalUnits3.BackColor = "Transparent"
			$objTabPageSettingsGroupBoxHashrate.Controls.Add($objTabPageSettingsGroupBoxHashrateLabelTotalUnits3)

			$objTabPageSettingsGroupBoxHashrateLabelHighest = New-Object System.Windows.Forms.Label
			$objTabPageSettingsGroupBoxHashrateLabelHighest.Location = New-Object System.Drawing.Size(5,95)
			$objTabPageSettingsGroupBoxHashrateLabelHighest.Size = New-Object System.Drawing.Size(150,20)
			$objTabPageSettingsGroupBoxHashrateLabelHighest.Text = "Highest:"
			$objTabPageSettingsGroupBoxHashrateLabelHighest.Font = New-Object System.Drawing.Font("Times New Roman",11,[System.Drawing.FontStyle]::Regular)
			$objTabPageSettingsGroupBoxHashrateLabelHighest.BackColor = "Transparent"
			$objTabPageSettingsGroupBoxHashrate.Controls.Add($objTabPageSettingsGroupBoxHashrateLabelHighest)
			$objTabPageSettingsGroupBoxHashrateTextBoxHighest = New-Object System.Windows.Forms.TextBox
			$objTabPageSettingsGroupBoxHashrateTextBoxHighest.Location = New-Object System.Drawing.Point(155,95)
			$objTabPageSettingsGroupBoxHashrateTextBoxHighest.Size = New-Object System.Drawing.Size(60,20)
			$objTabPageSettingsGroupBoxHashrateTextBoxHighest.Cursor = [System.Windows.Forms.Cursors]::Default
			$objTabPageSettingsGroupBoxHashrateTextBoxHighest.ReadOnly = $True
			$objTabPageSettingsGroupBoxHashrateTextBoxHighest.TextAlign = "Center";
			$objTabPageSettingsGroupBoxHashrateTextBoxHighest.Text = ""
			$objTabPageSettingsGroupBoxHashrate.Controls.Add($objTabPageSettingsGroupBoxHashrateTextBoxHighest)
			$objTabPageSettingsGroupBoxHashrateLabelHighestUnits = New-Object System.Windows.Forms.Label
			$objTabPageSettingsGroupBoxHashrateLabelHighestUnits.Location = New-Object System.Drawing.Size(215,95)
			$objTabPageSettingsGroupBoxHashrateLabelHighestUnits.Size = New-Object System.Drawing.Size(40,20)
			$objTabPageSettingsGroupBoxHashrateLabelHighestUnits.Text = "[H/s]"
			$objTabPageSettingsGroupBoxHashrateLabelHighestUnits.Font = New-Object System.Drawing.Font("Times New Roman",11,[System.Drawing.FontStyle]::Regular)
			$objTabPageSettingsGroupBoxHashrateLabelHighestUnits.BackColor = "Transparent"
			$objTabPageSettingsGroupBoxHashrate.Controls.Add($objTabPageSettingsGroupBoxHashrateLabelHighestUnits)

			$objTabPageSettingsGroupBoxHashrateThreads = New-Object System.Windows.Forms.GroupBox
			$objTabPageSettingsGroupBoxHashrateThreads.Location = New-Object System.Drawing.Point(360,10)
			$objTabPageSettingsGroupBoxHashrateThreads.Size = New-Object System.Drawing.Size(260,115)
			$objTabPageSettingsGroupBoxHashrateThreads.Font = New-Object System.Drawing.Font("Times New Roman",10,[System.Drawing.FontStyle]::Regular)
			$objTabPageSettingsGroupBoxHashrateThreads.Text = "Threads:"

				$objTabPageSettingsGroupBoxHashrateListViewThreads = New-Object System.Windows.Forms.ListView
				$objTabPageSettingsGroupBoxHashrateListViewThreads.Location = New-Object System.Drawing.Point(5,15)
				$objTabPageSettingsGroupBoxHashrateListViewThreads.Size = New-Object System.Drawing.Size(255,95)
				$objTabPageSettingsGroupBoxHashrateListViewThreads.View = [System.Windows.Forms.View]::Details
				$objTabPageSettingsGroupBoxHashrateListViewThreads.Width = $objTabPageSettingsGroupBoxHashrateListViewThreads.ClientRectangle.Width
				$objTabPageSettingsGroupBoxHashrateListViewThreads.Height = $objTabPageSettingsGroupBoxHashrateListViewThreads.ClientRectangle.Height
				$objTabPageSettingsGroupBoxHashrateListViewThreads.Anchor = "Top, Left, Right, Bottom"
				$objTabPageSettingsGroupBoxHashrateListViewThreads.Columns.Add("#", 20, "Center") | Out-Null
				$objTabPageSettingsGroupBoxHashrateListViewThreads.Columns.Add("2,5s", 70, "Center") | Out-Null
				$objTabPageSettingsGroupBoxHashrateListViewThreads.Columns.Add("60s", 70, "Center") | Out-Null
				$objTabPageSettingsGroupBoxHashrateListViewThreads.Columns.Add("15m", 70, "Center") | Out-Null
				$objTabPageSettingsGroupBoxHashrateListViewThreads.Add_ColumnClick({SortListView $objTabPageSettingsGroupBoxHashrateListViewThreads $_.Column})
				$objTabPageSettingsGroupBoxHashrateThreads.Controls.Add($objTabPageSettingsGroupBoxHashrateListViewThreads)

			$objTabPageSettingsGroupBoxHashrate.Controls.Add($objTabPageSettingsGroupBoxHashrateThreads)

		$objTabPageMonitor.Controls.Add($objTabPageSettingsGroupBoxHashrate)

		$objTabPageSettingsGroupBoxResults = New-Object System.Windows.Forms.GroupBox
		$objTabPageSettingsGroupBoxResults.Location = New-Object System.Drawing.Point($FormDimensions["objTabPageMonitorResultsHorizontalPosition"],$FormDimensions["objTabPageMonitorResultsVerticalPosition"])
		$objTabPageSettingsGroupBoxResults.Size = New-Object System.Drawing.Size($FormDimensions["objTabPageMonitorResultsWidth"],$FormDimensions["objTabPageMonitorResultsHeight"])
		$objTabPageSettingsGroupBoxResults.Font = New-Object System.Drawing.Font("Times New Roman",10,[System.Drawing.FontStyle]::Regular)
		$objTabPageSettingsGroupBoxResults.Text = "Results:"

			$objTabPageSettingsGroupBoxResultsLabelHashes = New-Object System.Windows.Forms.Label
			$objTabPageSettingsGroupBoxResultsLabelHashes.Location = New-Object System.Drawing.Size(5,20)
			$objTabPageSettingsGroupBoxResultsLabelHashes.Size = New-Object System.Drawing.Size(55,20)
			$objTabPageSettingsGroupBoxResultsLabelHashes.Text = "Hashes:"
			$objTabPageSettingsGroupBoxResultsLabelHashes.Font = New-Object System.Drawing.Font("Times New Roman",11,[System.Drawing.FontStyle]::Regular)
			$objTabPageSettingsGroupBoxResultsLabelHashes.BackColor = "Transparent"
			$objTabPageSettingsGroupBoxResults.Controls.Add($objTabPageSettingsGroupBoxResultsLabelHashes)
			$objTabPageSettingsGroupBoxResultsTextBoxHashes = New-Object System.Windows.Forms.TextBox
			$objTabPageSettingsGroupBoxResultsTextBoxHashes.Location = New-Object System.Drawing.Point(60,20)
			$objTabPageSettingsGroupBoxResultsTextBoxHashes.Size = New-Object System.Drawing.Size(80,20)
			$objTabPageSettingsGroupBoxResultsTextBoxHashes.Cursor = [System.Windows.Forms.Cursors]::Default
			$objTabPageSettingsGroupBoxResultsTextBoxHashes.ReadOnly = $True
			$objTabPageSettingsGroupBoxResultsTextBoxHashes.TextAlign = "Center";
			$objTabPageSettingsGroupBoxResultsTextBoxHashes.Text = ""
			$objTabPageSettingsGroupBoxResults.Controls.Add($objTabPageSettingsGroupBoxResultsTextBoxHashes)

			$objTabPageSettingsGroupBoxResultsLabelShares = New-Object System.Windows.Forms.Label
			$objTabPageSettingsGroupBoxResultsLabelShares.Location = New-Object System.Drawing.Size(150,20)
			$objTabPageSettingsGroupBoxResultsLabelShares.Size = New-Object System.Drawing.Size(135,20)
			$objTabPageSettingsGroupBoxResultsLabelShares.Text = "Shares (total / good):"
			$objTabPageSettingsGroupBoxResultsLabelShares.Font = New-Object System.Drawing.Font("Times New Roman",11,[System.Drawing.FontStyle]::Regular)
			$objTabPageSettingsGroupBoxResultsLabelShares.BackColor = "Transparent"
			$objTabPageSettingsGroupBoxResults.Controls.Add($objTabPageSettingsGroupBoxResultsLabelShares)
			$objTabPageSettingsGroupBoxResultsTextBoxSharesTotal = New-Object System.Windows.Forms.TextBox
			$objTabPageSettingsGroupBoxResultsTextBoxSharesTotal.Location = New-Object System.Drawing.Point(290,20)
			$objTabPageSettingsGroupBoxResultsTextBoxSharesTotal.Size = New-Object System.Drawing.Size(40,20)
			$objTabPageSettingsGroupBoxResultsTextBoxSharesTotal.Cursor = [System.Windows.Forms.Cursors]::Default
			$objTabPageSettingsGroupBoxResultsTextBoxSharesTotal.ReadOnly = $True
			$objTabPageSettingsGroupBoxResultsTextBoxSharesTotal.TextAlign = "Center";
			$objTabPageSettingsGroupBoxResultsTextBoxSharesTotal.Text = ""
			$objTabPageSettingsGroupBoxResults.Controls.Add($objTabPageSettingsGroupBoxResultsTextBoxSharesTotal)
			$objTabPageSettingsGroupBoxResultsLabelSharesDelimeter = New-Object System.Windows.Forms.Label
			$objTabPageSettingsGroupBoxResultsLabelSharesDelimeter.Location = New-Object System.Drawing.Size(330,20)
			$objTabPageSettingsGroupBoxResultsLabelSharesDelimeter.Size = New-Object System.Drawing.Size(10,20)
			$objTabPageSettingsGroupBoxResultsLabelSharesDelimeter.Text = "/"
			$objTabPageSettingsGroupBoxResultsLabelSharesDelimeter.Font = New-Object System.Drawing.Font("Times New Roman",11,[System.Drawing.FontStyle]::Regular)
			$objTabPageSettingsGroupBoxResultsLabelSharesDelimeter.BackColor = "Transparent"
			$objTabPageSettingsGroupBoxResults.Controls.Add($objTabPageSettingsGroupBoxResultsLabelSharesDelimeter)
			$objTabPageSettingsGroupBoxResultsTextBoxSharesGood = New-Object System.Windows.Forms.TextBox
			$objTabPageSettingsGroupBoxResultsTextBoxSharesGood.Location = New-Object System.Drawing.Point(340,20)
			$objTabPageSettingsGroupBoxResultsTextBoxSharesGood.Size = New-Object System.Drawing.Size(40,20)
			$objTabPageSettingsGroupBoxResultsTextBoxSharesGood.Cursor = [System.Windows.Forms.Cursors]::Default
			$objTabPageSettingsGroupBoxResultsTextBoxSharesGood.ReadOnly = $True
			$objTabPageSettingsGroupBoxResultsTextBoxSharesGood.TextAlign = "Center";
			$objTabPageSettingsGroupBoxResultsTextBoxSharesGood.Text = ""
			$objTabPageSettingsGroupBoxResults.Controls.Add($objTabPageSettingsGroupBoxResultsTextBoxSharesGood)

			$objTabPageSettingsGroupBoxResultsLabelTime = New-Object System.Windows.Forms.Label
			$objTabPageSettingsGroupBoxResultsLabelTime.Location = New-Object System.Drawing.Size(390,20)
			$objTabPageSettingsGroupBoxResultsLabelTime.Size = New-Object System.Drawing.Size(45,20)
			$objTabPageSettingsGroupBoxResultsLabelTime.Text = "Time:"
			$objTabPageSettingsGroupBoxResultsLabelTime.Font = New-Object System.Drawing.Font("Times New Roman",11,[System.Drawing.FontStyle]::Regular)
			$objTabPageSettingsGroupBoxResultsLabelTime.BackColor = "Transparent"
			$objTabPageSettingsGroupBoxResults.Controls.Add($objTabPageSettingsGroupBoxResultsLabelTime)
			$objTabPageSettingsGroupBoxResultsTextBoxTime = New-Object System.Windows.Forms.TextBox
			$objTabPageSettingsGroupBoxResultsTextBoxTime.Location = New-Object System.Drawing.Point(435,20)
			$objTabPageSettingsGroupBoxResultsTextBoxTime.Size = New-Object System.Drawing.Size(40,20)
			$objTabPageSettingsGroupBoxResultsTextBoxTime.Cursor = [System.Windows.Forms.Cursors]::Default
			$objTabPageSettingsGroupBoxResultsTextBoxTime.ReadOnly = $True
			$objTabPageSettingsGroupBoxResultsTextBoxTime.TextAlign = "Center";
			$objTabPageSettingsGroupBoxResultsTextBoxTime.Text = ""
			$objTabPageSettingsGroupBoxResults.Controls.Add($objTabPageSettingsGroupBoxResultsTextBoxTime)

			$objTabPageSettingsGroupBoxResultsLabelDifficulty = New-Object System.Windows.Forms.Label
			$objTabPageSettingsGroupBoxResultsLabelDifficulty.Location = New-Object System.Drawing.Size(485,20)
			$objTabPageSettingsGroupBoxResultsLabelDifficulty.Size = New-Object System.Drawing.Size(75,20)
			$objTabPageSettingsGroupBoxResultsLabelDifficulty.Text = "Difficulty:"
			$objTabPageSettingsGroupBoxResultsLabelDifficulty.Font = New-Object System.Drawing.Font("Times New Roman",11,[System.Drawing.FontStyle]::Regular)
			$objTabPageSettingsGroupBoxResultsLabelDifficulty.BackColor = "Transparent"
			$objTabPageSettingsGroupBoxResults.Controls.Add($objTabPageSettingsGroupBoxResultsLabelDifficulty)
			$objTabPageSettingsGroupBoxResultsTextBoxDifficulty = New-Object System.Windows.Forms.TextBox
			$objTabPageSettingsGroupBoxResultsTextBoxDifficulty.Location = New-Object System.Drawing.Point(560,20)
			$objTabPageSettingsGroupBoxResultsTextBoxDifficulty.Size = New-Object System.Drawing.Size(60,20)
			$objTabPageSettingsGroupBoxResultsTextBoxDifficulty.Cursor = [System.Windows.Forms.Cursors]::Default
			$objTabPageSettingsGroupBoxResultsTextBoxDifficulty.ReadOnly = $True
			$objTabPageSettingsGroupBoxResultsTextBoxDifficulty.TextAlign = "Center";
			$objTabPageSettingsGroupBoxResultsTextBoxDifficulty.Text = ""
			$objTabPageSettingsGroupBoxResults.Controls.Add($objTabPageSettingsGroupBoxResultsTextBoxDifficulty)

			$objTabPageSettingsGroupBoxResultsTop10Shares = New-Object System.Windows.Forms.GroupBox
			$objTabPageSettingsGroupBoxResultsTop10Shares.Location = New-Object System.Drawing.Point(5,45)
			$objTabPageSettingsGroupBoxResultsTop10Shares.Size = New-Object System.Drawing.Size(615,60)
			$objTabPageSettingsGroupBoxResultsTop10Shares.Font = New-Object System.Drawing.Font("Times New Roman",10,[System.Drawing.FontStyle]::Regular)
			$objTabPageSettingsGroupBoxResultsTop10Shares.Text = "Top 10 Shares:"

				$objTabPageSettingsGroupBoxResultsListViewTop10Shares = New-Object System.Windows.Forms.ListView
				$objTabPageSettingsGroupBoxResultsListViewTop10Shares.Location = New-Object System.Drawing.Point(5,15)
				$objTabPageSettingsGroupBoxResultsListViewTop10Shares.Size = New-Object System.Drawing.Size(610,45)
				$objTabPageSettingsGroupBoxResultsListViewTop10Shares.View = [System.Windows.Forms.View]::Details
				$objTabPageSettingsGroupBoxResultsListViewTop10Shares.Width = $objTabPageSettingsGroupBoxResultsListViewTop10Shares.ClientRectangle.Width
				$objTabPageSettingsGroupBoxResultsListViewTop10Shares.Height = $objTabPageSettingsGroupBoxResultsListViewTop10Shares.ClientRectangle.Height
				$objTabPageSettingsGroupBoxResultsListViewTop10Shares.Anchor = "Top, Left, Right, Bottom"
				$objTabPageSettingsGroupBoxResultsListViewTop10Shares.Columns.Add("0", 0) | Out-Null
				$objTabPageSettingsGroupBoxResultsListViewTop10Shares.Columns.Add("1", 60, "Center") | Out-Null
				$objTabPageSettingsGroupBoxResultsListViewTop10Shares.Columns.Add("2", 60, "Center") | Out-Null
				$objTabPageSettingsGroupBoxResultsListViewTop10Shares.Columns.Add("3", 60, "Center") | Out-Null
				$objTabPageSettingsGroupBoxResultsListViewTop10Shares.Columns.Add("4", 60, "Center") | Out-Null
				$objTabPageSettingsGroupBoxResultsListViewTop10Shares.Columns.Add("5", 60, "Center") | Out-Null
				$objTabPageSettingsGroupBoxResultsListViewTop10Shares.Columns.Add("6", 60, "Center") | Out-Null
				$objTabPageSettingsGroupBoxResultsListViewTop10Shares.Columns.Add("7", 60, "Center") | Out-Null
				$objTabPageSettingsGroupBoxResultsListViewTop10Shares.Columns.Add("8", 60, "Center") | Out-Null
				$objTabPageSettingsGroupBoxResultsListViewTop10Shares.Columns.Add("9", 60, "Center") | Out-Null
				$objTabPageSettingsGroupBoxResultsListViewTop10Shares.Columns.Add("10", 60, "Center") | Out-Null
				$objTabPageSettingsGroupBoxResultsTop10Shares.Controls.Add($objTabPageSettingsGroupBoxResultsListViewTop10Shares)

			$objTabPageSettingsGroupBoxResults.Controls.Add($objTabPageSettingsGroupBoxResultsTop10Shares)

			$objTabPageSettingsGroupBoxResultsErrorLog = New-Object System.Windows.Forms.GroupBox
			$objTabPageSettingsGroupBoxResultsErrorLog.Location = New-Object System.Drawing.Point(5,105)
			$objTabPageSettingsGroupBoxResultsErrorLog.Size = New-Object System.Drawing.Size(615,100)
			$objTabPageSettingsGroupBoxResultsErrorLog.Font = New-Object System.Drawing.Font("Times New Roman",10,[System.Drawing.FontStyle]::Regular)
			$objTabPageSettingsGroupBoxResultsErrorLog.Visible = $Script:FormFieldResultsErrorLogVisible
			$objTabPageSettingsGroupBoxResultsErrorLog.Text = "Error log:"

				$objTabPageSettingsGroupBoxResultsListBoxErrorLog = New-Object System.Windows.Forms.ListBox
				$objTabPageSettingsGroupBoxResultsListBoxErrorLog.Location = New-Object System.Drawing.Point(5,15)
				$objTabPageSettingsGroupBoxResultsListBoxErrorLog.Size = New-Object System.Drawing.Size(605,80)
				$objTabPageSettingsGroupBoxResultsErrorLog.Controls.Add($objTabPageSettingsGroupBoxResultsListBoxErrorLog)

			$objTabPageSettingsGroupBoxResults.Controls.Add($objTabPageSettingsGroupBoxResultsErrorLog)

		$objTabPageMonitor.Controls.Add($objTabPageSettingsGroupBoxResults)

	$objTabControl.Controls.Add($objTabPageMonitor)

	$objTabPageOptions = New-Object System.Windows.Forms.TabPage
	$objTabPageOptions.TabIndex = 1
	$objTabPageOptions.Location = New-Object System.Drawing.Point($FormDimensions["objTabPageOptionsHorizontalPosition"],$FormDimensions["objTabPageOptionsVerticalPosition"])
	$objTabPageOptions.Size = New-Object System.Drawing.Size($FormDimensions["objTabPageOptionsWidth"],$FormDimensions["objTabPageOptionsHeight"])
	$objTabPageOptions.Padding = "0, 0, 0, 0"
	$objTabPageOptions.Text = "Options"
	$objTabControl.Controls.Add($objTabPageOptions)

	$objTabPageSettings = New-Object System.Windows.Forms.TabPage
	$objTabPageSettings.TabIndex = 2
	$objTabPageSettings.Location = New-Object System.Drawing.Point($FormDimensions["objTabPageSettingsHorizontalPosition"],$FormDimensions["objTabPageSettingsVerticalPosition"])
	$objTabPageSettings.Size = New-Object System.Drawing.Size($FormDimensions["objTabPageSettingsWidth"],$FormDimensions["objTabPageSettingsHeight"])
	$objTabPageSettings.Padding = "0, 0, 0, 0"
	$objTabPageSettings.Text = "Settings"

		$objTabPageSettingsGroupBoxUpdate = New-Object System.Windows.Forms.GroupBox
		$objTabPageSettingsGroupBoxUpdate.Location = New-Object System.Drawing.Point($FormDimensions["objTabPageSettingsUpdateHorizontalPosition"],$FormDimensions["objTabPageSettingsUpdateVerticalPosition"])
		$objTabPageSettingsGroupBoxUpdate.Size = New-Object System.Drawing.Size($FormDimensions["objTabPageSettingsUpdateWidth"],$FormDimensions["objTabPageSettingsUpdateHeight"])
		$objTabPageSettingsGroupBoxUpdate.Font = New-Object System.Drawing.Font("Times New Roman",10,[System.Drawing.FontStyle]::Regular)
		$objTabPageSettingsGroupBoxUpdate.Text = "Update every:"

			$objTabPageSettingsGroupBoxUpdateComboBoxDataSourceHours = New-Object System.Collections.Generic.List[System.Object]
			$objTabPageSettingsGroupBoxUpdateComboBoxDataSourceMinutes = New-Object System.Collections.Generic.List[System.Object]
			$objTabPageSettingsGroupBoxUpdateComboBoxDataSourceSeconds = New-Object System.Collections.Generic.List[System.Object]
			For ($i = 0; $i -le 59 ; $i++) {
				If ($i -le 23) {
					$objTabPageSettingsGroupBoxUpdateComboBoxDataSourceHours.Add($i.ToString("00.##"))
				}
				$objTabPageSettingsGroupBoxUpdateComboBoxDataSourceMinutes.Add($i.ToString("00.##"))
				$objTabPageSettingsGroupBoxUpdateComboBoxDataSourceSeconds.Add($i.ToString("00.##"))
			}

			$objTabPageSettingsGroupBoxUpdateLabelTimeLeft = New-Object System.Windows.Forms.Label
			$objTabPageSettingsGroupBoxUpdateLabelTimeLeft.Location = New-Object System.Drawing.Size(5,20)
			$objTabPageSettingsGroupBoxUpdateLabelTimeLeft.Size = New-Object System.Drawing.Size(100,20)
			$objTabPageSettingsGroupBoxUpdateLabelTimeLeft.Text = "Next refresh in:"
			$objTabPageSettingsGroupBoxUpdateLabelTimeLeft.Font = New-Object System.Drawing.Font("Times New Roman",11,[System.Drawing.FontStyle]::Regular)
			$objTabPageSettingsGroupBoxUpdateLabelTimeLeft.BackColor = "Transparent"
			$objTabPageSettingsGroupBoxUpdate.Controls.Add($objTabPageSettingsGroupBoxUpdateLabelTimeLeft)
			$objTabPageSettingsGroupBoxUpdateTextBoxTimeLeft = New-Object System.Windows.Forms.TextBox
			$objTabPageSettingsGroupBoxUpdateTextBoxTimeLeft.Location = New-Object System.Drawing.Point(110,20)
			$objTabPageSettingsGroupBoxUpdateTextBoxTimeLeft.Size = New-Object System.Drawing.Size(40,20)
			$objTabPageSettingsGroupBoxUpdateTextBoxTimeLeft.Cursor = [System.Windows.Forms.Cursors]::Default
			$objTabPageSettingsGroupBoxUpdateTextBoxTimeLeft.ReadOnly = $True
			$objTabPageSettingsGroupBoxUpdateTextBoxTimeLeft.TextAlign = "Center";
			$objTabPageSettingsGroupBoxUpdateTextBoxTimeLeft.Text = ""
			$objTabPageSettingsGroupBoxUpdate.Controls.Add($objTabPageSettingsGroupBoxUpdateTextBoxTimeLeft)
			$objTabPageSettingsGroupBoxUpdateLabelTimeLeftUnits = New-Object System.Windows.Forms.Label
			$objTabPageSettingsGroupBoxUpdateLabelTimeLeftUnits.Location = New-Object System.Drawing.Size(150,20)
			$objTabPageSettingsGroupBoxUpdateLabelTimeLeftUnits.Size = New-Object System.Drawing.Size(30,20)
			$objTabPageSettingsGroupBoxUpdateLabelTimeLeftUnits.Text = "[s]"
			$objTabPageSettingsGroupBoxUpdateLabelTimeLeftUnits.Font = New-Object System.Drawing.Font("Times New Roman",11,[System.Drawing.FontStyle]::Regular)
			$objTabPageSettingsGroupBoxUpdateLabelTimeLeftUnits.BackColor = "Transparent"
			$objTabPageSettingsGroupBoxUpdate.Controls.Add($objTabPageSettingsGroupBoxUpdateLabelTimeLeftUnits)

			$objTabPageSettingsGroupBoxUpdateLabelTimeLeftUnits = New-Object System.Windows.Forms.Label
			$objTabPageSettingsGroupBoxUpdateLabelTimeLeftUnits.Location = New-Object System.Drawing.Size(180,20)
			$objTabPageSettingsGroupBoxUpdateLabelTimeLeftUnits.Size = New-Object System.Drawing.Size(145,20)
			$objTabPageSettingsGroupBoxUpdateLabelTimeLeftUnits.Text = "Change refresh period:"
			$objTabPageSettingsGroupBoxUpdateLabelTimeLeftUnits.Font = New-Object System.Drawing.Font("Times New Roman",11,[System.Drawing.FontStyle]::Regular)
			$objTabPageSettingsGroupBoxUpdateLabelTimeLeftUnits.BackColor = "Transparent"
			$objTabPageSettingsGroupBoxUpdate.Controls.Add($objTabPageSettingsGroupBoxUpdateLabelTimeLeftUnits)

			$objTabPageSettingsGroupBoxUpdateComboBoxHours = New-Object System.Windows.Forms.ComboBox
			$objTabPageSettingsGroupBoxUpdateComboBoxHours.Name = "UpdateComboBoxHours"
			$objTabPageSettingsGroupBoxUpdateComboBoxHours.DataSource = $objTabPageSettingsGroupBoxUpdateComboBoxDataSourceHours
			$objTabPageSettingsGroupBoxUpdateComboBoxHours.Location = New-Object System.Drawing.Point(330,20)
			$objTabPageSettingsGroupBoxUpdateComboBoxHours.Size = New-Object System.Drawing.Size(40,20)
			$objTabPageSettingsGroupBoxUpdateComboBoxHours.Add_SelectedIndexChanged({RefreshInterval $objTabPageSettingsGroupBoxUpdateComboBoxHours.SelectedItem $objTabPageSettingsGroupBoxUpdateComboBoxMinutes.SelectedItem $objTabPageSettingsGroupBoxUpdateComboBoxSeconds.SelectedItem})
			$objTabPageSettingsGroupBoxUpdate.Controls.Add($objTabPageSettingsGroupBoxUpdateComboBoxHours)
			$objTabPageSettingsGroupBoxUpdateLabelHours = New-Object System.Windows.Forms.Label
			$objTabPageSettingsGroupBoxUpdateLabelHours.Location = New-Object System.Drawing.Size(370,20)
			$objTabPageSettingsGroupBoxUpdateLabelHours.Size = New-Object System.Drawing.Size(50,20)
			$objTabPageSettingsGroupBoxUpdateLabelHours.Text = "Hours"
			$objTabPageSettingsGroupBoxUpdateLabelHours.Font = New-Object System.Drawing.Font("Times New Roman",11,[System.Drawing.FontStyle]::Regular)
			$objTabPageSettingsGroupBoxUpdateLabelHours.BackColor = "Transparent"
			$objTabPageSettingsGroupBoxUpdate.Controls.Add($objTabPageSettingsGroupBoxUpdateLabelHours)

			$objTabPageSettingsGroupBoxUpdateComboBoxMinutes = New-Object System.Windows.Forms.ComboBox
			$objTabPageSettingsGroupBoxUpdateComboBoxMinutes.Name = "UpdateComboBoxMinutes"
			$objTabPageSettingsGroupBoxUpdateComboBoxMinutes.DataSource = $objTabPageSettingsGroupBoxUpdateComboBoxDataSourceMinutes
			$objTabPageSettingsGroupBoxUpdateComboBoxMinutes.Location = New-Object System.Drawing.Point(420,20)
			$objTabPageSettingsGroupBoxUpdateComboBoxMinutes.Size = New-Object System.Drawing.Size(40,20)
			$objTabPageSettingsGroupBoxUpdateComboBoxMinutes.Add_SelectedIndexChanged({RefreshInterval $objTabPageSettingsGroupBoxUpdateComboBoxHours.SelectedItem $objTabPageSettingsGroupBoxUpdateComboBoxMinutes.SelectedItem $objTabPageSettingsGroupBoxUpdateComboBoxSeconds.SelectedItem})
			$objTabPageSettingsGroupBoxUpdate.Controls.Add($objTabPageSettingsGroupBoxUpdateComboBoxMinutes)
			$objTabPageSettingsGroupBoxUpdateLabelMinutes = New-Object System.Windows.Forms.Label
			$objTabPageSettingsGroupBoxUpdateLabelMinutes.Location = New-Object System.Drawing.Size(460,20)
			$objTabPageSettingsGroupBoxUpdateLabelMinutes.Size = New-Object System.Drawing.Size(60,20)
			$objTabPageSettingsGroupBoxUpdateLabelMinutes.Text = "Minutes"
			$objTabPageSettingsGroupBoxUpdateLabelMinutes.Font = New-Object System.Drawing.Font("Times New Roman",11,[System.Drawing.FontStyle]::Regular)
			$objTabPageSettingsGroupBoxUpdateLabelMinutes.BackColor = "Transparent"
			$objTabPageSettingsGroupBoxUpdate.Controls.Add($objTabPageSettingsGroupBoxUpdateLabelMinutes)

			$objTabPageSettingsGroupBoxUpdateComboBoxSeconds = New-Object System.Windows.Forms.ComboBox
			$objTabPageSettingsGroupBoxUpdateComboBoxSeconds.Name = "UpdateComboBoxSeconds"
			$objTabPageSettingsGroupBoxUpdateComboBoxSeconds.DataSource = $objTabPageSettingsGroupBoxUpdateComboBoxDataSourceSeconds
			$objTabPageSettingsGroupBoxUpdateComboBoxSeconds.Location = New-Object System.Drawing.Point(520,20)
			$objTabPageSettingsGroupBoxUpdateComboBoxSeconds.Size = New-Object System.Drawing.Size(40,20)
			$objTabPageSettingsGroupBoxUpdateComboBoxSeconds.Add_SelectedIndexChanged({RefreshInterval $objTabPageSettingsGroupBoxUpdateComboBoxHours.SelectedItem $objTabPageSettingsGroupBoxUpdateComboBoxMinutes.SelectedItem $objTabPageSettingsGroupBoxUpdateComboBoxSeconds.SelectedItem})
			$objTabPageSettingsGroupBoxUpdate.Controls.Add($objTabPageSettingsGroupBoxUpdateComboBoxSeconds)
			$objTabPageSettingsGroupBoxUpdateLabelSeconds = New-Object System.Windows.Forms.Label
			$objTabPageSettingsGroupBoxUpdateLabelSeconds.Location = New-Object System.Drawing.Size(560,20)
			$objTabPageSettingsGroupBoxUpdateLabelSeconds.Size = New-Object System.Drawing.Size(60,20)
			$objTabPageSettingsGroupBoxUpdateLabelSeconds.Text = "Seconds"
			$objTabPageSettingsGroupBoxUpdateLabelSeconds.Font = New-Object System.Drawing.Font("Times New Roman",11,[System.Drawing.FontStyle]::Regular)
			$objTabPageSettingsGroupBoxUpdateLabelSeconds.BackColor = "Transparent"
			$objTabPageSettingsGroupBoxUpdate.Controls.Add($objTabPageSettingsGroupBoxUpdateLabelSeconds)

		$objTabPageSettings.Controls.Add($objTabPageSettingsGroupBoxUpdate)

		$objTabPageSettingsGroupBoxManualConnection = New-Object System.Windows.Forms.GroupBox
		$objTabPageSettingsGroupBoxManualConnection.Location = New-Object System.Drawing.Point($FormDimensions["objTabPageSettingsManualConnectionHorizontalPosition"],$FormDimensions["objTabPageSettingsManualConnectionVerticalPosition"])
		$objTabPageSettingsGroupBoxManualConnection.Size = New-Object System.Drawing.Size($FormDimensions["objTabPageSettingsManualConnectionWidth"],$FormDimensions["objTabPageSettingsManualConnectionHeight"])
		$objTabPageSettingsGroupBoxManualConnection.Font = New-Object System.Drawing.Font("Times New Roman",10,[System.Drawing.FontStyle]::Regular)
		$objTabPageSettingsGroupBoxManualConnection.Text = "Manual connection:"

			$objTabPageSettingsGroupBoxManualConnectionLabelAddress = New-Object System.Windows.Forms.Label
			$objTabPageSettingsGroupBoxManualConnectionLabelAddress.Location = New-Object System.Drawing.Size(5,20)
			$objTabPageSettingsGroupBoxManualConnectionLabelAddress.Size = New-Object System.Drawing.Size(60,20)
			$objTabPageSettingsGroupBoxManualConnectionLabelAddress.Text = "Address:"
			$objTabPageSettingsGroupBoxManualConnectionLabelAddress.Font = New-Object System.Drawing.Font("Times New Roman",11,[System.Drawing.FontStyle]::Regular)
			$objTabPageSettingsGroupBoxManualConnectionLabelAddress.BackColor = "Transparent"
			$objTabPageSettingsGroupBoxManualConnection.Controls.Add($objTabPageSettingsGroupBoxManualConnectionLabelAddress)
			$objTabPageSettingsGroupBoxManualConnectionTextBoxAddress = New-Object System.Windows.Forms.TextBox
			$objTabPageSettingsGroupBoxManualConnectionTextBoxAddress.Location = New-Object System.Drawing.Point(65,20)
			$objTabPageSettingsGroupBoxManualConnectionTextBoxAddress.Size = New-Object System.Drawing.Size(190,20)
			$objTabPageSettingsGroupBoxManualConnectionTextBoxAddress.ReadOnly = $False
			$objTabPageSettingsGroupBoxManualConnectionTextBoxAddress.TextAlign = "Left";
			$objTabPageSettingsGroupBoxManualConnectionTextBoxAddress.Text = ""
			$objTabPageSettingsGroupBoxManualConnection.Controls.Add($objTabPageSettingsGroupBoxManualConnectionTextBoxAddress)

			$objTabPageSettingsGroupBoxManualConnectionLabelPort = New-Object System.Windows.Forms.Label
			$objTabPageSettingsGroupBoxManualConnectionLabelPort.Location = New-Object System.Drawing.Size(275,20)
			$objTabPageSettingsGroupBoxManualConnectionLabelPort.Size = New-Object System.Drawing.Size(35,20)
			$objTabPageSettingsGroupBoxManualConnectionLabelPort.Text = "Port:"
			$objTabPageSettingsGroupBoxManualConnectionLabelPort.Font = New-Object System.Drawing.Font("Times New Roman",11,[System.Drawing.FontStyle]::Regular)
			$objTabPageSettingsGroupBoxManualConnectionLabelPort.BackColor = "Transparent"
			$objTabPageSettingsGroupBoxManualConnection.Controls.Add($objTabPageSettingsGroupBoxManualConnectionLabelPort)
			$objTabPageSettingsGroupBoxManualConnectionTextBoxPort = New-Object System.Windows.Forms.TextBox
			$objTabPageSettingsGroupBoxManualConnectionTextBoxPort.Location = New-Object System.Drawing.Point(310,20)
			$objTabPageSettingsGroupBoxManualConnectionTextBoxPort.Size = New-Object System.Drawing.Size(50,20)
			$objTabPageSettingsGroupBoxManualConnectionTextBoxPort.ReadOnly = $False
			$objTabPageSettingsGroupBoxManualConnectionTextBoxPort.TextAlign = "Left";
			$objTabPageSettingsGroupBoxManualConnectionTextBoxPort.Text = ""
			$objTabPageSettingsGroupBoxManualConnection.Controls.Add($objTabPageSettingsGroupBoxManualConnectionTextBoxPort)

			$objTabPageSettingsGroupBoxManualConnectionLabelProcess = New-Object System.Windows.Forms.Label
			$objTabPageSettingsGroupBoxManualConnectionLabelProcess.Location = New-Object System.Drawing.Size(380,20)
			$objTabPageSettingsGroupBoxManualConnectionLabelProcess.Size = New-Object System.Drawing.Size(60,20)
			$objTabPageSettingsGroupBoxManualConnectionLabelProcess.Text = "Process:"
			$objTabPageSettingsGroupBoxManualConnectionLabelProcess.Font = New-Object System.Drawing.Font("Times New Roman",11,[System.Drawing.FontStyle]::Regular)
			$objTabPageSettingsGroupBoxManualConnectionLabelProcess.BackColor = "Transparent"
			$objTabPageSettingsGroupBoxManualConnection.Controls.Add($objTabPageSettingsGroupBoxManualConnectionLabelProcess)
			$objTabPageSettingsGroupBoxManualConnectionTextBoxProcess = New-Object System.Windows.Forms.TextBox
			$objTabPageSettingsGroupBoxManualConnectionTextBoxProcess.Location = New-Object System.Drawing.Point(440,20)
			$objTabPageSettingsGroupBoxManualConnectionTextBoxProcess.Size = New-Object System.Drawing.Size(180,20)
			$objTabPageSettingsGroupBoxManualConnectionTextBoxProcess.ReadOnly = $False
			$objTabPageSettingsGroupBoxManualConnectionTextBoxProcess.TextAlign = "Left";
			$objTabPageSettingsGroupBoxManualConnectionTextBoxProcess.Text = ""
			$objTabPageSettingsGroupBoxManualConnection.Controls.Add($objTabPageSettingsGroupBoxManualConnectionTextBoxProcess)

			$objTabPageSettingsGroupBoxManualConnectionLabelToken = New-Object System.Windows.Forms.Label
			$objTabPageSettingsGroupBoxManualConnectionLabelToken.Location = New-Object System.Drawing.Size(5,45)
			$objTabPageSettingsGroupBoxManualConnectionLabelToken.Size = New-Object System.Drawing.Size(60,45)
			$objTabPageSettingsGroupBoxManualConnectionLabelToken.Text = "Token:"
			$objTabPageSettingsGroupBoxManualConnectionLabelToken.Font = New-Object System.Drawing.Font("Times New Roman",11,[System.Drawing.FontStyle]::Regular)
			$objTabPageSettingsGroupBoxManualConnectionLabelToken.BackColor = "Transparent"
			$objTabPageSettingsGroupBoxManualConnection.Controls.Add($objTabPageSettingsGroupBoxManualConnectionLabelToken)
			$objTabPageSettingsGroupBoxManualConnectionTextBoxToken = New-Object System.Windows.Forms.TextBox
			$objTabPageSettingsGroupBoxManualConnectionTextBoxToken.Location = New-Object System.Drawing.Point(65,45)
			$objTabPageSettingsGroupBoxManualConnectionTextBoxToken.Size = New-Object System.Drawing.Size(375,45)
			$objTabPageSettingsGroupBoxManualConnectionTextBoxToken.ReadOnly = $False
			$objTabPageSettingsGroupBoxManualConnectionTextBoxToken.TextAlign = "Left";
			$objTabPageSettingsGroupBoxManualConnectionTextBoxToken.Text = ""
			$objTabPageSettingsGroupBoxManualConnection.Controls.Add($objTabPageSettingsGroupBoxManualConnectionTextBoxToken)

			$objTabPageSettingsGroupBoxManualConnectionButtonApply = New-Object System.Windows.Forms.Button
			$objTabPageSettingsGroupBoxManualConnectionButtonApply.Location = New-Object System.Drawing.Point(450,45)
			$objTabPageSettingsGroupBoxManualConnectionButtonApply.Text = "Apply"
			$objTabPageSettingsGroupBoxManualConnectionButtonApply.Add_Click({
				$Script:AddressCurrent = $objTabPageSettingsGroupBoxManualConnectionTextBoxAddress.Text
				$Script:PortCurrent = $objTabPageSettingsGroupBoxManualConnectionTextBoxPort.Text
				$Script:ProcessCurrent = $objTabPageSettingsGroupBoxManualConnectionTextBoxProcess.Text
				$Script:TokenCurrent = $objTabPageSettingsGroupBoxManualConnectionTextBoxToken.Text
				$Script:TryToReconnect = $True
			})
			$objTabPageSettingsGroupBoxManualConnection.Controls.Add($objTabPageSettingsGroupBoxManualConnectionButtonApply)

			$objTabPageSettingsGroupBoxManualConnectionButtonReset = New-Object System.Windows.Forms.Button
			$objTabPageSettingsGroupBoxManualConnectionButtonReset.Location = New-Object System.Drawing.Point(540,45)
			$objTabPageSettingsGroupBoxManualConnectionButtonReset.Text = "Reset"
			$objTabPageSettingsGroupBoxManualConnectionButtonReset.Add_Click({
				$Script:AddressCurrent = $Script:AddressDefault
				$objTabPageSettingsGroupBoxManualConnectionTextBoxAddress.Text = $Script:AddressDefault
				$Script:PortCurrent = $Script:PortDefault
				$objTabPageSettingsGroupBoxManualConnectionTextBoxPort.Text = $Script:PortDefault
				$Script:ProcessCurrent = $Script:ProcessDefault
				$objTabPageSettingsGroupBoxManualConnectionTextBoxProcess.Text = $Script:ProcessDefault
				$Script:TokenCurrent = $Script:TokenDefault
				$objTabPageSettingsGroupBoxManualConnectionTextBoxToken.Text = $Script:TokenDefault
				$Script:TryToReconnect = $True
			})
			$objTabPageSettingsGroupBoxManualConnection.Controls.Add($objTabPageSettingsGroupBoxManualConnectionButtonReset)

		$objTabPageSettings.Controls.Add($objTabPageSettingsGroupBoxManualConnection)

	$objTabControl.Controls.Add($objTabPageSettings)

	$objForm.Controls.Add($objTabControl)

	TabControl $objTabControl @($objTabPageMonitor, $objTabPageOptions) $False
#	$objTabControl.SelectedIndex = 2

	$objForm.KeyPreview = $True
# Close form on "ESC" button:
	$objForm.Add_KeyDown({If ($_.KeyCode -eq "Escape") {$objForm.Close()}})
# Form is always on top:
#	$objForm.Topmost = $False

	$objTimer.Start()
	$objForm.Add_Load({
		RefreshInterval ("{0:HH}" -f ([datetime]([timespan]::FromSeconds($Script:RefreshInterval)).Ticks)) ("{0:mm}" -f ([datetime]([timespan]::FromSeconds($Script:RefreshInterval)).Ticks)) ("{0:ss}" -f ([datetime]([timespan]::FromSeconds($Script:RefreshInterval)).Ticks))
#		$objTabPageSettingsGroupBoxUpdateComboBoxHours.SelectedIndex = $objTabPageSettingsGroupBoxUpdateComboBoxHours.Items.IndexOf("{0:HH}" -f ([datetime]([timespan]::FromSeconds($Script:RefreshInterval)).Ticks))
#		$objTabPageSettingsGroupBoxUpdateComboBoxMinutes.SelectedIndex = $objTabPageSettingsGroupBoxUpdateComboBoxMinutes.Items.IndexOf("{0:mm}" -f ([datetime]([timespan]::FromSeconds($Script:RefreshInterval)).Ticks))
#		$objTabPageSettingsGroupBoxUpdateComboBoxSeconds.SelectedIndex = $objTabPageSettingsGroupBoxUpdateComboBoxSeconds.Items.IndexOf("{0:ss}" -f ([datetime]([timespan]::FromSeconds($Script:RefreshInterval)).Ticks))
		$objTabPageSettingsGroupBoxManualConnectionTextBoxAddress.Text = $address
		$objTabPageSettingsGroupBoxManualConnectionTextBoxPort.Text = $port
		$objTabPageSettingsGroupBoxManualConnectionTextBoxProcess.Text = $process
		$objTabPageSettingsGroupBoxManualConnectionTextBoxToken.Text = $token
#		$objTimer.Enabled = $True
#[System.Windows.Forms.MessageBox]::Show("SelectedIndex: " + $objTabControl.SelectedIndex)
	})
	$objForm.Add_Shown({$objForm.Activate()})

#	$objTabControl.Add_SelectedIndexChanged({[System.Windows.Forms.MessageBox]::Show("Index: " + ($objTabControl.SelectedTab).TabIndex + "; Text: " + ($objTabControl.SelectedTab).Text)})
#	Start-Sleep -s 1
	$objForm.ShowDialog() | Out-Null
#	$objArray = $objForm.ShowDialog()
	$objTimer.Stop()
	$objForm.Close()

#	Return $objArray
}

Show_Dialog $address $port $token $process $refresh
