<#
.SYNOPSIS
  List PSM Sessions
.DESCRIPTION
  List the number of PSM sessions and services status
.PARAMETER <Parameter_Name>
    
.INPUTS
  
.OUTPUTS
  Not log
.NOTES
  Version:        1.0
  Author:         Antonino Bambino
  Creation Date:  13/08/2023
  Purpose/Change: 
  
.EXAMPLE
  PSM-Sessions-Monitor.ps1 -ServerList C:\TMP\listserver.csv
  
  Run Fast mode
  PSM-Sessions-Monitor.ps1 -ServerList C:\TMP\listserver.csv 
  
  Run Normal mode
  PSM-Sessions-Monitor.ps1 -ServerList C:\TMP\listserver.csv -Mode Normal
#>

# param ([Parameter(Mandatory)]$ServerList, [ValidateSet(“Fast”,”Normal”)] [String] $Mode)
param ([Parameter(Mandatory)]$ServerList, $Mode = "Fast")

Clear-Host

# Import list of servers
if (!$ServerList) { exit }
if ( -Not (Test-Path $ServerList) ) {
	Write-Host ''
	Write-Host ''
	Write-Host $ServerList 'not found...' -ForegroundColor Red
	Start-Sleep -Seconds 5
	Return
}

$ServerList = import-csv $ServerList

# Input credential
$credential = Get-Credential -Message "Credential are required for run the script"
if (!$credential) { exit }

$Data = Get-date
Clear-Host
Write-Host '--------------------------------------------' -ForegroundColor Green
Write-Host ''
Write-Host "Start scan server(s): $Data" -ForegroundColor Green
Write-Host ''
Write-Host '--------------------------------------------' -ForegroundColor Green
Write-Host ''
Write-Host '------------------------------'


foreach ($element in $ServerList) {
	# $element.computername
	# $element.role
	# $element.description
	Try {
		
		$ComputerRemoto = ""
		$ComputerRemoto = $element.computername
		
		# Verify connection
		$TestConnection = Test-Connection -ComputerName $element.computername -Quiet -Count 1
		If (-Not $TestConnection) { }
		
		# Set session
		$Session = New-PSSession -ComputerName $element.computername -Credential $credential -ErrorAction Stop

		If ( $Mode -ne "Fast") {
			Write-Host "$($element.computername) - $($element.description)"
			Write-Host ''
		
			# Last reboot
			$LastReboot = Invoke-Command -Session $Session -ScriptBlock { Get-CimInstance -ClassName win32_operatingsystem }
			Write-Host -nonewline 'Last Reboot: '
			Write-Host $LastReboot.lastbootuptime -ForegroundColor Green
			#Write-Host ''
		
			# PSM Service
			$PSMService = Invoke-Command -Session $Session -ScriptBlock { Get-Service 'Cyber-Ark Privileged Session Manager' }
		
			Write-Host -nonewline 'CyberArk PSM Service: '
			if ($PSMService.Status -ne 'Running') {
				Write-Host -nonewline $PSMService.status -ForegroundColor Red
			}
			else {
				Write-Host -nonewline $PSMService.status -ForegroundColor Green
			}
			Write-Host ''
		}
		
		# Get RDP Sessions
		$RDPSessions = Invoke-Command -Session $Session -ScriptBlock { qwinsta /server:$ComputerRemoto; $lastexitcode } 2>&1
		
		$TotRDPSessions = 0
		$TotRDPActiveSessions = 0
		$TotRDPInactiveSessions = 0
		
		foreach ($row in $RDPSessions) {                
			$regex = "Disc|Active"
			#$regex = "Disc|Attivo"

			if ($row -NotMatch "services|console" -and $row -match $regex) {
				$TotRDPSessions ++
				if ($row -match "Active") { $TotRDPActiveSessions ++ }
				if ($row -match "Disc") { $TotRDPInactiveSessions ++ }
			}
		}

		If ( $Mode -ne "Fast") {
			# Number of Active RDP Sessions
			Write-Host -nonewline 'Active RDP Sessions: '
			if ($TotRDPActiveSessions -eq 0) { Write-Host $TotRDPActiveSessions -ForegroundColor Red } Else { Write-Host $TotRDPActiveSessions -ForegroundColor Green }
		
			# Number of Disconnected RDP Sessions
			Write-Host -nonewline 'Disconnected RDP Sessions: '
			if ($TotRDPInactiveSessions -eq 0) { Write-Host $TotRDPInactiveSessions -ForegroundColor Red } Else { Write-Host $TotRDPInactiveSessions -ForegroundColor Green }
		
			# Number of Total RDP Sessions
			Write-Host -nonewline 'Total RDP Sessions: '
			if ($TotRDPSessions -eq 0) { Write-Host $TotRDPSessions -ForegroundColor Red } Else { Write-Host $TotRDPSessions -ForegroundColor Green }
			Write-Host ''
		
			# Avarege Time
			$Avg = 0
			$PingServer = Test-Connection -count 3 $ComputerRemoto
			$Avg = ($PingServer | Measure-Object ResponseTime -average)
			$Calc = [System.Math]::Round($Avg.average)
			Write-Host -nonewline "Ping (ms): "
			Write-Host "$($Calc)" -ForegroundColor Green
				
			# CPU utilization
			$AVGProc = Invoke-Command -Session $Session -ScriptBlock { Get-WmiObject win32_processor | Measure-Object -property LoadPercentage -Average | Select-Object Average }
			$CPULoad = "$($AVGProc.Average)%"
			Write-Host -nonewline "CPU usage: "
			Write-Host "$($CPULoad)" -ForegroundColor Green
		
			# RAM utilization
			$OS = Invoke-Command -Session $Session -ScriptBlock { (Get-WmiObject -Class win32_operatingsystem | Select-Object @{Name = "MemoryUsage"; Expression = { “{0:N2}” -f ((($_.TotalVisibleMemorySize - $_.FreePhysicalMemory) * 100) / $_.TotalVisibleMemorySize) } }) }
			$MemLoad = "$($OS.MemoryUsage)%"
			Write-Host -nonewline "RAM usage: "
			Write-Host "$($MemLoad)" -ForegroundColor Green
		
			# C: free space
			$calc = 0
			$percFree = 0
			$driveData = Invoke-Command -Session $Session -ScriptBlock { (Invoke-Command { Get-PSDrive C } | Select-Object Used, Free) }
			$total = $driveData.Used + $driveData.Free
			$calc = [Math]::Round($driveData.Free / $total, 2)
			$percFree = $calc * 100
			Write-Host -nonewline "C: Free Space: "
			Write-Host "$($percFree)%" -ForegroundColor Green
		}
		else {
			Write-Host -nonewline "$($element.computername) Active RDP Sessions: "
			if ($TotRDPActiveSessions -eq 0) { Write-Host $TotRDPActiveSessions -ForegroundColor Red } Else { Write-Host $TotRDPActiveSessions -ForegroundColor Green }
		}
		Write-Host '------------------------------'
	}
	Catch {
		Write-Host "$($element.computername) not responding" -ForegroundColor Red
		Write-Host '------------------------------'
	}
}

$Data = Get-date
Write-Host ''
Write-Host '--------------------------------------------' -ForegroundColor Green
Write-Host ''
Write-Host "Number of servers scanned: $($ServerList.Count)" -ForegroundColor Green
Write-Host ''
Write-Host "End server scan: $Data" -ForegroundColor Green
Write-Host ''
Write-Host '--------------------------------------------' -ForegroundColor Green