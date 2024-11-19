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
                [MouseSwitch]::SwapMouseButton(1)
                Write-Host "Mouse buttons swapped successfully"
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
                [MouseSwitch]::SwapMouseButton(0)
                Write-Host "Mouse buttons restored successfully"
                return $true
            } catch {
                Write-Host "Error restoring mouse buttons: $_"
                return $false
            }
        }
    }
}

return $MouseSwitcher