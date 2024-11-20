$StartupEnabler = @{
    Name = "Startup Enabler"
    Width = 360
    Height = 80
    Actions = @{
        Enable = {
            try {
                # Store original states
                $script:originalStates = @{}
                
                # Registry paths for startup states
                $startupApprovedPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\StartupFolder"
                $startupRunPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run"
                
                # Function to enable startup item
                function Enable-StartupItem {
                    param($keyPath, $itemName)
                    try {
                        if (Test-Path $keyPath) {
                            $value = (Get-ItemProperty -Path $keyPath -Name $itemName -ErrorAction SilentlyContinue).$itemName
                            if ($value) {
                                # Store original state
                                $script:originalStates[$itemName] = $value
                                
                                # Create new byte array for "Enabled" state
                                $newValue = [byte[]]@(2,0,0,0,0,0,0,0,0,0,0,0)
                                
                                # Set new value
                                Set-ItemProperty -Path $keyPath -Name $itemName -Value $newValue
                                Write-Host "Enabled startup item: $itemName"
                            }
                        }
                    } catch {
                        Write-Host "Error processing $itemName : $_"
                    }
                }
                
                # Get all .lnk files from Startup folder
                $startupFolder = [Environment]::GetFolderPath('Startup')
                $startupFiles = Get-ChildItem -Path $startupFolder -Filter "*.lnk"
                
                foreach ($file in $startupFiles) {
                    Write-Host "Processing startup link: $($file.Name)"
                    Enable-StartupItem $startupApprovedPath $file.Name
                }

                # Handle Run registry items
                $runKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
                if (Test-Path $runKey) {
                    Get-Item $runKey | Select-Object -ExpandProperty Property | ForEach-Object {
                        Write-Host "Processing Run item: $_"
                        Enable-StartupItem $startupRunPath $_
                    }
                }
                
                # Additional registry method to force enable
                $disableKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run32"
                if (Test-Path $disableKey) {
                    $props = Get-ItemProperty $disableKey
                    $props.PSObject.Properties | Where-Object { $_.Name -notlike "PS*" } | ForEach-Object {
                        try {
                            $newValue = [byte[]]@(2,0,0,0,0,0,0,0,0,0,0,0)
                            Set-ItemProperty -Path $disableKey -Name $_.Name -Value $newValue
                            Write-Host "Enabled startup item (alternate method): $($_.Name)"
                        } catch {
                            Write-Host "Error enabling $($_.Name): $_"
                        }
                    }
                }

                Write-Host "All startup items processed"
                return $true

            } catch {
                Write-Host "Error enabling startups: $_"
                return $false
            }
        }
        Disable = {
            try {
                # Restore original states
                foreach ($item in $script:originalStates.GetEnumerator()) {
                    $keyPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\StartupFolder"
                    if (!(Test-Path $keyPath)) { continue }
                    
                    try {
                        Set-ItemProperty -Path $keyPath -Name $item.Key -Value $item.Value
                        Write-Host "Restored original state for: $($item.Key)"
                    } catch {
                        Write-Host "Error restoring $($item.Key): $_"
                    }
                }

                Write-Host "Restored original startup states where possible"
                return $true
            } catch {
                Write-Host "Error restoring startup states: $_"
                return $false
            }
        }
    }
}

return $StartupEnabler