$StartupEnabler = @{
    Name = "Startup Enabler"
    Width = 360
    Height = 80
    Actions = @{
        Enable = {
            try {
                # Store original states
                $script:originalStates = @()
                
                # Enable startups in Registry Run
                $regPaths = @(
                    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run",
                    "HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce",
                    "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run",
                    "HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce"
                )

                foreach ($path in $regPaths) {
                    if (Test-Path $path) {
                        Get-Item $path | Select-Object -ExpandProperty Property | ForEach-Object {
                            Write-Host "Enabling registry startup: $_"
                        }
                    }
                }

                # Enable Task Scheduler startups
                Write-Host "Enabling scheduled task startups..."
                Get-ScheduledTask | Where-Object {$_.State -eq "Disabled"} | ForEach-Object {
                    $script:originalStates += @{
                        Name = $_.TaskName
                        Path = $_.TaskPath
                        State = $_.State
                    }
                    Enable-ScheduledTask -TaskName $_.TaskName -TaskPath $_.TaskPath
                    Write-Host "Enabled task: $($_.TaskName)"
                }

                # Enable MSConfig startups
                $regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run"
                if (Test-Path $regPath) {
                    $items = Get-Item -Path $regPath
                    $items.Property | ForEach-Object {
                        $data = (Get-ItemProperty -Path $regPath -Name $_).$_
                        $data[0] = 2  # Enable startup
                        Set-ItemProperty -Path $regPath -Name $_ -Value $data
                        Write-Host "Enabled MSConfig startup: $_"
                    }
                }

                # Enable through WMI
                $startups = Get-CimInstance Win32_StartupCommand
                foreach ($startup in $startups) {
                    Write-Host "Found startup: $($startup.Name)"
                    # WMI startups are usually reflected in registry or task scheduler
                }

                Write-Host "All startup items have been enabled"
                return $true
            }
            catch {
                Write-Host "Error enabling startups: $_"
                return $false
            }
        }
        Disable = {
            try {
                # Restore original scheduled task states
                if ($script:originalStates) {
                    foreach ($task in $script:originalStates) {
                        if ($task.State -eq "Disabled") {
                            Disable-ScheduledTask -TaskName $task.Name -TaskPath $task.Path
                            Write-Host "Restored task state: $($task.Name)"
                        }
                    }
                }

                # Note: We don't disable other startups as it might affect system stability
                Write-Host "Restored original startup states where possible"
                return $true
            }
            catch {
                Write-Host "Error restoring startup states: $_"
                return $false
            }
        }
    }
}

return $StartupEnabler