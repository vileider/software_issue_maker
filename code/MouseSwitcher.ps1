# Define the component
$MouseSwitcher = @{
    Name = "Mouse Switcher"
    Width = 360
    Height = 80
    Actions = @{
        Enable = {
            Add-Type -TypeDefinition @'
using System.Runtime.InteropServices;
public class MouseSwitch {
    [DllImport("user32.dll")]
    public static extern int SwapMouseButton(int swap);
}
'@
            try {
                # Change current state
                [MouseSwitch]::SwapMouseButton(1)
                
                # Update registry for persistence
                $regPath = "HKCU:\Control Panel\Mouse"
                Set-ItemProperty -Path $regPath -Name "SwapMouseButtons" -Value "1"
                
                Write-Host "Mouse buttons swapped successfully and set to persist"
                return $true
            } catch {
                Write-Host "Error swapping mouse buttons: $_"
                return $false
            }
        }
        Disable = {
            Add-Type -TypeDefinition @'
using System.Runtime.InteropServices;
public class MouseSwitch {
    [DllImport("user32.dll")]
    public static extern int SwapMouseButton(int swap);
}
'@
            try {
                # Change current state
                [MouseSwitch]::SwapMouseButton(0)
                
                # Update registry for persistence
                $regPath = "HKCU:\Control Panel\Mouse"
                Set-ItemProperty -Path $regPath -Name "SwapMouseButtons" -Value "0"
                
                Write-Host "Mouse buttons restored successfully and set to persist"
                return $true
            } catch {
                Write-Host "Error restoring mouse buttons: $_"
                return $false
            }
        }
    }
}

return $MouseSwitcher