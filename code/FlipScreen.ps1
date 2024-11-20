$ScreenFlipper = @{
    Name = "Screen Flipper"
    Width = 360
    Height = 80
    Actions = @{
        Enable = {
            Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;

public class ScreenFlipper {
    [DllImport("user32.dll")]
    public static extern bool EnumDisplaySettings(string deviceName, int modeNum, ref DEVMODE devMode);
    
    [DllImport("user32.dll")]
    public static extern int ChangeDisplaySettings(ref DEVMODE devMode, int flags);

    [StructLayout(LayoutKind.Sequential)]
    public struct DEVMODE {
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)]
        public string dmDeviceName;
        public short dmSpecVersion;
        public short dmDriverVersion;
        public short dmSize;
        public short dmDriverExtra;
        public int dmFields;
        public int dmPositionX;
        public int dmPositionY;
        public int dmDisplayOrientation;
        public int dmDisplayFixedOutput;
        public short dmColor;
        public short dmDuplex;
        public short dmYResolution;
        public short dmTTOption;
        public short dmCollate;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)]
        public string dmFormName;
        public short dmLogPixels;
        public int dmBitsPerPel;
        public int dmPelsWidth;
        public int dmPelsHeight;
        public int dmDisplayFlags;
        public int dmDisplayFrequency;
    }

    public const int ENUM_CURRENT_SETTINGS = -1;
    public const int CDS_UPDATEREGISTRY = 0x01;
    public const int DMDO_DEFAULT = 0;
    public const int DMDO_180 = 2;
    public const int DM_DISPLAYORIENTATION = 0x00000080;
}
'@
            try {
                $dm = New-Object ScreenFlipper+DEVMODE
                $dm.dmSize = [System.Runtime.InteropServices.Marshal]::SizeOf($dm)
                
                # Get current settings
                [ScreenFlipper]::EnumDisplaySettings($null, [ScreenFlipper]::ENUM_CURRENT_SETTINGS, [ref]$dm)
                
                # Store original orientation
                $script:originalOrientation = $dm.dmDisplayOrientation
                Write-Host "Original orientation: $($script:originalOrientation)"

                # Set orientation to 180 degrees (upside down)
                $dm.dmDisplayOrientation = [ScreenFlipper]::DMDO_180
                $dm.dmFields = [ScreenFlipper]::DM_DISPLAYORIENTATION

                # Apply changes
                $result = [ScreenFlipper]::ChangeDisplaySettings([ref]$dm, [ScreenFlipper]::CDS_UPDATEREGISTRY)
                
                if ($result -eq 0) {
                    Write-Host "Screen flipped successfully"
                    return $true
                } else {
                    Write-Host "Failed to flip screen. Error code: $result"
                    return $false
                }
            }
            catch {
                Write-Host "Error flipping screen: $_"
                return $false
            }
        }
        Disable = {
            try {
                $dm = New-Object ScreenFlipper+DEVMODE
                $dm.dmSize = [System.Runtime.InteropServices.Marshal]::SizeOf($dm)
                
                # Get current settings
                [ScreenFlipper]::EnumDisplaySettings($null, [ScreenFlipper]::ENUM_CURRENT_SETTINGS, [ref]$dm)
                
                # Restore original orientation
                $dm.dmDisplayOrientation = [ScreenFlipper]::DMDO_DEFAULT
                $dm.dmFields = [ScreenFlipper]::DM_DISPLAYORIENTATION
                
                # Apply changes
                $result = [ScreenFlipper]::ChangeDisplaySettings([ref]$dm, [ScreenFlipper]::CDS_UPDATEREGISTRY)
                
                if ($result -eq 0) {
                    Write-Host "Screen orientation restored"
                    return $true
                } else {
                    Write-Host "Failed to restore screen orientation. Error code: $result"
                    return $false
                }
            }
            catch {
                Write-Host "Error restoring screen orientation: $_"
                return $false
            }
        }
    }
}

return $ScreenFlipper