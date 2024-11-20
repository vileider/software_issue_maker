$StartupEnabler = @{
    Name = "Startup Enabler"
    Width = 360
    Height = 80
    Actions = @{
        Enable = {
            try {
                # Store original states
                $script:originalStates = @()
                
                # Enable startups in Registry Run (User level only)
                $regPaths = @(
                    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run",
                    "HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce"
                )

                foreach ($path in $regPaths) {
                    if (Test-Path $path) {
                        Get-Item $path | Select-Object -ExpandProperty Property | ForEach-Object {
                            Write-Host "Enabling user registry startup: $_"
                        }
                    }
                }

                # Enable Task Scheduler startups (only user tasks)
                Write-Host "Enabling user scheduled task startups..."
                Get-ScheduledTask | Where-Object {
                    $_.State -eq "Disabled" -and 
                    $_.Principal.UserId -eq [System.Security.Principal.WindowsIdentity]::GetCurrent().Name -and
                    -not $_.TaskPath.StartsWith("\Microsoft\") -and
                    -not $_.TaskPath.StartsWith("\Windows")
                } | ForEach-Object {
                    Write-Host "Processing task: $($_.TaskName)"
                    try {
                        $script:originalStates += @{
                            Name = $_.TaskName
                            Path = $_.TaskPath
                            State = $_.State
                        }
                        Enable-ScheduledTask -TaskName $_.TaskName -TaskPath $_.TaskPath -ErrorAction Stop
                        Write-Host "Enabled task: $($_.TaskName)"
                    }
                    catch {
                        Write-Host "Skipping task due to permissions: $($_.TaskName)"
                    }
                }

                # Enable MSConfig user startups
                $regPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run"
                if (Test-Path $regPath) {
                    $items = Get-Item -Path $regPath
                    $items.Property | ForEach-Object {
                        try {
                            $data = (Get-ItemProperty -Path $regPath -Name $_).$_
                            $data[0] = 2  # Enable startup
                            Set-ItemProperty -Path $regPath -Name $_ -Value $data
                            Write-Host "Enabled user MSConfig startup: $_"
                        }
                        catch {
                            Write-Host "Skipping MSConfig item due to permissions: $_"
                        }
                    }
                }

                # Find user startup folder items
                $startupFolder = [Environment]::GetFolderPath('Startup')
                if (Test-Path $startupFolder) {
                    Get-ChildItem -Path $startupFolder | ForEach-Object {
                        Write-Host "Found startup item: $($_.Name)"
                    }
                }

                Write-Host "User startup items have been enabled"
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
                            try {
                                Disable-ScheduledTask -TaskName $task.Name -TaskPath $task.Path -ErrorAction Stop
                                Write-Host "Restored task state: $($task.Name)"
                            }
                            catch {
                                Write-Host "Could not restore task: $($task.Name)"
                            }
                        }
                    }
                }

                Write-Host "Restored original user startup states where possible"
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