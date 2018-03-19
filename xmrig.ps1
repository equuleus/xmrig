PARAM (
	[string]$address = $(Read-Host "Input address, please: "),
	[string]$port = $(Read-Host "Input port, please: "),
	[string]$process = $(Read-Host "Input process name, please: "),
	[string]$refresh
)
Set-ExecutionPolicy Unrestricted -Scope CurrentUser -Force

Function API_Get ($address, $port) {
	$URI		= "http://" + $address + ":" + $port
	$Method		= "GET"
	$Headers	= @{
		"Content-type" = "Application/json"
	}
	$ContentType	= "Application/json"
	Try {
		$WebRequest = Invoke-WebRequest -Uri $URI -Method $Method -Headers $Headers -ContentType $ContentType -TimeoutSec 10
	} Catch {
		$_.Exception.Response
	} Finally {
		If ($WebRequest -ne $null) {
			$Content = $WebRequest.Content | ConvertFrom-JSON
		}
	}
	Return $Content
}

Function RefreshInterval ($hours, $minutes, $seconds) {
	$objGroupBoxUpdateComboBoxHours.SelectedIndex = $objGroupBoxUpdateComboBoxHours.Items.IndexOf($hours)
	$objGroupBoxUpdateComboBoxMinutes.SelectedIndex = $objGroupBoxUpdateComboBoxMinutes.Items.IndexOf($minutes)
	$objGroupBoxUpdateComboBoxSeconds.SelectedIndex = $objGroupBoxUpdateComboBoxSeconds.Items.IndexOf($seconds)
	$Script:RefreshInterval = ([timespan]($hours.ToString() + ":" + $minutes.ToString() + ":" + $seconds.ToString())).TotalSeconds
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

Function Show_Dialog ($address, $port, $process, $refresh) {

	$Script:RefreshInterval = [int]$refresh
	If ($Script:RefreshInterval -le 0) {
		$Script:RefreshInterval = 1
	}

	$Content = API_Get $address $port
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

	[int]$objFormHorizontalPosition = 0
	[int]$objFormVerticalPosition = 0
	[int]$objFormHorizontalBorder = 25
	[int]$objFormVerticalBorder = 50

	$objFormInformationHorizontalPosition = $objFormHorizontalPosition + 5
	$objFormInformationVerticalPosition = $objFormVerticalPosition + 5
	$objFormInformationWidth = 500
	$objFormInformationHeight = 155

	$objFormUpdateHorizontalPosition = 510
	$objFormUpdateVerticalPosition = $objFormVerticalPosition + 5
	$objFormUpdateWidth = 120
	$objFormUpdateHeight = 155

	$objFormCPUHorizontalPosition = 5
	$objFormCPUVerticalPosition = $objFormInformationVerticalPosition + $objFormInformationHeight
	$objFormCPUWidth = 625
	$objFormCPUHeight = 55

	If ($Type -eq "NVIDIA") {
		$objFormNVIDIAHorizontalPosition = 5
		$objFormNVIDIAVerticalPosition = $objFormCPUVerticalPosition + $objFormCPUHeight
		$objFormNVIDIAWidth = 625
		$objFormNVIDIAHeight = 80
	} Else {
		$objFormNVIDIAHorizontalPosition = 5
		$objFormNVIDIAVerticalPosition = $objFormCPUVerticalPosition + $objFormCPUHeight
		$objFormNVIDIAWidth = 625
		$objFormNVIDIAHeight = 0
	}

	$objFormConnectionHorizontalPosition = 5
	$objFormConnectionVerticalPosition = $objFormNVIDIAVerticalPosition + $objFormNVIDIAHeight
	$objFormConnectionWidth = 625
	$objFormConnectionHeight = 50
	If ($Content.connection.error_log.Count -gt 0) {
		$FormFieldConnectionErrorLogVisible = $True
		$objFormConnectionHeight = $objFormConnectionHeight + 100
	} Else {
		$FormFieldConnectionErrorLogVisible = $False
	}

	$objFormHashrateHorizontalPosition = 5
	$objFormHashrateVerticalPosition = $objFormConnectionVerticalPosition + $objFormConnectionHeight
	$objFormHashrateWidth = 625
	$objFormHashrateHeight = 130

	$objFormResultsHorizontalPosition = 5
	$objFormResultsVerticalPosition = $objFormHashrateVerticalPosition + $objFormHashrateHeight
	$objFormResultsWidth = 625
	$objFormResultsHeight = 110
	If ($Content.results.error_log.Count -gt 0) {
		$FormFieldResultsErrorLogVisible = $True
		$objFormResultsHeight = $objFormResultsHeight + 100
	} Else {
		$FormFieldResultsErrorLogVisible = $False
	}

	$FormSizeX = $objFormResultsHorizontalPosition + $objFormResultsWidth + $objFormHorizontalBorder
	$FormSizeY = $objFormResultsVerticalPosition + $objFormResultsHeight + $objFormVerticalBorder

#	[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null
	Add-Type -AssemblyName System.Windows.Forms

#	$objArray = New-Object -TypeName PSCustomObject

	$ObjTimer = New-Object System.Windows.Forms.Timer
	$ObjTimer.Interval = 1000
	$ObjTimer.Add_Tick({
		If ($Script:RefreshTimeStart) {
			$RefreshTimeFinish = ($Script:RefreshTimeStart + (new-timespan -seconds $Script:RefreshInterval))
			$RefreshTimeLeft = ((New-TimeSpan -Start (get-date) -End $RefreshTimeFinish).TotalSeconds).ToString("#.")
			If (($RefreshTimeLeft -lt 1) -or ([math]::Sign($RefreshTimeLeft) -eq -1)) {
				$RefreshReload = $True
				$RefreshTimeLeft = 0
			} Else {
				$RefreshReload = $False
			}
		} Else {
			$RefreshReload = $True
			$RefreshTimeLeft = 0
		}
		$objGroupBoxUpdateTextBoxTimeLeft.text = $RefreshTimeLeft
		$ToolTip.SetToolTip($objGroupBoxUpdateTextBoxTimeLeft, "Time until next refresh: " + ("{0:HH:mm:ss}" -f ([datetime]([timespan]::FromSeconds($RefreshTimeLeft)).Ticks)))

		If ($RefreshReload -eq $True) {
			$Script:RefreshTimeStart = (get-date)
			$Content = API_Get $address $port
			If ($Content -ne $null) {
				$objGroupBoxInformationLabelUA.Text = $Content.ua

				$objGroupBoxInformationTextBoxWorkerID.Text = $Content.worker_id
				$objGroupBoxInformationTextBoxID.Text = $Content.id

				$objGroupBoxInformationTextBoxVersion.Text = $Content.version
				$objGroupBoxInformationTextBoxDonateLevel.Text = $Content.donate_level

				$objGroupBoxInformationTextBoxKind.Text = $Content.kind
				If ($Content.hugepages -eq "true") {
					$objGroupBoxInformationCheckBoxHugepages.Checked = $True
					$objGroupBoxInformationCheckBoxHugepages.Text = "Available"
				} Else {
					$objGroupBoxInformationCheckBoxHugepages.Checked = $False
					$objGroupBoxInformationCheckBoxHugepages.Text = "Not available"
				}
				$objGroupBoxInformationTextBoxAlgo.Text = $Content.algo

				$objGroupBoxCPUTextBoxBrand.Text = $Content.cpu.brand
				If ($Content.cpu.aes -eq "true") {
					$objGroupBoxCPUCheckBoxAES.Checked = $True
				} Else {
					$objGroupBoxCPUCheckBoxAES.Checked = $False
				}
				If ($Content.cpu.x64 -eq "true") {
					$objGroupBoxCPUCheckBoxX64.Checked = $True
				} Else {
					$objGroupBoxCPUCheckBoxX64.Checked = $False
				}
				$objGroupBoxCPUTextBoxSockets.Text = $Content.cpu.sockets

				If ($Content.kind -eq "nvidia") {
					$objGroupBoxNVIDIATextBoxName.Text = $Content.health.name
					$objGroupBoxNVIDIATextBoxGPU.Text = $Content.health.clock
					$objGroupBoxNVIDIATextBoxMemory.Text = $Content.health.mem_clock
					$objGroupBoxNVIDIATextBoxPower.Text = $Content.health.power
					$objGroupBoxNVIDIATextBoxTemperature.Text = $Content.health.temp
					$objGroupBoxNVIDIATextBoxFan.Text = $Content.health.fan
				}

				$objGroupBoxConnectionTextBoxPool.Text = $Content.connection.pool
				$objGroupBoxConnectionTextBoxPing.Text = $Content.connection.ping
				$objGroupBoxConnectionTextBoxUptime.Text = $Content.connection.uptime
				$ToolTip.SetToolTip($objGroupBoxConnectionTextBoxUptime, ("{0:dd,HH:mm:ss}" -f ([datetime]([timespan]::FromSeconds($Content.connection.uptime)).Ticks)))
				$objGroupBoxConnectionTextBoxFailures.Text = $Content.connection.failures
				$objGroupBoxConnectionListBoxErrorLog.Items.Clear()
				If ($Content.connection.error_log.Count -gt 0) {
					If ($objGroupBoxConnectionErrorLog.Visible -eq $False) {
						$objForm.Size = "" + $objForm.Size.Width + ", " + ($objForm.Size.Height + 100) + ""
						$objGroupBoxConnection.Size = "" + $objFormConnectionWidth + ", " + ($objFormConnectionHeight + 100) + ""
						$objGroupBoxHashrate.Location = "" + $objFormHashrateHorizontalPosition + ", " + ($objFormHashrateVerticalPosition + 100) + ""
						$objGroupBoxResults.Location = "" + $objFormResultsHorizontalPosition + ", " + ($objFormResultsVerticalPosition + 100) + ""
						$objGroupBoxConnectionErrorLog.Visible = $True
					}
					ForEach ($error_log in $Content.connection.error_log) {
						$objGroupBoxConnectionListBoxErrorLog.Items.Add($error_log) | Out-Null
					}
				}

				$objGroupBoxHashrateTextBoxTotal1.Text = $Content.hashrate.total[0]
				$ToolTip.SetToolTip($objGroupBoxHashrateTextBoxTotal1, ($Content.hashrate.total[0].ToString() + " hashes per second in a last 2,5 seconds"))
				$objGroupBoxHashrateTextBoxTotal2.Text = $Content.hashrate.total[1]
				$ToolTip.SetToolTip($objGroupBoxHashrateTextBoxTotal2, ($Content.hashrate.total[1].ToString() + " hashes per second in a last 60 seconds"))
				$objGroupBoxHashrateTextBoxTotal3.Text = $Content.hashrate.total[2]
				$ToolTip.SetToolTip($objGroupBoxHashrateTextBoxTotal3, ($Content.hashrate.total[2].ToString() + " hashes per second in a last 15 minutes"))
				$objGroupBoxHashrateTextBoxHighest.Text = $Content.hashrate.highest
				$ToolTip.SetToolTip($objGroupBoxHashrateTextBoxHighest, ($Content.hashrate.highest.ToString() + " hashes per second is a highest value since start"))
				$objGroupBoxHashrateListViewThreads.Items.Clear()
				$i = 0
				ForEach ($thread in $Content.hashrate.threads) {
					$i = $i + 1
					$ListViewItem = New-Object System.Windows.Forms.ListViewItem($i)
					$ListViewItem.Subitems.Add($thread[0].ToString()) | Out-Null
					$ListViewItem.Subitems.Add($thread[1].ToString()) | Out-Null
					$ListViewItem.Subitems.Add($thread[2].ToString()) | Out-Null
					$objGroupBoxHashrateListViewThreads.Items.Add($ListViewItem) | Out-Null
				}

				$objGroupBoxResultsTextBoxHashes.Text = $Content.results.hashes_total
				$ToolTip.SetToolTip($objGroupBoxResultsTextBoxHashes, ($Content.results.hashes_total.ToString() + " total hashes found"))
				$objGroupBoxResultsTextBoxSharesTotal.Text = $Content.results.shares_total
				$ToolTip.SetToolTip($objGroupBoxResultsTextBoxSharesTotal, ($Content.results.shares_total.ToString() + " total shares found"))
				$objGroupBoxResultsTextBoxSharesGood.Text = $Content.results.shares_good
				$ToolTip.SetToolTip($objGroupBoxResultsTextBoxSharesGood, ($Content.results.shares_good.ToString() + " good shares found"))
				$objGroupBoxResultsTextBoxTime.Text = $Content.results.avg_time
				$ToolTip.SetToolTip($objGroupBoxResultsTextBoxTime, ($Content.results.avg_time.ToString() + " seconds (" + ("{0:HH:mm:ss}" -f ([datetime]([timespan]::FromSeconds($Content.results.avg_time)).Ticks)) + ") - average time to find a share"))
				$objGroupBoxResultsTextBoxDifficulty.Text = $Content.results.diff_current
				$ToolTip.SetToolTip($objGroupBoxResultsTextBoxDifficulty, ($Content.results.diff_current.ToString() + " current difficulty for worker"))
				$objGroupBoxResultsListViewTop10Shares.Items.Clear()
				$ListViewItem = New-Object System.Windows.Forms.ListViewItem(0)
				ForEach ($result in $Content.results.best) {
					$ListViewItem.Subitems.Add($result.ToString()) | Out-Null
				}
				$objGroupBoxResultsListViewTop10Shares.Items.Add($ListViewItem) | Out-Null

				$objGroupBoxResultsListBoxErrorLog.Items.Clear()
				If ($Content.results.error_log.Count -gt 0) {
					If ($objGroupBoxResultsErrorLog.Visible -eq $False) {
						$objForm.Size = "" + $objForm.Size.Width + ", " + ($objForm.Size.Height + 100) + ""
						$objGroupBoxResults.Size = "" + $objFormResultsWidth + ", " + ($objFormResultsHeight + 100) + ""
						$objGroupBoxResultsErrorLog.Visible = $True
					}
					ForEach ($error_log in $Content.connection.error_log) {
						$objGroupBoxConnectionListBoxErrorLog.Items.Add($error_log) | Out-Null
					}
				}

				ForEach ($error_log in $Content.results.error_log) {
					$objGroupBoxResultsListBoxErrorLog.Items.Add($error_log) | Out-Null
				}

				$objForm.Refresh()
			} Else {
				$ObjTimer.Stop()
				[System.Windows.Forms.MessageBox]::Show("ERROR: Can not get content from`r`n`r`nIP: $address`r`n`r`nPORT: $port", "XMRig API Monitor", 0, [System.Windows.Forms.MessageBoxIcon]::Error) | out-null
				$objForm.Close()
			}
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
	$objForm.Size = New-Object System.Drawing.Size($FormSizeX,$FormSizeY)
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

	$objGroupBoxInformation = New-Object System.Windows.Forms.GroupBox
	$objGroupBoxInformation.Location = New-Object System.Drawing.Point($objFormInformationHorizontalPosition,$objFormInformationVerticalPosition)
	$objGroupBoxInformation.Size = New-Object System.Drawing.Size($objFormInformationWidth,$objFormInformationHeight)
	$objGroupBoxInformation.Font = New-Object System.Drawing.Font("Times New Roman",10,[System.Drawing.FontStyle]::Regular)
	$objGroupBoxInformation.Text = "Information:"
#	$objGroupBoxInformation.AutoSize = $true

		$objGroupBoxInformationLabelUA = New-Object System.Windows.Forms.Label
		$objGroupBoxInformationLabelUA.Location = New-Object System.Drawing.Size(5,20)
		$objGroupBoxInformationLabelUA.Size = New-Object System.Drawing.Size(490,20)
		$objGroupBoxInformationLabelUA.Text = ""
		$objGroupBoxInformationLabelUA.Font = New-Object System.Drawing.Font("Times New Roman",10,[System.Drawing.FontStyle]::Bold)
		$objGroupBoxInformationLabelUA.BackColor = "Transparent"
		$objGroupBoxInformation.Controls.Add($objGroupBoxInformationLabelUA)

		$objGroupBoxInformationLabelWorkerID = New-Object System.Windows.Forms.Label
		$objGroupBoxInformationLabelWorkerID.Location = New-Object System.Drawing.Size(5,45)
		$objGroupBoxInformationLabelWorkerID.Size = New-Object System.Drawing.Size(80,20)
		$objGroupBoxInformationLabelWorkerID.Text = "Worker ID:"
		$objGroupBoxInformationLabelWorkerID.Font = New-Object System.Drawing.Font("Times New Roman",11,[System.Drawing.FontStyle]::Regular)
		$objGroupBoxInformationLabelWorkerID.BackColor = "Transparent"
		$objGroupBoxInformation.Controls.Add($objGroupBoxInformationLabelWorkerID)
		$objGroupBoxInformationTextBoxWorkerID = New-Object System.Windows.Forms.TextBox
		$objGroupBoxInformationTextBoxWorkerID.Location = New-Object System.Drawing.Point(85,45)
		$objGroupBoxInformationTextBoxWorkerID.Size = New-Object System.Drawing.Size(150,20)
		$objGroupBoxInformationTextBoxWorkerID.Cursor = [System.Windows.Forms.Cursors]::Default
		$objGroupBoxInformationTextBoxWorkerID.ReadOnly = $True
		$objGroupBoxInformationTextBoxWorkerID.Text = ""
		$objGroupBoxInformation.Controls.Add($objGroupBoxInformationTextBoxWorkerID)
		$objGroupBoxInformationLabelID = New-Object System.Windows.Forms.Label
		$objGroupBoxInformationLabelID.Location = New-Object System.Drawing.Size(260,45)
		$objGroupBoxInformationLabelID.Size = New-Object System.Drawing.Size(80,20)
		$objGroupBoxInformationLabelID.Text = "ID:"
		$objGroupBoxInformationLabelID.Font = New-Object System.Drawing.Font("Times New Roman",11,[System.Drawing.FontStyle]::Regular)
		$objGroupBoxInformationLabelID.BackColor = "Transparent"
		$objGroupBoxInformation.Controls.Add($objGroupBoxInformationLabelID)
		$objGroupBoxInformationTextBoxID = New-Object System.Windows.Forms.TextBox
		$objGroupBoxInformationTextBoxID.Location = New-Object System.Drawing.Point(340,45)
		$objGroupBoxInformationTextBoxID.Size = New-Object System.Drawing.Size(150,20)
		$objGroupBoxInformationTextBoxID.Cursor = [System.Windows.Forms.Cursors]::Default
		$objGroupBoxInformationTextBoxID.ReadOnly = $True
		$objGroupBoxInformationTextBoxID.Text = ""
		$objGroupBoxInformation.Controls.Add($objGroupBoxInformationTextBoxID)

		$objGroupBoxInformationLabelVersion = New-Object System.Windows.Forms.Label
		$objGroupBoxInformationLabelVersion.Location = New-Object System.Drawing.Size(5,70)
		$objGroupBoxInformationLabelVersion.Size = New-Object System.Drawing.Size(80,20)
		$objGroupBoxInformationLabelVersion.Text = "Version:"
		$objGroupBoxInformationLabelVersion.Font = New-Object System.Drawing.Font("Times New Roman",11,[System.Drawing.FontStyle]::Regular)
		$objGroupBoxInformationLabelVersion.BackColor = "Transparent"
		$objGroupBoxInformation.Controls.Add($objGroupBoxInformationLabelVersion)
		$objGroupBoxInformationTextBoxVersion = New-Object System.Windows.Forms.TextBox
		$objGroupBoxInformationTextBoxVersion.Location = New-Object System.Drawing.Point(85,70)
		$objGroupBoxInformationTextBoxVersion.Size = New-Object System.Drawing.Size(50,20)
		$objGroupBoxInformationTextBoxVersion.Cursor = [System.Windows.Forms.Cursors]::Default
		$objGroupBoxInformationTextBoxVersion.ReadOnly = $True
		$objGroupBoxInformationTextBoxVersion.Text = ""
		$objGroupBoxInformation.Controls.Add($objGroupBoxInformationTextBoxVersion)
		$objGroupBoxInformationLabelDonateLevel = New-Object System.Windows.Forms.Label
		$objGroupBoxInformationLabelDonateLevel.Location = New-Object System.Drawing.Size(260,70)
		$objGroupBoxInformationLabelDonateLevel.Size = New-Object System.Drawing.Size(80,20)
		$objGroupBoxInformationLabelDonateLevel.Text = "Donate:"
		$objGroupBoxInformationLabelDonateLevel.Font = New-Object System.Drawing.Font("Times New Roman",11,[System.Drawing.FontStyle]::Regular)
		$objGroupBoxInformationLabelDonateLevel.BackColor = "Transparent"
		$objGroupBoxInformation.Controls.Add($objGroupBoxInformationLabelDonateLevel)
		$objGroupBoxInformationTextBoxDonateLevel = New-Object System.Windows.Forms.TextBox
		$objGroupBoxInformationTextBoxDonateLevel.Location = New-Object System.Drawing.Point(340,70)
		$objGroupBoxInformationTextBoxDonateLevel.Size = New-Object System.Drawing.Size(30,20)
		$objGroupBoxInformationTextBoxDonateLevel.Cursor = [System.Windows.Forms.Cursors]::Default
		$objGroupBoxInformationTextBoxDonateLevel.ReadOnly = $True
		$objGroupBoxInformationTextBoxDonateLevel.TextAlign = "Center";
		$objGroupBoxInformationTextBoxDonateLevel.Text = ""
		$objGroupBoxInformation.Controls.Add($objGroupBoxInformationTextBoxDonateLevel)
		$objGroupBoxInformationLabelDonateLevelPercent = New-Object System.Windows.Forms.Label
		$objGroupBoxInformationLabelDonateLevelPercent.Location = New-Object System.Drawing.Size(370,70)
		$objGroupBoxInformationLabelDonateLevelPercent.Size = New-Object System.Drawing.Size(20,20)
		$objGroupBoxInformationLabelDonateLevelPercent.Text = "%"
		$objGroupBoxInformationLabelDonateLevelPercent.Font = New-Object System.Drawing.Font("Times New Roman",11,[System.Drawing.FontStyle]::Regular)
		$objGroupBoxInformationLabelDonateLevelPercent.BackColor = "Transparent"
		$objGroupBoxInformation.Controls.Add($objGroupBoxInformationLabelDonateLevelPercent)

		$objGroupBoxInformationLabelKind = New-Object System.Windows.Forms.Label
		$objGroupBoxInformationLabelKind.Location = New-Object System.Drawing.Size(5,95)
		$objGroupBoxInformationLabelKind.Size = New-Object System.Drawing.Size(80,20)
		$objGroupBoxInformationLabelKind.Text = "Type:"
		$objGroupBoxInformationLabelKind.Font = New-Object System.Drawing.Font("Times New Roman",11,[System.Drawing.FontStyle]::Regular)
		$objGroupBoxInformationLabelKind.BackColor = "Transparent"
		$objGroupBoxInformation.Controls.Add($objGroupBoxInformationLabelKind)
		$objGroupBoxInformationTextBoxKind = New-Object System.Windows.Forms.TextBox
		$objGroupBoxInformationTextBoxKind.Location = New-Object System.Drawing.Point(85,95)
		$objGroupBoxInformationTextBoxKind.Size = New-Object System.Drawing.Size(50,20)
		$objGroupBoxInformationTextBoxKind.Cursor = [System.Windows.Forms.Cursors]::Default
		$objGroupBoxInformationTextBoxKind.ReadOnly = $True
		$objGroupBoxInformationTextBoxKind.Text = ""
		$objGroupBoxInformation.Controls.Add($objGroupBoxInformationTextBoxKind)
		$objGroupBoxInformationLabelHugepages = New-Object System.Windows.Forms.Label
		$objGroupBoxInformationLabelHugepages.Location = New-Object System.Drawing.Size(260,95)
		$objGroupBoxInformationLabelHugepages.Size = New-Object System.Drawing.Size(80,20)
		$objGroupBoxInformationLabelHugepages.Text = "Hugepages:"
		$objGroupBoxInformationLabelHugepages.Font = New-Object System.Drawing.Font("Times New Roman",11,[System.Drawing.FontStyle]::Regular)
		$objGroupBoxInformationLabelHugepages.BackColor = "Transparent"
		$objGroupBoxInformation.Controls.Add($objGroupBoxInformationLabelHugepages)
		$objGroupBoxInformationCheckBoxHugepages = New-Object System.Windows.Forms.CheckBox
		$objGroupBoxInformationCheckBoxHugepages.Location = New-Object System.Drawing.Point(340,95)
#		$objGroupBoxInformationCheckBoxHugepages.Size = New-Object System.Drawing.Size(50,20)
		$objGroupBoxInformationCheckBoxHugepages.AutoSize = $True
		$objGroupBoxInformationCheckBoxHugepages.Checked = $False
		$objGroupBoxInformationCheckBoxHugepages.Enabled = $False
		$objGroupBoxInformationCheckBoxHugepages.Text = ""
		$objGroupBoxInformation.Controls.Add($objGroupBoxInformationCheckBoxHugepages)

		$objGroupBoxInformationLabelAlgo = New-Object System.Windows.Forms.Label
		$objGroupBoxInformationLabelAlgo.Location = New-Object System.Drawing.Size(5,120)
		$objGroupBoxInformationLabelAlgo.Size = New-Object System.Drawing.Size(80,20)
		$objGroupBoxInformationLabelAlgo.Text = "Algorytm:"
		$objGroupBoxInformationLabelAlgo.Font = New-Object System.Drawing.Font("Times New Roman",11,[System.Drawing.FontStyle]::Regular)
		$objGroupBoxInformationLabelAlgo.BackColor = "Transparent"
		$objGroupBoxInformation.Controls.Add($objGroupBoxInformationLabelAlgo)
		$objGroupBoxInformationTextBoxAlgo = New-Object System.Windows.Forms.TextBox
		$objGroupBoxInformationTextBoxAlgo.Location = New-Object System.Drawing.Point(85,120)
		$objGroupBoxInformationTextBoxAlgo.Size = New-Object System.Drawing.Size(150,20)
		$objGroupBoxInformationTextBoxAlgo.Cursor = [System.Windows.Forms.Cursors]::Default
		$objGroupBoxInformationTextBoxAlgo.ReadOnly = $True
		$objGroupBoxInformationTextBoxAlgo.Text = ""
		$objGroupBoxInformation.Controls.Add($objGroupBoxInformationTextBoxAlgo)

	$objForm.Controls.Add($objGroupBoxInformation)

	$objGroupBoxUpdate = New-Object System.Windows.Forms.GroupBox
	$objGroupBoxUpdate.Location = New-Object System.Drawing.Point($objFormUpdateHorizontalPosition,$objFormUpdateVerticalPosition)
	$objGroupBoxUpdate.Size = New-Object System.Drawing.Size($objFormUpdateWidth,$objFormUpdateHeight)
	$objGroupBoxUpdate.Font = New-Object System.Drawing.Font("Times New Roman",10,[System.Drawing.FontStyle]::Regular)
	$objGroupBoxUpdate.Text = "Update every:"

		$objGroupBoxUpdateComboBoxDataSourceHours = New-Object System.Collections.Generic.List[System.Object]
		$objGroupBoxUpdateComboBoxDataSourceMinutes = New-Object System.Collections.Generic.List[System.Object]
		$objGroupBoxUpdateComboBoxDataSourceSeconds = New-Object System.Collections.Generic.List[System.Object]
		For ($i = 0; $i -le 59 ; $i++) {
			If ($i -le 23) {
				$objGroupBoxUpdateComboBoxDataSourceHours.Add($i.ToString("00.##"))
			}
			$objGroupBoxUpdateComboBoxDataSourceMinutes.Add($i.ToString("00.##"))
			$objGroupBoxUpdateComboBoxDataSourceSeconds.Add($i.ToString("00.##"))
		}

		$objGroupBoxUpdateComboBoxHours = New-Object System.Windows.Forms.ComboBox
		$objGroupBoxUpdateComboBoxHours.Name = "UpdateComboBoxHours"
		$objGroupBoxUpdateComboBoxHours.DataSource = $objGroupBoxUpdateComboBoxDataSourceHours
		$objGroupBoxUpdateComboBoxHours.Location = New-Object System.Drawing.Point(10,25)
		$objGroupBoxUpdateComboBoxHours.Size = New-Object System.Drawing.Size(40,20)
		$objGroupBoxUpdateComboBoxHours.Add_SelectedIndexChanged({RefreshInterval $objGroupBoxUpdateComboBoxHours.SelectedItem $objGroupBoxUpdateComboBoxMinutes.SelectedItem $objGroupBoxUpdateComboBoxSeconds.SelectedItem})
		$objGroupBoxUpdate.Controls.Add($objGroupBoxUpdateComboBoxHours)
		$objGroupBoxUpdateLabelHours = New-Object System.Windows.Forms.Label
		$objGroupBoxUpdateLabelHours.Location = New-Object System.Drawing.Size(50,25)
		$objGroupBoxUpdateLabelHours.Size = New-Object System.Drawing.Size(60,20)
		$objGroupBoxUpdateLabelHours.Text = "Hours"
		$objGroupBoxUpdateLabelHours.Font = New-Object System.Drawing.Font("Times New Roman",11,[System.Drawing.FontStyle]::Regular)
		$objGroupBoxUpdateLabelHours.BackColor = "Transparent"
		$objGroupBoxUpdate.Controls.Add($objGroupBoxUpdateLabelHours)

		$objGroupBoxUpdateComboBoxMinutes = New-Object System.Windows.Forms.ComboBox
		$objGroupBoxUpdateComboBoxMinutes.Name = "UpdateComboBoxMinutes"
		$objGroupBoxUpdateComboBoxMinutes.DataSource = $objGroupBoxUpdateComboBoxDataSourceMinutes
		$objGroupBoxUpdateComboBoxMinutes.Location = New-Object System.Drawing.Point(10,50)
		$objGroupBoxUpdateComboBoxMinutes.Size = New-Object System.Drawing.Size(40,20)
		$objGroupBoxUpdateComboBoxMinutes.Add_SelectedIndexChanged({RefreshInterval $objGroupBoxUpdateComboBoxHours.SelectedItem $objGroupBoxUpdateComboBoxMinutes.SelectedItem $objGroupBoxUpdateComboBoxSeconds.SelectedItem})
		$objGroupBoxUpdate.Controls.Add($objGroupBoxUpdateComboBoxMinutes)
		$objGroupBoxUpdateLabelMinutes = New-Object System.Windows.Forms.Label
		$objGroupBoxUpdateLabelMinutes.Location = New-Object System.Drawing.Size(50,50)
		$objGroupBoxUpdateLabelMinutes.Size = New-Object System.Drawing.Size(60,20)
		$objGroupBoxUpdateLabelMinutes.Text = "Minutes"
		$objGroupBoxUpdateLabelMinutes.Font = New-Object System.Drawing.Font("Times New Roman",11,[System.Drawing.FontStyle]::Regular)
		$objGroupBoxUpdateLabelMinutes.BackColor = "Transparent"
		$objGroupBoxUpdate.Controls.Add($objGroupBoxUpdateLabelMinutes)

		$objGroupBoxUpdateComboBoxSeconds = New-Object System.Windows.Forms.ComboBox
		$objGroupBoxUpdateComboBoxSeconds.Name = "UpdateComboBoxSeconds"
		$objGroupBoxUpdateComboBoxSeconds.DataSource = $objGroupBoxUpdateComboBoxDataSourceSeconds
		$objGroupBoxUpdateComboBoxSeconds.Location = New-Object System.Drawing.Point(10,75)
		$objGroupBoxUpdateComboBoxSeconds.Size = New-Object System.Drawing.Size(40,20)
		$objGroupBoxUpdateComboBoxSeconds.Add_SelectedIndexChanged({RefreshInterval $objGroupBoxUpdateComboBoxHours.SelectedItem $objGroupBoxUpdateComboBoxMinutes.SelectedItem $objGroupBoxUpdateComboBoxSeconds.SelectedItem})
		$objGroupBoxUpdate.Controls.Add($objGroupBoxUpdateComboBoxSeconds)
		$objGroupBoxUpdateLabelSeconds = New-Object System.Windows.Forms.Label
		$objGroupBoxUpdateLabelSeconds.Location = New-Object System.Drawing.Size(50,75)
		$objGroupBoxUpdateLabelSeconds.Size = New-Object System.Drawing.Size(60,20)
		$objGroupBoxUpdateLabelSeconds.Text = "Seconds"
		$objGroupBoxUpdateLabelSeconds.Font = New-Object System.Drawing.Font("Times New Roman",11,[System.Drawing.FontStyle]::Regular)
		$objGroupBoxUpdateLabelSeconds.BackColor = "Transparent"
		$objGroupBoxUpdate.Controls.Add($objGroupBoxUpdateLabelSeconds)

		$objGroupBoxUpdateLabelTimeLeft = New-Object System.Windows.Forms.Label
		$objGroupBoxUpdateLabelTimeLeft.Location = New-Object System.Drawing.Size(10,100)
		$objGroupBoxUpdateLabelTimeLeft.Size = New-Object System.Drawing.Size(100,20)
		$objGroupBoxUpdateLabelTimeLeft.Text = "Next refresh in:"
		$objGroupBoxUpdateLabelTimeLeft.Font = New-Object System.Drawing.Font("Times New Roman",11,[System.Drawing.FontStyle]::Regular)
		$objGroupBoxUpdateLabelTimeLeft.BackColor = "Transparent"
		$objGroupBoxUpdate.Controls.Add($objGroupBoxUpdateLabelTimeLeft)
		$objGroupBoxUpdateTextBoxTimeLeft = New-Object System.Windows.Forms.TextBox
		$objGroupBoxUpdateTextBoxTimeLeft.Location = New-Object System.Drawing.Point(20,125)
		$objGroupBoxUpdateTextBoxTimeLeft.Size = New-Object System.Drawing.Size(60,20)
		$objGroupBoxUpdateTextBoxTimeLeft.Cursor = [System.Windows.Forms.Cursors]::Default
		$objGroupBoxUpdateTextBoxTimeLeft.ReadOnly = $True
		$objGroupBoxUpdateTextBoxTimeLeft.TextAlign = "Center";
		$objGroupBoxUpdateTextBoxTimeLeft.Text = ""
		$objGroupBoxUpdate.Controls.Add($objGroupBoxUpdateTextBoxTimeLeft)
		$objGroupBoxUpdateLabelTimeLeftUnits = New-Object System.Windows.Forms.Label
		$objGroupBoxUpdateLabelTimeLeftUnits.Location = New-Object System.Drawing.Size(80,125)
		$objGroupBoxUpdateLabelTimeLeftUnits.Size = New-Object System.Drawing.Size(30,20)
		$objGroupBoxUpdateLabelTimeLeftUnits.Text = "[s]"
		$objGroupBoxUpdateLabelTimeLeftUnits.Font = New-Object System.Drawing.Font("Times New Roman",11,[System.Drawing.FontStyle]::Regular)
		$objGroupBoxUpdateLabelTimeLeftUnits.BackColor = "Transparent"
		$objGroupBoxUpdate.Controls.Add($objGroupBoxUpdateLabelTimeLeftUnits)

	$objForm.Controls.Add($objGroupBoxUpdate)

	$objGroupBoxCPU = New-Object System.Windows.Forms.GroupBox
	$objGroupBoxCPU.Location = New-Object System.Drawing.Point($objFormCPUHorizontalPosition,$objFormCPUVerticalPosition)
	$objGroupBoxCPU.Size = New-Object System.Drawing.Size($objFormCPUWidth,$objFormCPUHeight)
	$objGroupBoxCPU.Font = New-Object System.Drawing.Font("Times New Roman",10,[System.Drawing.FontStyle]::Regular)
	$objGroupBoxCPU.Text = "CPU:"

		$objGroupBoxCPULabelBrand = New-Object System.Windows.Forms.Label
		$objGroupBoxCPULabelBrand.Location = New-Object System.Drawing.Size(5,20)
		$objGroupBoxCPULabelBrand.Size = New-Object System.Drawing.Size(50,20)
		$objGroupBoxCPULabelBrand.Text = "Brand:"
		$objGroupBoxCPULabelBrand.Font = New-Object System.Drawing.Font("Times New Roman",11,[System.Drawing.FontStyle]::Regular)
		$objGroupBoxCPULabelBrand.BackColor = "Transparent"
		$objGroupBoxCPU.Controls.Add($objGroupBoxCPULabelBrand)
		$objGroupBoxCPUTextBoxBrand = New-Object System.Windows.Forms.TextBox
		$objGroupBoxCPUTextBoxBrand.Location = New-Object System.Drawing.Point(55,20)
		$objGroupBoxCPUTextBoxBrand.Size = New-Object System.Drawing.Size(320,20)
		$objGroupBoxCPUTextBoxBrand.Cursor = [System.Windows.Forms.Cursors]::Default
		$objGroupBoxCPUTextBoxBrand.ReadOnly = $True
		$objGroupBoxCPUTextBoxBrand.Text = ""
		$objGroupBoxCPU.Controls.Add($objGroupBoxCPUTextBoxBrand)

		$objGroupBoxCPULabelAES = New-Object System.Windows.Forms.Label
		$objGroupBoxCPULabelAES.Location = New-Object System.Drawing.Size(390,20)
		$objGroupBoxCPULabelAES.Size = New-Object System.Drawing.Size(40,20)
		$objGroupBoxCPULabelAES.Text = "AES:"
		$objGroupBoxCPULabelAES.Font = New-Object System.Drawing.Font("Times New Roman",11,[System.Drawing.FontStyle]::Regular)
		$objGroupBoxCPULabelAES.BackColor = "Transparent"
		$objGroupBoxCPU.Controls.Add($objGroupBoxCPULabelAES)
		$objGroupBoxCPUCheckBoxAES = New-Object System.Windows.Forms.CheckBox
		$objGroupBoxCPUCheckBoxAES.Location = New-Object System.Drawing.Point(430,20)
		$objGroupBoxCPUCheckBoxAES.AutoSize = $True
		$objGroupBoxCPUCheckBoxAES.Checked = $False
		$objGroupBoxCPUCheckBoxAES.Enabled = $False
		$objGroupBoxCPU.Controls.Add($objGroupBoxCPUCheckBoxAES)

		$objGroupBoxCPULabelX64 = New-Object System.Windows.Forms.Label
		$objGroupBoxCPULabelX64.Location = New-Object System.Drawing.Size(460,20)
		$objGroupBoxCPULabelX64.Size = New-Object System.Drawing.Size(40,20)
		$objGroupBoxCPULabelX64.Text = "X64:"
		$objGroupBoxCPULabelX64.Font = New-Object System.Drawing.Font("Times New Roman",11,[System.Drawing.FontStyle]::Regular)
		$objGroupBoxCPULabelX64.BackColor = "Transparent"
		$objGroupBoxCPU.Controls.Add($objGroupBoxCPULabelX64)
		$objGroupBoxCPUCheckBoxX64 = New-Object System.Windows.Forms.CheckBox
		$objGroupBoxCPUCheckBoxX64.Location = New-Object System.Drawing.Point(500,20)
		$objGroupBoxCPUCheckBoxX64.AutoSize = $True
		$objGroupBoxCPUCheckBoxX64.Checked = $False
		$objGroupBoxCPUCheckBoxX64.Enabled = $False
		$objGroupBoxCPU.Controls.Add($objGroupBoxCPUCheckBoxX64)

		$objGroupBoxCPULabelSockets = New-Object System.Windows.Forms.Label
		$objGroupBoxCPULabelSockets.Location = New-Object System.Drawing.Size(530,20)
		$objGroupBoxCPULabelSockets.Size = New-Object System.Drawing.Size(60,20)
		$objGroupBoxCPULabelSockets.Text = "Sockets:"
		$objGroupBoxCPULabelSockets.Font = New-Object System.Drawing.Font("Times New Roman",11,[System.Drawing.FontStyle]::Regular)
		$objGroupBoxCPULabelSockets.BackColor = "Transparent"
		$objGroupBoxCPU.Controls.Add($objGroupBoxCPULabelSockets)
		$objGroupBoxCPUTextBoxSockets = New-Object System.Windows.Forms.TextBox
		$objGroupBoxCPUTextBoxSockets.Location = New-Object System.Drawing.Point(590,20)
		$objGroupBoxCPUTextBoxSockets.Size = New-Object System.Drawing.Size(30,20)
		$objGroupBoxCPUTextBoxSockets.Cursor = [System.Windows.Forms.Cursors]::Default
		$objGroupBoxCPUTextBoxSockets.ReadOnly = $True
		$objGroupBoxCPUTextBoxSockets.TextAlign = "Center";
		$objGroupBoxCPUTextBoxSockets.Text = ""
		$objGroupBoxCPU.Controls.Add($objGroupBoxCPUTextBoxSockets)

	$objForm.Controls.Add($objGroupBoxCPU)

	If ($Type -eq "NVIDIA") {

		$objGroupBoxNVIDIA = New-Object System.Windows.Forms.GroupBox
		$objGroupBoxNVIDIA.Location = New-Object System.Drawing.Point($objFormNVIDIAHorizontalPosition,$objFormNVIDIAVerticalPosition)
		$objGroupBoxNVIDIA.Size = New-Object System.Drawing.Size($objFormNVIDIAWidth,$objFormNVIDIAHeight)
		$objGroupBoxNVIDIA.Font = New-Object System.Drawing.Font("Times New Roman",10,[System.Drawing.FontStyle]::Regular)
		$objGroupBoxNVIDIA.Text = "NVIDIA:"

			$objGroupBoxNVIDIALabelName = New-Object System.Windows.Forms.Label
			$objGroupBoxNVIDIALabelName.Location = New-Object System.Drawing.Size(5,20)
			$objGroupBoxNVIDIALabelName.Size = New-Object System.Drawing.Size(50,20)
			$objGroupBoxNVIDIALabelName.Text = "Name:"
			$objGroupBoxNVIDIALabelName.Font = New-Object System.Drawing.Font("Times New Roman",11,[System.Drawing.FontStyle]::Regular)
			$objGroupBoxNVIDIALabelName.BackColor = "Transparent"
			$objGroupBoxNVIDIA.Controls.Add($objGroupBoxNVIDIALabelName)
			$objGroupBoxNVIDIATextBoxName = New-Object System.Windows.Forms.TextBox
			$objGroupBoxNVIDIATextBoxName.Location = New-Object System.Drawing.Point(55,20)
			$objGroupBoxNVIDIATextBoxName.Size = New-Object System.Drawing.Size(320,20)
			$objGroupBoxNVIDIATextBoxName.Cursor = [System.Windows.Forms.Cursors]::Default
			$objGroupBoxNVIDIATextBoxName.ReadOnly = $True
			$objGroupBoxNVIDIATextBoxName.Text = ""
			$objGroupBoxNVIDIA.Controls.Add($objGroupBoxNVIDIATextBoxName)

			$objGroupBoxNVIDIALabelGPU = New-Object System.Windows.Forms.Label
			$objGroupBoxNVIDIALabelGPU.Location = New-Object System.Drawing.Size(390,20)
			$objGroupBoxNVIDIALabelGPU.Size = New-Object System.Drawing.Size(40,20)
			$objGroupBoxNVIDIALabelGPU.Text = "GPU:"
			$objGroupBoxNVIDIALabelGPU.Font = New-Object System.Drawing.Font("Times New Roman",11,[System.Drawing.FontStyle]::Regular)
			$objGroupBoxNVIDIALabelGPU.BackColor = "Transparent"
			$objGroupBoxNVIDIA.Controls.Add($objGroupBoxNVIDIALabelGPU)
			$objGroupBoxNVIDIATextBoxGPU = New-Object System.Windows.Forms.TextBox
			$objGroupBoxNVIDIATextBoxGPU.Location = New-Object System.Drawing.Point(430,20)
			$objGroupBoxNVIDIATextBoxGPU.Size = New-Object System.Drawing.Size(50,20)
			$objGroupBoxNVIDIATextBoxGPU.Cursor = [System.Windows.Forms.Cursors]::Default
			$objGroupBoxNVIDIATextBoxGPU.ReadOnly = $True
			$objGroupBoxNVIDIATextBoxGPU.Text = ""
			$objGroupBoxNVIDIA.Controls.Add($objGroupBoxNVIDIATextBoxGPU)

			$objGroupBoxNVIDIALabelMemory = New-Object System.Windows.Forms.Label
			$objGroupBoxNVIDIALabelMemory.Location = New-Object System.Drawing.Size(505,20)
			$objGroupBoxNVIDIALabelMemory.Size = New-Object System.Drawing.Size(65,20)
			$objGroupBoxNVIDIALabelMemory.Text = "Memory:"
			$objGroupBoxNVIDIALabelMemory.Font = New-Object System.Drawing.Font("Times New Roman",11,[System.Drawing.FontStyle]::Regular)
			$objGroupBoxNVIDIALabelMemory.BackColor = "Transparent"
			$objGroupBoxNVIDIA.Controls.Add($objGroupBoxNVIDIALabelMemory)
			$objGroupBoxNVIDIATextBoxMemory = New-Object System.Windows.Forms.TextBox
			$objGroupBoxNVIDIATextBoxMemory.Location = New-Object System.Drawing.Point(570,20)
			$objGroupBoxNVIDIATextBoxMemory.Size = New-Object System.Drawing.Size(50,20)
			$objGroupBoxNVIDIATextBoxMemory.Cursor = [System.Windows.Forms.Cursors]::Default
			$objGroupBoxNVIDIATextBoxMemory.ReadOnly = $True
			$objGroupBoxNVIDIATextBoxMemory.Text = ""
			$objGroupBoxNVIDIA.Controls.Add($objGroupBoxNVIDIATextBoxMemory)

			$objGroupBoxNVIDIALabelPower = New-Object System.Windows.Forms.Label
			$objGroupBoxNVIDIALabelPower.Location = New-Object System.Drawing.Size(5,45)
			$objGroupBoxNVIDIALabelPower.Size = New-Object System.Drawing.Size(50,20)
			$objGroupBoxNVIDIALabelPower.Text = "Power:"
			$objGroupBoxNVIDIALabelPower.Font = New-Object System.Drawing.Font("Times New Roman",11,[System.Drawing.FontStyle]::Regular)
			$objGroupBoxNVIDIALabelPower.BackColor = "Transparent"
			$objGroupBoxNVIDIA.Controls.Add($objGroupBoxNVIDIALabelPower)
			$objGroupBoxNVIDIATextBoxPower = New-Object System.Windows.Forms.TextBox
			$objGroupBoxNVIDIATextBoxPower.Location = New-Object System.Drawing.Point(55,45)
			$objGroupBoxNVIDIATextBoxPower.Size = New-Object System.Drawing.Size(50,20)
			$objGroupBoxNVIDIATextBoxPower.Cursor = [System.Windows.Forms.Cursors]::Default
			$objGroupBoxNVIDIATextBoxPower.ReadOnly = $True
			$objGroupBoxNVIDIATextBoxPower.Text = ""
			$objGroupBoxNVIDIA.Controls.Add($objGroupBoxNVIDIATextBoxPower)
			$objGroupBoxNVIDIALabelPowerUnits = New-Object System.Windows.Forms.Label
			$objGroupBoxNVIDIALabelPowerUnits.Location = New-Object System.Drawing.Size(110,45)
			$objGroupBoxNVIDIALabelPowerUnits.Size = New-Object System.Drawing.Size(40,20)
			$objGroupBoxNVIDIALabelPowerUnits.Text = "Watt"
			$objGroupBoxNVIDIALabelPowerUnits.Font = New-Object System.Drawing.Font("Times New Roman",11,[System.Drawing.FontStyle]::Regular)
			$objGroupBoxNVIDIALabelPowerUnits.BackColor = "Transparent"
			$objGroupBoxNVIDIA.Controls.Add($objGroupBoxNVIDIALabelPowerUnits)

			$objGroupBoxNVIDIALabelTemperature = New-Object System.Windows.Forms.Label
			$objGroupBoxNVIDIALabelTemperature.Location = New-Object System.Drawing.Size(230,45)
			$objGroupBoxNVIDIALabelTemperature.Size = New-Object System.Drawing.Size(90,20)
			$objGroupBoxNVIDIALabelTemperature.Text = "Temperature:"
			$objGroupBoxNVIDIALabelTemperature.Font = New-Object System.Drawing.Font("Times New Roman",11,[System.Drawing.FontStyle]::Regular)
			$objGroupBoxNVIDIALabelTemperature.BackColor = "Transparent"
			$objGroupBoxNVIDIA.Controls.Add($objGroupBoxNVIDIALabelTemperature)
			$objGroupBoxNVIDIATextBoxTemperature = New-Object System.Windows.Forms.TextBox
			$objGroupBoxNVIDIATextBoxTemperature.Location = New-Object System.Drawing.Point(320,45)
			$objGroupBoxNVIDIATextBoxTemperature.Size = New-Object System.Drawing.Size(50,20)
			$objGroupBoxNVIDIATextBoxTemperature.Cursor = [System.Windows.Forms.Cursors]::Default
			$objGroupBoxNVIDIATextBoxTemperature.ReadOnly = $True
			$objGroupBoxNVIDIATextBoxTemperature.Text = ""
			$objGroupBoxNVIDIA.Controls.Add($objGroupBoxNVIDIATextBoxTemperature)
			$objGroupBoxNVIDIALabelTemperatureUnits = New-Object System.Windows.Forms.Label
			$objGroupBoxNVIDIALabelTemperatureUnits.Location = New-Object System.Drawing.Size(375,45)
			$objGroupBoxNVIDIALabelTemperatureUnits.Size = New-Object System.Drawing.Size(30,20)
			$objGroupBoxNVIDIALabelTemperatureUnits.Text = "C"
			$objGroupBoxNVIDIALabelTemperatureUnits.Font = New-Object System.Drawing.Font("Times New Roman",11,[System.Drawing.FontStyle]::Regular)
			$objGroupBoxNVIDIALabelTemperatureUnits.BackColor = "Transparent"
			$objGroupBoxNVIDIA.Controls.Add($objGroupBoxNVIDIALabelTemperatureUnits)

			$objGroupBoxNVIDIALabelFan = New-Object System.Windows.Forms.Label
			$objGroupBoxNVIDIALabelFan.Location = New-Object System.Drawing.Size(485,45)
			$objGroupBoxNVIDIALabelFan.Size = New-Object System.Drawing.Size(35,20)
			$objGroupBoxNVIDIALabelFan.Text = "Fan:"
			$objGroupBoxNVIDIALabelFan.Font = New-Object System.Drawing.Font("Times New Roman",11,[System.Drawing.FontStyle]::Regular)
			$objGroupBoxNVIDIALabelFan.BackColor = "Transparent"
			$objGroupBoxNVIDIA.Controls.Add($objGroupBoxNVIDIALabelFan)
			$objGroupBoxNVIDIATextBoxFan = New-Object System.Windows.Forms.TextBox
			$objGroupBoxNVIDIATextBoxFan.Location = New-Object System.Drawing.Point(520,45)
			$objGroupBoxNVIDIATextBoxFan.Size = New-Object System.Drawing.Size(50,20)
			$objGroupBoxNVIDIATextBoxFan.Cursor = [System.Windows.Forms.Cursors]::Default
			$objGroupBoxNVIDIATextBoxFan.ReadOnly = $True
			$objGroupBoxNVIDIATextBoxFan.Text = ""
			$objGroupBoxNVIDIA.Controls.Add($objGroupBoxNVIDIATextBoxFan)
			$objGroupBoxNVIDIALabelFanUnits = New-Object System.Windows.Forms.Label
			$objGroupBoxNVIDIALabelFanUnits.Location = New-Object System.Drawing.Size(575,45)
			$objGroupBoxNVIDIALabelFanUnits.Size = New-Object System.Drawing.Size(40,20)
			$objGroupBoxNVIDIALabelFanUnits.Text = "RPM"
			$objGroupBoxNVIDIALabelFanUnits.Font = New-Object System.Drawing.Font("Times New Roman",11,[System.Drawing.FontStyle]::Regular)
			$objGroupBoxNVIDIALabelFanUnits.BackColor = "Transparent"
			$objGroupBoxNVIDIA.Controls.Add($objGroupBoxNVIDIALabelFanUnits)

		$objForm.Controls.Add($objGroupBoxNVIDIA)
	}

	$objGroupBoxConnection = New-Object System.Windows.Forms.GroupBox
	$objGroupBoxConnection.Location = New-Object System.Drawing.Point($objFormConnectionHorizontalPosition,$objFormConnectionVerticalPosition)
	$objGroupBoxConnection.Size = New-Object System.Drawing.Size($objFormConnectionWidth,$objFormConnectionHeight)
	$objGroupBoxConnection.Font = New-Object System.Drawing.Font("Times New Roman",10,[System.Drawing.FontStyle]::Regular)
	$objGroupBoxConnection.Text = "Connection:"

		$objGroupBoxConnectionLabelPool = New-Object System.Windows.Forms.Label
		$objGroupBoxConnectionLabelPool.Location = New-Object System.Drawing.Size(5,20)
		$objGroupBoxConnectionLabelPool.Size = New-Object System.Drawing.Size(40,20)
		$objGroupBoxConnectionLabelPool.Text = "Pool:"
		$objGroupBoxConnectionLabelPool.Font = New-Object System.Drawing.Font("Times New Roman",11,[System.Drawing.FontStyle]::Regular)
		$objGroupBoxConnectionLabelPool.BackColor = "Transparent"
		$objGroupBoxConnection.Controls.Add($objGroupBoxConnectionLabelPool)
		$objGroupBoxConnectionTextBoxPool = New-Object System.Windows.Forms.TextBox
		$objGroupBoxConnectionTextBoxPool.Location = New-Object System.Drawing.Point(45,20)
		$objGroupBoxConnectionTextBoxPool.Size = New-Object System.Drawing.Size(190,20)
		$objGroupBoxConnectionTextBoxPool.ReadOnly = $False
		$objGroupBoxConnectionTextBoxPool.Text = ""
		$objGroupBoxConnection.Controls.Add($objGroupBoxConnectionTextBoxPool)

		$objGroupBoxConnectionLabelPing = New-Object System.Windows.Forms.Label
		$objGroupBoxConnectionLabelPing.Location = New-Object System.Drawing.Size(245,20)
		$objGroupBoxConnectionLabelPing.Size = New-Object System.Drawing.Size(40,20)
		$objGroupBoxConnectionLabelPing.Text = "Ping:"
		$objGroupBoxConnectionLabelPing.Font = New-Object System.Drawing.Font("Times New Roman",11,[System.Drawing.FontStyle]::Regular)
		$objGroupBoxConnectionLabelPing.BackColor = "Transparent"
		$objGroupBoxConnection.Controls.Add($objGroupBoxConnectionLabelPing)
		$objGroupBoxConnectionTextBoxPing = New-Object System.Windows.Forms.TextBox
		$objGroupBoxConnectionTextBoxPing.Location = New-Object System.Drawing.Point(285,20)
		$objGroupBoxConnectionTextBoxPing.Size = New-Object System.Drawing.Size(40,20)
		$objGroupBoxConnectionTextBoxPing.Cursor = [System.Windows.Forms.Cursors]::Default
		$objGroupBoxConnectionTextBoxPing.ReadOnly = $True
		$objGroupBoxConnectionTextBoxPing.TextAlign = "Center";
		$objGroupBoxConnectionTextBoxPing.Text = ""
		$objGroupBoxConnection.Controls.Add($objGroupBoxConnectionTextBoxPing)
		$objGroupBoxConnectionLabelPingUnits = New-Object System.Windows.Forms.Label
		$objGroupBoxConnectionLabelPingUnits.Location = New-Object System.Drawing.Size(325,20)
		$objGroupBoxConnectionLabelPingUnits.Size = New-Object System.Drawing.Size(40,20)
		$objGroupBoxConnectionLabelPingUnits.Text = "[ms]"
		$objGroupBoxConnectionLabelPingUnits.Font = New-Object System.Drawing.Font("Times New Roman",11,[System.Drawing.FontStyle]::Regular)
		$objGroupBoxConnectionLabelPingUnits.BackColor = "Transparent"
		$objGroupBoxConnection.Controls.Add($objGroupBoxConnectionLabelPingUnits)

		$objGroupBoxConnectionLabelUptime = New-Object System.Windows.Forms.Label
		$objGroupBoxConnectionLabelUptime.Location = New-Object System.Drawing.Size(375,20)
		$objGroupBoxConnectionLabelUptime.Size = New-Object System.Drawing.Size(55,20)
		$objGroupBoxConnectionLabelUptime.Text = "Uptime:"
		$objGroupBoxConnectionLabelUptime.Font = New-Object System.Drawing.Font("Times New Roman",11,[System.Drawing.FontStyle]::Regular)
		$objGroupBoxConnectionLabelUptime.BackColor = "Transparent"
		$objGroupBoxConnection.Controls.Add($objGroupBoxConnectionLabelUptime)
		$objGroupBoxConnectionTextBoxUptime = New-Object System.Windows.Forms.TextBox
		$objGroupBoxConnectionTextBoxUptime.Location = New-Object System.Drawing.Point(430,20)
		$objGroupBoxConnectionTextBoxUptime.Size = New-Object System.Drawing.Size(60,20)
		$objGroupBoxConnectionTextBoxUptime.Cursor = [System.Windows.Forms.Cursors]::Default
		$objGroupBoxConnectionTextBoxUptime.ReadOnly = $True
		$objGroupBoxConnectionTextBoxUptime.TextAlign = "Center";
		$objGroupBoxConnectionTextBoxUptime.Text = ""
		$objGroupBoxConnection.Controls.Add($objGroupBoxConnectionTextBoxUptime)
		$objGroupBoxConnectionLabelUptimeUnits = New-Object System.Windows.Forms.Label
		$objGroupBoxConnectionLabelUptimeUnits.Location = New-Object System.Drawing.Size(490,20)
		$objGroupBoxConnectionLabelUptimeUnits.Size = New-Object System.Drawing.Size(30,20)
		$objGroupBoxConnectionLabelUptimeUnits.Text = "[s]"
		$objGroupBoxConnectionLabelUptimeUnits.Font = New-Object System.Drawing.Font("Times New Roman",11,[System.Drawing.FontStyle]::Regular)
		$objGroupBoxConnectionLabelUptimeUnits.BackColor = "Transparent"
		$objGroupBoxConnection.Controls.Add($objGroupBoxConnectionLabelUptimeUnits)

		$objGroupBoxConnectionLabelFailures = New-Object System.Windows.Forms.Label
		$objGroupBoxConnectionLabelFailures.Location = New-Object System.Drawing.Size(530,20)
		$objGroupBoxConnectionLabelFailures.Size = New-Object System.Drawing.Size(60,20)
		$objGroupBoxConnectionLabelFailures.Text = "Failures:"
		$objGroupBoxConnectionLabelFailures.Font = New-Object System.Drawing.Font("Times New Roman",11,[System.Drawing.FontStyle]::Regular)
		$objGroupBoxConnectionLabelFailures.BackColor = "Transparent"
		$objGroupBoxConnection.Controls.Add($objGroupBoxConnectionLabelFailures)
		$objGroupBoxConnectionTextBoxFailures = New-Object System.Windows.Forms.TextBox
		$objGroupBoxConnectionTextBoxFailures.Location = New-Object System.Drawing.Point(590,20)
		$objGroupBoxConnectionTextBoxFailures.Size = New-Object System.Drawing.Size(30,20)
		$objGroupBoxConnectionTextBoxFailures.Cursor = [System.Windows.Forms.Cursors]::Default
		$objGroupBoxConnectionTextBoxFailures.ReadOnly = $True
		$objGroupBoxConnectionTextBoxFailures.TextAlign = "Center";
		$objGroupBoxConnectionTextBoxFailures.Text = ""
		$objGroupBoxConnection.Controls.Add($objGroupBoxConnectionTextBoxFailures)

		$objGroupBoxConnectionErrorLog = New-Object System.Windows.Forms.GroupBox
		$objGroupBoxConnectionErrorLog.Location = New-Object System.Drawing.Point(5,45)
		$objGroupBoxConnectionErrorLog.Size = New-Object System.Drawing.Size(615,100)
		$objGroupBoxConnectionErrorLog.Font = New-Object System.Drawing.Font("Times New Roman",10,[System.Drawing.FontStyle]::Regular)
		$objGroupBoxConnectionErrorLog.Visible = $FormFieldConnectionErrorLogVisible
		$objGroupBoxConnectionErrorLog.Text = "Error log:"

			$objGroupBoxConnectionListBoxErrorLog = New-Object System.Windows.Forms.ListBox
			$objGroupBoxConnectionListBoxErrorLog.Location = New-Object System.Drawing.Point(5,15)
			$objGroupBoxConnectionListBoxErrorLog.Size = New-Object System.Drawing.Size(605,80)
			$objGroupBoxConnectionErrorLog.Controls.Add($objGroupBoxConnectionListBoxErrorLog)

		$objGroupBoxConnection.Controls.Add($objGroupBoxConnectionErrorLog)

	$objForm.Controls.Add($objGroupBoxConnection)

	$objGroupBoxHashrate = New-Object System.Windows.Forms.GroupBox
	$objGroupBoxHashrate.Location = New-Object System.Drawing.Point($objFormHashrateHorizontalPosition,$objFormHashrateVerticalPosition)
	$objGroupBoxHashrate.Size = New-Object System.Drawing.Size($objFormHashrateWidth,$objFormHashrateHeight)
	$objGroupBoxHashrate.Font = New-Object System.Drawing.Font("Times New Roman",10,[System.Drawing.FontStyle]::Regular)
	$objGroupBoxHashrate.Text = "Hashrate:"

		$objGroupBoxHashrateLabelTotal1 = New-Object System.Windows.Forms.Label
		$objGroupBoxHashrateLabelTotal1.Location = New-Object System.Drawing.Size(5,20)
		$objGroupBoxHashrateLabelTotal1.Size = New-Object System.Drawing.Size(150,20)
		$objGroupBoxHashrateLabelTotal1.Text = "Total (in 2,5 seconds):"
		$objGroupBoxHashrateLabelTotal1.Font = New-Object System.Drawing.Font("Times New Roman",11,[System.Drawing.FontStyle]::Regular)
		$objGroupBoxHashrateLabelTotal1.BackColor = "Transparent"
		$objGroupBoxHashrate.Controls.Add($objGroupBoxHashrateLabelTotal1)
		$objGroupBoxHashrateTextBoxTotal1 = New-Object System.Windows.Forms.TextBox
		$objGroupBoxHashrateTextBoxTotal1.Location = New-Object System.Drawing.Point(155,20)
		$objGroupBoxHashrateTextBoxTotal1.Size = New-Object System.Drawing.Size(60,20)
		$objGroupBoxHashrateTextBoxTotal1.Cursor = [System.Windows.Forms.Cursors]::Default
		$objGroupBoxHashrateTextBoxTotal1.ReadOnly = $True
		$objGroupBoxHashrateTextBoxTotal1.TextAlign = "Center";
		$objGroupBoxHashrateTextBoxTotal1.Text = ""
		$objGroupBoxHashrate.Controls.Add($objGroupBoxHashrateTextBoxTotal1)
		$objGroupBoxHashrateLabelTotalUnits1 = New-Object System.Windows.Forms.Label
		$objGroupBoxHashrateLabelTotalUnits1.Location = New-Object System.Drawing.Size(215,20)
		$objGroupBoxHashrateLabelTotalUnits1.Size = New-Object System.Drawing.Size(40,20)
		$objGroupBoxHashrateLabelTotalUnits1.Text = "[H/s]"
		$objGroupBoxHashrateLabelTotalUnits1.Font = New-Object System.Drawing.Font("Times New Roman",11,[System.Drawing.FontStyle]::Regular)
		$objGroupBoxHashrateLabelTotalUnits1.BackColor = "Transparent"
		$objGroupBoxHashrate.Controls.Add($objGroupBoxHashrateLabelTotalUnits1)

		$objGroupBoxHashrateLabelTotal2 = New-Object System.Windows.Forms.Label
		$objGroupBoxHashrateLabelTotal2.Location = New-Object System.Drawing.Size(5,45)
		$objGroupBoxHashrateLabelTotal2.Size = New-Object System.Drawing.Size(150,20)
		$objGroupBoxHashrateLabelTotal2.Text = "Total (in 60 seconds):"
		$objGroupBoxHashrateLabelTotal2.Font = New-Object System.Drawing.Font("Times New Roman",11,[System.Drawing.FontStyle]::Regular)
		$objGroupBoxHashrateLabelTotal2.BackColor = "Transparent"
		$objGroupBoxHashrate.Controls.Add($objGroupBoxHashrateLabelTotal2)
		$objGroupBoxHashrateTextBoxTotal2 = New-Object System.Windows.Forms.TextBox
		$objGroupBoxHashrateTextBoxTotal2.Location = New-Object System.Drawing.Point(155,45)
		$objGroupBoxHashrateTextBoxTotal2.Size = New-Object System.Drawing.Size(60,20)
		$objGroupBoxHashrateTextBoxTotal2.Cursor = [System.Windows.Forms.Cursors]::Default
		$objGroupBoxHashrateTextBoxTotal2.ReadOnly = $True
		$objGroupBoxHashrateTextBoxTotal2.TextAlign = "Center";
		$objGroupBoxHashrateTextBoxTotal2.Text = ""
		$objGroupBoxHashrate.Controls.Add($objGroupBoxHashrateTextBoxTotal2)
		$objGroupBoxHashrateLabelTotalUnits2 = New-Object System.Windows.Forms.Label
		$objGroupBoxHashrateLabelTotalUnits2.Location = New-Object System.Drawing.Size(215,45)
		$objGroupBoxHashrateLabelTotalUnits2.Size = New-Object System.Drawing.Size(40,20)
		$objGroupBoxHashrateLabelTotalUnits2.Text = "[H/s]"
		$objGroupBoxHashrateLabelTotalUnits2.Font = New-Object System.Drawing.Font("Times New Roman",11,[System.Drawing.FontStyle]::Regular)
		$objGroupBoxHashrateLabelTotalUnits2.BackColor = "Transparent"
		$objGroupBoxHashrate.Controls.Add($objGroupBoxHashrateLabelTotalUnits2)

		$objGroupBoxHashrateLabelTotal3 = New-Object System.Windows.Forms.Label
		$objGroupBoxHashrateLabelTotal3.Location = New-Object System.Drawing.Size(5,70)
		$objGroupBoxHashrateLabelTotal3.Size = New-Object System.Drawing.Size(150,20)
		$objGroupBoxHashrateLabelTotal3.Text = "Total (in 15 minutes):"
		$objGroupBoxHashrateLabelTotal3.Font = New-Object System.Drawing.Font("Times New Roman",11,[System.Drawing.FontStyle]::Regular)
		$objGroupBoxHashrateLabelTotal3.BackColor = "Transparent"
		$objGroupBoxHashrate.Controls.Add($objGroupBoxHashrateLabelTotal3)
		$objGroupBoxHashrateTextBoxTotal3 = New-Object System.Windows.Forms.TextBox
		$objGroupBoxHashrateTextBoxTotal3.Location = New-Object System.Drawing.Point(155,70)
		$objGroupBoxHashrateTextBoxTotal3.Size = New-Object System.Drawing.Size(60,20)
		$objGroupBoxHashrateTextBoxTotal3.Cursor = [System.Windows.Forms.Cursors]::Default
		$objGroupBoxHashrateTextBoxTotal3.ReadOnly = $True
		$objGroupBoxHashrateTextBoxTotal3.TextAlign = "Center";
		$objGroupBoxHashrateTextBoxTotal3.Text = ""
		$objGroupBoxHashrate.Controls.Add($objGroupBoxHashrateTextBoxTotal3)
		$objGroupBoxHashrateLabelTotalUnits3 = New-Object System.Windows.Forms.Label
		$objGroupBoxHashrateLabelTotalUnits3.Location = New-Object System.Drawing.Size(215,70)
		$objGroupBoxHashrateLabelTotalUnits3.Size = New-Object System.Drawing.Size(40,20)
		$objGroupBoxHashrateLabelTotalUnits3.Text = "[H/s]"
		$objGroupBoxHashrateLabelTotalUnits3.Font = New-Object System.Drawing.Font("Times New Roman",11,[System.Drawing.FontStyle]::Regular)
		$objGroupBoxHashrateLabelTotalUnits3.BackColor = "Transparent"
		$objGroupBoxHashrate.Controls.Add($objGroupBoxHashrateLabelTotalUnits3)

		$objGroupBoxHashrateLabelHighest = New-Object System.Windows.Forms.Label
		$objGroupBoxHashrateLabelHighest.Location = New-Object System.Drawing.Size(5,95)
		$objGroupBoxHashrateLabelHighest.Size = New-Object System.Drawing.Size(150,20)
		$objGroupBoxHashrateLabelHighest.Text = "Highest:"
		$objGroupBoxHashrateLabelHighest.Font = New-Object System.Drawing.Font("Times New Roman",11,[System.Drawing.FontStyle]::Regular)
		$objGroupBoxHashrateLabelHighest.BackColor = "Transparent"
		$objGroupBoxHashrate.Controls.Add($objGroupBoxHashrateLabelHighest)
		$objGroupBoxHashrateTextBoxHighest = New-Object System.Windows.Forms.TextBox
		$objGroupBoxHashrateTextBoxHighest.Location = New-Object System.Drawing.Point(155,95)
		$objGroupBoxHashrateTextBoxHighest.Size = New-Object System.Drawing.Size(60,20)
		$objGroupBoxHashrateTextBoxHighest.Cursor = [System.Windows.Forms.Cursors]::Default
		$objGroupBoxHashrateTextBoxHighest.ReadOnly = $True
		$objGroupBoxHashrateTextBoxHighest.TextAlign = "Center";
		$objGroupBoxHashrateTextBoxHighest.Text = ""
		$objGroupBoxHashrate.Controls.Add($objGroupBoxHashrateTextBoxHighest)
		$objGroupBoxHashrateLabelHighestUnits = New-Object System.Windows.Forms.Label
		$objGroupBoxHashrateLabelHighestUnits.Location = New-Object System.Drawing.Size(215,95)
		$objGroupBoxHashrateLabelHighestUnits.Size = New-Object System.Drawing.Size(40,20)
		$objGroupBoxHashrateLabelHighestUnits.Text = "[H/s]"
		$objGroupBoxHashrateLabelHighestUnits.Font = New-Object System.Drawing.Font("Times New Roman",11,[System.Drawing.FontStyle]::Regular)
		$objGroupBoxHashrateLabelHighestUnits.BackColor = "Transparent"
		$objGroupBoxHashrate.Controls.Add($objGroupBoxHashrateLabelHighestUnits)

		$objGroupBoxHashrateThreads = New-Object System.Windows.Forms.GroupBox
		$objGroupBoxHashrateThreads.Location = New-Object System.Drawing.Point(360,10)
		$objGroupBoxHashrateThreads.Size = New-Object System.Drawing.Size(260,115)
		$objGroupBoxHashrateThreads.Font = New-Object System.Drawing.Font("Times New Roman",10,[System.Drawing.FontStyle]::Regular)
		$objGroupBoxHashrateThreads.Text = "Threads:"

			$objGroupBoxHashrateListViewThreads = New-Object System.Windows.Forms.ListView
			$objGroupBoxHashrateListViewThreads.Location = New-Object System.Drawing.Point(5,15)
			$objGroupBoxHashrateListViewThreads.Size = New-Object System.Drawing.Size(255,95)
			$objGroupBoxHashrateListViewThreads.View = [System.Windows.Forms.View]::Details
			$objGroupBoxHashrateListViewThreads.Width = $objGroupBoxHashrateListViewThreads.ClientRectangle.Width
			$objGroupBoxHashrateListViewThreads.Height = $objGroupBoxHashrateListViewThreads.ClientRectangle.Height
			$objGroupBoxHashrateListViewThreads.Anchor = "Top, Left, Right, Bottom"
			$objGroupBoxHashrateListViewThreads.Columns.Add("#", 20, "Center") | Out-Null
			$objGroupBoxHashrateListViewThreads.Columns.Add("2,5s", 70, "Center") | Out-Null
			$objGroupBoxHashrateListViewThreads.Columns.Add("60s", 70, "Center") | Out-Null
			$objGroupBoxHashrateListViewThreads.Columns.Add("15m", 70, "Center") | Out-Null
			$objGroupBoxHashrateThreads.Controls.Add($objGroupBoxHashrateListViewThreads)
			$objGroupBoxHashrateListViewThreads.add_ColumnClick({SortListView $objGroupBoxHashrateListViewThreads $_.Column})

		$objGroupBoxHashrate.Controls.Add($objGroupBoxHashrateThreads)

	$objForm.Controls.Add($objGroupBoxHashrate)

	$objGroupBoxResults = New-Object System.Windows.Forms.GroupBox
	$objGroupBoxResults.Location = New-Object System.Drawing.Point($objFormResultsHorizontalPosition,$objFormResultsVerticalPosition)
	$objGroupBoxResults.Size = New-Object System.Drawing.Size($objFormResultsWidth,$objFormResultsHeight)
	$objGroupBoxResults.Font = New-Object System.Drawing.Font("Times New Roman",10,[System.Drawing.FontStyle]::Regular)
	$objGroupBoxResults.Text = "Results:"

		$objGroupBoxResultsLabelHashes = New-Object System.Windows.Forms.Label
		$objGroupBoxResultsLabelHashes.Location = New-Object System.Drawing.Size(5,20)
		$objGroupBoxResultsLabelHashes.Size = New-Object System.Drawing.Size(55,20)
		$objGroupBoxResultsLabelHashes.Text = "Hashes:"
		$objGroupBoxResultsLabelHashes.Font = New-Object System.Drawing.Font("Times New Roman",11,[System.Drawing.FontStyle]::Regular)
		$objGroupBoxResultsLabelHashes.BackColor = "Transparent"
		$objGroupBoxResults.Controls.Add($objGroupBoxResultsLabelHashes)
		$objGroupBoxResultsTextBoxHashes = New-Object System.Windows.Forms.TextBox
		$objGroupBoxResultsTextBoxHashes.Location = New-Object System.Drawing.Point(60,20)
		$objGroupBoxResultsTextBoxHashes.Size = New-Object System.Drawing.Size(80,20)
		$objGroupBoxResultsTextBoxHashes.Cursor = [System.Windows.Forms.Cursors]::Default
		$objGroupBoxResultsTextBoxHashes.ReadOnly = $True
		$objGroupBoxResultsTextBoxHashes.TextAlign = "Center";
		$objGroupBoxResultsTextBoxHashes.Text = ""
		$objGroupBoxResults.Controls.Add($objGroupBoxResultsTextBoxHashes)

		$objGroupBoxResultsLabelShares = New-Object System.Windows.Forms.Label
		$objGroupBoxResultsLabelShares.Location = New-Object System.Drawing.Size(150,20)
		$objGroupBoxResultsLabelShares.Size = New-Object System.Drawing.Size(135,20)
		$objGroupBoxResultsLabelShares.Text = "Shares (total / good):"
		$objGroupBoxResultsLabelShares.Font = New-Object System.Drawing.Font("Times New Roman",11,[System.Drawing.FontStyle]::Regular)
		$objGroupBoxResultsLabelShares.BackColor = "Transparent"
		$objGroupBoxResults.Controls.Add($objGroupBoxResultsLabelShares)
		$objGroupBoxResultsTextBoxSharesTotal = New-Object System.Windows.Forms.TextBox
		$objGroupBoxResultsTextBoxSharesTotal.Location = New-Object System.Drawing.Point(290,20)
		$objGroupBoxResultsTextBoxSharesTotal.Size = New-Object System.Drawing.Size(40,20)
		$objGroupBoxResultsTextBoxSharesTotal.Cursor = [System.Windows.Forms.Cursors]::Default
		$objGroupBoxResultsTextBoxSharesTotal.ReadOnly = $True
		$objGroupBoxResultsTextBoxSharesTotal.TextAlign = "Center";
		$objGroupBoxResultsTextBoxSharesTotal.Text = ""
		$objGroupBoxResults.Controls.Add($objGroupBoxResultsTextBoxSharesTotal)
		$objGroupBoxResultsLabelSharesDelimeter = New-Object System.Windows.Forms.Label
		$objGroupBoxResultsLabelSharesDelimeter.Location = New-Object System.Drawing.Size(330,20)
		$objGroupBoxResultsLabelSharesDelimeter.Size = New-Object System.Drawing.Size(10,20)
		$objGroupBoxResultsLabelSharesDelimeter.Text = "/"
		$objGroupBoxResultsLabelSharesDelimeter.Font = New-Object System.Drawing.Font("Times New Roman",11,[System.Drawing.FontStyle]::Regular)
		$objGroupBoxResultsLabelSharesDelimeter.BackColor = "Transparent"
		$objGroupBoxResults.Controls.Add($objGroupBoxResultsLabelSharesDelimeter)
		$objGroupBoxResultsTextBoxSharesGood = New-Object System.Windows.Forms.TextBox
		$objGroupBoxResultsTextBoxSharesGood.Location = New-Object System.Drawing.Point(340,20)
		$objGroupBoxResultsTextBoxSharesGood.Size = New-Object System.Drawing.Size(40,20)
		$objGroupBoxResultsTextBoxSharesGood.Cursor = [System.Windows.Forms.Cursors]::Default
		$objGroupBoxResultsTextBoxSharesGood.ReadOnly = $True
		$objGroupBoxResultsTextBoxSharesGood.TextAlign = "Center";
		$objGroupBoxResultsTextBoxSharesGood.Text = ""
		$objGroupBoxResults.Controls.Add($objGroupBoxResultsTextBoxSharesGood)

		$objGroupBoxResultsLabelTime = New-Object System.Windows.Forms.Label
		$objGroupBoxResultsLabelTime.Location = New-Object System.Drawing.Size(390,20)
		$objGroupBoxResultsLabelTime.Size = New-Object System.Drawing.Size(45,20)
		$objGroupBoxResultsLabelTime.Text = "Time:"
		$objGroupBoxResultsLabelTime.Font = New-Object System.Drawing.Font("Times New Roman",11,[System.Drawing.FontStyle]::Regular)
		$objGroupBoxResultsLabelTime.BackColor = "Transparent"
		$objGroupBoxResults.Controls.Add($objGroupBoxResultsLabelTime)
		$objGroupBoxResultsTextBoxTime = New-Object System.Windows.Forms.TextBox
		$objGroupBoxResultsTextBoxTime.Location = New-Object System.Drawing.Point(435,20)
		$objGroupBoxResultsTextBoxTime.Size = New-Object System.Drawing.Size(40,20)
		$objGroupBoxResultsTextBoxTime.Cursor = [System.Windows.Forms.Cursors]::Default
		$objGroupBoxResultsTextBoxTime.ReadOnly = $True
		$objGroupBoxResultsTextBoxTime.TextAlign = "Center";
		$objGroupBoxResultsTextBoxTime.Text = ""
		$objGroupBoxResults.Controls.Add($objGroupBoxResultsTextBoxTime)

		$objGroupBoxResultsLabelDifficulty = New-Object System.Windows.Forms.Label
		$objGroupBoxResultsLabelDifficulty.Location = New-Object System.Drawing.Size(485,20)
		$objGroupBoxResultsLabelDifficulty.Size = New-Object System.Drawing.Size(75,20)
		$objGroupBoxResultsLabelDifficulty.Text = "Difficulty:"
		$objGroupBoxResultsLabelDifficulty.Font = New-Object System.Drawing.Font("Times New Roman",11,[System.Drawing.FontStyle]::Regular)
		$objGroupBoxResultsLabelDifficulty.BackColor = "Transparent"
		$objGroupBoxResults.Controls.Add($objGroupBoxResultsLabelDifficulty)
		$objGroupBoxResultsTextBoxDifficulty = New-Object System.Windows.Forms.TextBox
		$objGroupBoxResultsTextBoxDifficulty.Location = New-Object System.Drawing.Point(560,20)
		$objGroupBoxResultsTextBoxDifficulty.Size = New-Object System.Drawing.Size(60,20)
		$objGroupBoxResultsTextBoxDifficulty.Cursor = [System.Windows.Forms.Cursors]::Default
		$objGroupBoxResultsTextBoxDifficulty.ReadOnly = $True
		$objGroupBoxResultsTextBoxDifficulty.TextAlign = "Center";
		$objGroupBoxResultsTextBoxDifficulty.Text = ""
		$objGroupBoxResults.Controls.Add($objGroupBoxResultsTextBoxDifficulty)

		$objGroupBoxResultsTop10Shares = New-Object System.Windows.Forms.GroupBox
		$objGroupBoxResultsTop10Shares.Location = New-Object System.Drawing.Point(5,45)
		$objGroupBoxResultsTop10Shares.Size = New-Object System.Drawing.Size(615,60)
		$objGroupBoxResultsTop10Shares.Font = New-Object System.Drawing.Font("Times New Roman",10,[System.Drawing.FontStyle]::Regular)
		$objGroupBoxResultsTop10Shares.Text = "Top 10 Shares:"

			$objGroupBoxResultsListViewTop10Shares = New-Object System.Windows.Forms.ListView
			$objGroupBoxResultsListViewTop10Shares.Location = New-Object System.Drawing.Point(5,15)
			$objGroupBoxResultsListViewTop10Shares.Size = New-Object System.Drawing.Size(610,45)
			$objGroupBoxResultsListViewTop10Shares.View = [System.Windows.Forms.View]::Details
			$objGroupBoxResultsListViewTop10Shares.Width = $objGroupBoxResultsListViewTop10Shares.ClientRectangle.Width
			$objGroupBoxResultsListViewTop10Shares.Height = $objGroupBoxResultsListViewTop10Shares.ClientRectangle.Height
			$objGroupBoxResultsListViewTop10Shares.Anchor = "Top, Left, Right, Bottom"
			$objGroupBoxResultsListViewTop10Shares.Columns.Add("0", 0) | Out-Null
			$objGroupBoxResultsListViewTop10Shares.Columns.Add("1", 60, "Center") | Out-Null
			$objGroupBoxResultsListViewTop10Shares.Columns.Add("2", 60, "Center") | Out-Null
			$objGroupBoxResultsListViewTop10Shares.Columns.Add("3", 60, "Center") | Out-Null
			$objGroupBoxResultsListViewTop10Shares.Columns.Add("4", 60, "Center") | Out-Null
			$objGroupBoxResultsListViewTop10Shares.Columns.Add("5", 60, "Center") | Out-Null
			$objGroupBoxResultsListViewTop10Shares.Columns.Add("6", 60, "Center") | Out-Null
			$objGroupBoxResultsListViewTop10Shares.Columns.Add("7", 60, "Center") | Out-Null
			$objGroupBoxResultsListViewTop10Shares.Columns.Add("8", 60, "Center") | Out-Null
			$objGroupBoxResultsListViewTop10Shares.Columns.Add("9", 60, "Center") | Out-Null
			$objGroupBoxResultsListViewTop10Shares.Columns.Add("10", 60, "Center") | Out-Null
			$objGroupBoxResultsTop10Shares.Controls.Add($objGroupBoxResultsListViewTop10Shares)

		$objGroupBoxResults.Controls.Add($objGroupBoxResultsTop10Shares)

		$objGroupBoxResultsErrorLog = New-Object System.Windows.Forms.GroupBox
		$objGroupBoxResultsErrorLog.Location = New-Object System.Drawing.Point(5,105)
		$objGroupBoxResultsErrorLog.Size = New-Object System.Drawing.Size(615,100)
		$objGroupBoxResultsErrorLog.Font = New-Object System.Drawing.Font("Times New Roman",10,[System.Drawing.FontStyle]::Regular)
		$objGroupBoxResultsErrorLog.Visible = $FormFieldResultsErrorLogVisible
		$objGroupBoxResultsErrorLog.Text = "Error log:"

			$objGroupBoxResultsListBoxErrorLog = New-Object System.Windows.Forms.ListBox
			$objGroupBoxResultsListBoxErrorLog.Location = New-Object System.Drawing.Point(5,15)
			$objGroupBoxResultsListBoxErrorLog.Size = New-Object System.Drawing.Size(605,80)
			$objGroupBoxResultsErrorLog.Controls.Add($objGroupBoxResultsListBoxErrorLog)

		$objGroupBoxResults.Controls.Add($objGroupBoxResultsErrorLog)

	$objForm.Controls.Add($objGroupBoxResults)

	$objForm.KeyPreview = $True
	$objForm.Add_KeyDown({If ($_.KeyCode -eq "Escape") {$objForm.Close()}})

	$objForm.Topmost = $True

	If (((Get-Process -name $process -ErrorAction SilentlyContinue).Responding) -eq $True) {
		$ObjTimer.Start()
		$objForm.Add_Load({
			$objGroupBoxUpdateComboBoxHours.SelectedIndex = $objGroupBoxUpdateComboBoxHours.Items.IndexOf("{0:HH}" -f ([datetime]([timespan]::FromSeconds($Script:RefreshInterval)).Ticks))
			$objGroupBoxUpdateComboBoxMinutes.SelectedIndex = $objGroupBoxUpdateComboBoxMinutes.Items.IndexOf("{0:mm}" -f ([datetime]([timespan]::FromSeconds($Script:RefreshInterval)).Ticks))
			$objGroupBoxUpdateComboBoxSeconds.SelectedIndex = $objGroupBoxUpdateComboBoxSeconds.Items.IndexOf("{0:ss}" -f ([datetime]([timespan]::FromSeconds($Script:RefreshInterval)).Ticks))
		})
		$objForm.Add_Shown({$objForm.Activate()})
		$objForm.ShowDialog() | Out-Null
		$objForm.Close()
		$ObjTimer.Stop()
	} Else {
		[System.Windows.Forms.MessageBox]::Show("ERROR: Process `"" + $process + "`" not loaded", "XMRig API Monitor", 0, [System.Windows.Forms.MessageBoxIcon]::Error) | out-null
	}
}

Show_Dialog $address $port $process $refresh
