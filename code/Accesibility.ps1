# Define the component
$MousePointerSize = @{
    Name = "Mouse Pointer Size"
    Width = 360
    Height = 80
    Actions = @{
        Enable = {
            try {
                # Set registry key for large pointer size (e.g., 15)
                Set-ItemProperty -Path "HKCU:\Control Panel\Cursors" -Name "CursorBaseSize" -Value 45
                Write-Host "Cursor size set to Large. Updating settings..."
                
                # Apply changes
                rundll32.exe user32.dll, UpdatePerUserSystemParameters
                Write-Host "Mouse pointer size set to Large."
                return $true
            } catch {
                Write-Host "Error setting mouse pointer size: $_" -ForegroundColor Red
                return $false
            }
        }
        Disable = {
            try {
                # Reset registry key for default pointer size (e.g., 10)
                Set-ItemProperty -Path "HKCU:\Control Panel\Cursors" -Name "CursorBaseSize" -Value 10
                Write-Host "Cursor size set to Normal. Updating settings..."
                
                # Apply changes
                rundll32.exe user32.dll, UpdatePerUserSystemParameters
                Write-Host "Mouse pointer size reset to Normal."
                return $true
            } catch {
                Write-Host "Error resetting mouse pointer size: $_" -ForegroundColor Red
                return $false
            }
        }
    }
}

return $MousePointerSize
