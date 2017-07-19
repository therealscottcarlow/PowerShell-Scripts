<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2016 v5.2.122
	 Created on:   	6/3/2016 08:37
	 Created by:   	Scott Carlow
	 Organization: 	Dynamic Network Solutions
	 Filename:     	ChangePowerProfile.PS1
	===========================================================================
	.DESCRIPTION
		This script changes the power profile to High performance, deploys a process or waits for a process to finish, 
        then changes it back to the previous active profile if different.
    
	.SYNOPSIS 
		This script uses Powershell to wrap around powercfg.exe. The reason we are using Powershell instead 
		of calling Powerecfg with the appropriate info via psexec or a batch file is our ability to easily
		store and use variables. We manually set the Windows built-in 'High Performance' profile for the sake 
		of software deployment, deploy the software and make the script wait until the process completes, then 
		it sets the previous powerplan using information we retreived from powercfg before changing the profile.
		A function is made called Set-PowerProfile. It can be used without performing the rest of the script 
		functions, but the previous plan variable will be lost if you close the session.

	.EXAMPLE
		Set-PowerProfile -Name [$HighPerformance | $Balanced | $PowerSaver | $EnergyStar | $Previous]
#>
# Pre-define the system power plans

$HighPerformance = '8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c'
$Balanced = '381b4222-f694-41f0-9685-ff5bb260df2e'
$PowerSaver = 'a1841308-3541-4fab-bc81-f71556f20b4a'
$EnergyStar = 'de7ef2ae-119c-458b-a5a3-997c2221e76e'

# And now to pull the curent power plan

$currScheme = POWERCFG -GETACTIVESCHEME | Select-String "power scheme guid" -List
$Previous = $currScheme.tostring().split(" ") | where { ($_.length -eq 36) -and ([guid]$_) }

# Create of function for easy re-use of the same command

function Set-PowerProfile($Name)
{
	$ProfileCheck = POWERCFG -GETACTIVESCHEME
	if ($ProfileCheck -notcontains $Name) {
		PowerCfg -SetActive $Name
	}
	else
	{
		break
	}
}

# The actual script.
Try
{
	if ((Get-Process -name setup -ErrorAction SilentlyContinue) -eq $null)
	{
		Set-PowerProfile "$HighPerformance"
		Start-Process @DeployDirectory@\Path\To\setup -NoNewWindow -Wait -ArgumentList <comma separated arguments> -ErrorAction SilentlyContinue
		Set-PowerProfile "$Previous"
	}
	else
	{
		$ProfileCheck = POWERCFG -GETACTIVESCHEME
		if ($ProfileCheck -notcontains $HighPerformance)
		{
			$ProcessID = (Get-Process <name> -ErrorAction SilentlyContinue).id
			Set-PowerProfile "$HighPerformance"
			Wait-Process -Id $ProcessID
			Set-PowerProfile "$Previous"
		}
		
	}
}
# Error Handling. Writes to event log and console so it can be monitored if need be.
Catch
{
	Write-Warning $_.Exception
}
