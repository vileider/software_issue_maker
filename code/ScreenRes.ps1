$ScreenRes = @{
    Name = "Screen Resolution"
    Width = 360
    Height = 80
    Actions = @{
        Enable = {
            try {
                # Add required type
                Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;

public class Resolution
{
    [DllImport("user32.dll")]
    public static extern int ChangeDisplaySettings(ref DEVMODE devMode, int flags);

    [DllImport("user32.dll")]
    public static extern bool EnumDisplaySettings(string deviceName, int modeNum, ref DEVMODE devMode);

    [StructLayout(LayoutKind.Sequential)]
    public struct DEVMODE
    {
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)]
        public string dmDeviceName;
        public short dmSpecVersion;
        public short dmDriverVersion;
        public short dmSize;
        public short dmDriverExtra;
        public int dmFields;
        public short dmOrientation;
        public short dmPaperSize;
        public short dmPaperLength;
        public short dmPaperWidth;
        public short dmScale;
        public short dmCopies;
        public short dmDefaultSource;
        public short dmPrintQuality;
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

    private const int ENUM_CURRENT_SETTINGS = -1;
    private const int CDS_UPDATEREGISTRY = 0x01;
    private const int CDS_TEST = 0x02;
    private const int DISP_CHANGE_SUCCESSFUL = 0;

    public static bool ChangeResolution(int width, int height)
    {
        DEVMODE dm = new DEVMODE();
        dm.dmSize = (short)Marshal.SizeOf(dm);

        if (!EnumDisplaySettings(null, ENUM_CURRENT_SETTINGS, ref dm))
        {
            return false;
        }

        dm.dmPelsWidth = width;
        dm.dmPelsHeight = height;
        dm.dmFields = 0x80000 | 0x100000;  // DM_PELSWIDTH | DM_PELSHEIGHT

        int result = ChangeDisplaySettings(ref dm, CDS_UPDATEREGISTRY);
        return result == DISP_CHANGE_SUCCESSFUL;
    }

    public static bool GetCurrentResolution(out int width, out int height)
    {
        DEVMODE dm = new DEVMODE();
        dm.dmSize = (short)Marshal.SizeOf(dm);
        width = 0;
        height = 0;

        if (EnumDisplaySettings(null, ENUM_CURRENT_SETTINGS, ref dm))
        {
            width = dm.dmPelsWidth;
            height = dm.dmPelsHeight;
            return true;
        }
        return false;
    }
}
'@
                # Get and store current resolution
                $currentWidth = 0
                $currentHeight = 0
                $success = [Resolution]::GetCurrentResolution([ref]$currentWidth, [ref]$currentHeight)
                
                if ($success) {
                    $script:originalWidth = $currentWidth
                    $script:originalHeight = $currentHeight
                    Write-Host "Current resolution: $($script:originalWidth)x$($script:originalHeight)"

                    # Change to 800x600
                    Write-Host "Attempting to change resolution to 800x600..."
                    if ([Resolution]::ChangeResolution(800, 600)) {
                        Write-Host "Resolution changed successfully"
                        return $true
                    } else {
                        Write-Host "Failed to change resolution"
                        return $false
                    }
                } else {
                    Write-Host "Failed to get current resolution"
                    return $false
                }
            } catch {
                Write-Host "Error changing resolution: $_"
                return $false
            }
        }
        Disable = {
            try {
                if ($script:originalWidth -and $script:originalHeight) {
                    Write-Host "Restoring resolution to $($script:originalWidth)x$($script:originalHeight)"
                    if ([Resolution]::ChangeResolution($script:originalWidth, $script:originalHeight)) {
                        Write-Host "Resolution restored successfully"
                        return $true
                    } else {
                        Write-Host "Failed to restore resolution"
                        return $false
                    }
                }
                return $false
            } catch {
                Write-Host "Error restoring resolution: $_"
                return $false
            }
        }
    }
}

return $ScreenRes