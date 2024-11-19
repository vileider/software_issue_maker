$MousePointerSize = @{
    Name = "Mouse Pointer Size"
    Width = 360 
    Height = 80
    Actions = @{
        Enable = {
            $CSharpSig = @"
            using System;
            using System.Runtime.InteropServices;
            public class WinAPI 
            {
                [DllImport("user32.dll", EntryPoint = "SystemParametersInfo", SetLastError=true)]
                public static extern bool SystemParametersInfo(uint uiAction, uint uiParam, uint pvParam, uint fWinIni);
                
                [DllImport("user32.dll", SetLastError=true)]
                public static extern IntPtr SendMessageTimeout(IntPtr hWnd, uint msg, IntPtr wParam, IntPtr lParam, uint fuFlags, uint uTimeout, IntPtr lpdwResult);
            }
"@
            $SizeChanger = Add-Type -TypeDefinition $CSharpSig -PassThru
            
            try {
                $result = $SizeChanger::SystemParametersInfo(0x0029, [UInt32]3, $null, 1)
                if (!$result) {
                    $errCode = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
                    Write-Host "SystemParametersInfo failed with error code: $errCode"
                }
                
                $SizeChanger::SystemParametersInfo(0x0057, 0, $null, 0)
                $SizeChanger::SendMessageTimeout([IntPtr]0xffff, 0x001A, [IntPtr]41, [IntPtr]0, 2, 5000, [IntPtr]0)
            } catch {
                Write-Host "Error: $_"
                $result = $false
            }
            
            Write-Host "Mouse pointer size set to Extra Large. Result: $result"
            return $result
        }
        Disable = {
            $CSharpSig = @"
            using System;
            using System.Runtime.InteropServices;
            public class WinAPI 
            {
                [DllImport("user32.dll", EntryPoint = "SystemParametersInfo", SetLastError=true)]
                public static extern bool SystemParametersInfo(uint uiAction, uint uiParam, uint pvParam, uint fWinIni);
                
                [DllImport("user32.dll", SetLastError=true)]
                public static extern IntPtr SendMessageTimeout(IntPtr hWnd, uint msg, IntPtr wParam, IntPtr lParam, uint fuFlags, uint uTimeout, IntPtr lpdwResult);
            }
"@
            $SizeChanger = Add-Type -TypeDefinition $CSharpSig -PassThru
            
            try {
                $result = $SizeChanger::SystemParametersInfo(0x0029, [UInt32]1, $null, 1)
                if (!$result) {
                    $errCode = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
                    Write-Host "SystemParametersInfo failed with error code: $errCode"
                }
                
                $SizeChanger::SystemParametersInfo(0x0057, 0, $null, 0)
                $SizeChanger::SendMessageTimeout([IntPtr]0xffff, 0x001A, [IntPtr]41, [IntPtr]0, 2, 5000, [IntPtr]0)
            } catch {
                Write-Host "Error: $_"
                $result = $false  
            }

            Write-Host "Mouse pointer size set to Normal. Result: $result"
            return $result
        }
    }
}

return $MousePointerSize