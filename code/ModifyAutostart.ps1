# Define the component
$MultiAppAutostart = @{
    Name = "Multi App Autostart"
    Width = 360
    Height = 80
    Actions = @{
        Enable = {
            try {
                # Path to the user's Startup folder
                $StartupFolder = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"

                # List of applications to add to autostart with their paths
                $Apps = @(
                    @{Name = "Notepad"; Path = "$env:WinDir\System32\notepad.exe"},
                    @{Name = "Control Panel"; Path = "control"},
                    @{Name = "Task Manager"; Path = "$env:WinDir\System32\Taskmgr.exe"},
                    @{Name = "Calculator"; Path = "$env:WinDir\System32\calc.exe"},
                    @{Name = "File Explorer"; Path = "explorer.exe"}
                )

                # Create shortcuts for each application
                $WScriptShell = New-Object -ComObject WScript.Shell
                foreach ($App in $Apps) {
                    $ShortcutName = "$($App.Name).lnk"
                    $ShortcutPath = Join-Path -Path $StartupFolder -ChildPath $ShortcutName
                    $Shortcut = $WScriptShell.CreateShortcut($ShortcutPath)
                    $Shortcut.TargetPath = $App.Path
                    $Shortcut.Save()
                    Write-Host "Added $($App.Name) to autostart." -ForegroundColor Green
                }

                Write-Host "All applications have been added to autostart." -ForegroundColor Green
                return $true
            } catch {
                Write-Host "Error adding applications to autostart: $_" -ForegroundColor Red
                return $false
            }
        }
        Disable = {
            try {
                # Path to the user's Startup folder
                $StartupFolder = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"

                # List of application shortcut names
                $ShortcutNames = @("Notepad.lnk", "Control Panel.lnk", "Task Manager.lnk", "Calculator.lnk", "File Explorer.lnk")

                # Remove shortcuts for each application
                foreach ($ShortcutName in $ShortcutNames) {
                    $ShortcutPath = Join-Path -Path $StartupFolder -ChildPath $ShortcutName
                    if (Test-Path $ShortcutPath) {
                        Remove-Item -Path $ShortcutPath -Force
                        Write-Host "Removed $ShortcutName from autostart." -ForegroundColor Green
                    } else {
                        Write-Host "$ShortcutName was not found in the autostart folder." -ForegroundColor Yellow
                    }
                }

                Write-Host "All application shortcuts have been removed from autostart." -ForegroundColor Green
                return $true
            } catch {
                Write-Host "Error removing applications from autostart: $_" -ForegroundColor Red
                return $false
            }
        }
    }
}

return $MultiAppAutostart
