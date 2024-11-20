$NotepadSpam = @{
    Name = "Notepad Spam"
    Width = 360
    Height = 80
    Actions = @{
        Enable = {
            try {
                # Create bat file content
                $batContent = @'
:loop
@echo How to stop me? > "%temp%\spam.txt"
start /min notepad "%temp%\spam.txt"
timeout /t 15 /nobreak
goto loop
'@
                
                # Get startup folder path
                $startupPath = [Environment]::GetFolderPath('Startup')
                $batPath = Join-Path $startupPath "notepad_spam.bat"
                
                # Save bat file
                $batContent | Out-File -FilePath $batPath -Encoding ASCII

                # Start the batch file
                Start-Process $batPath -WindowStyle Hidden
                
                Write-Host "Notepad spam activated and set to persist"
                return $true
            } catch {
                Write-Host "Error setting up notepad spam: $_"
                return $false
            }
        }
        Disable = {
            try {
                # Get startup folder path
                $startupPath = [Environment]::GetFolderPath('Startup')
                $batPath = Join-Path $startupPath "notepad_spam.bat"
                
                # Kill all notepads running with our spam file
                Get-Process | Where-Object { $_.ProcessName -eq "notepad" } | ForEach-Object {
                    try {
                        $_ | Stop-Process -Force
                    } catch {
                        Write-Host "Error stopping notepad: $_"
                    }
                }
                
                # Delete bat file if it exists
                if (Test-Path $batPath) {
                    Remove-Item $batPath -Force
                }
                
                # Delete spam text file if it exists
                $spamFile = "$env:TEMP\spam.txt"
                if (Test-Path $spamFile) {
                    Remove-Item $spamFile -Force
                }
                
                Write-Host "Notepad spam deactivated"
                return $true
            } catch {
                Write-Host "Error removing notepad spam: $_"
                return $false
            }
        }
    }
}

return $NotepadSpam