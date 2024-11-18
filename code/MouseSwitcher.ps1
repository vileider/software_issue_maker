# Load required assemblies for GUI
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Add the Windows API function
$code = @'
using System.Runtime.InteropServices;
public class MouseSwitch {
    [DllImport("user32.dll")]
    public static extern int SwapMouseButton(int swap);
}
'@
Add-Type -TypeDefinition $code

# Create the form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Mouse Button Switcher"
$form.Size = New-Object System.Drawing.Size(300,200)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false

# Create the main button
$switchButton = New-Object System.Windows.Forms.Button
$switchButton.Location = New-Object System.Drawing.Point(50,30)
$switchButton.Size = New-Object System.Drawing.Size(200,40)
$switchButton.Text = "Switch Mouse Buttons"
$switchButton.BackColor = [System.Drawing.Color]::LightBlue

# Create status label
$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Location = New-Object System.Drawing.Point(50,90)
$statusLabel.Size = New-Object System.Drawing.Size(200,30)
$statusLabel.TextAlign = "MiddleCenter"
$statusLabel.Text = "Current: Normal Setup"

# Track button state
$script:isSwapped = $false

# Add click event to button
$switchButton.Add_Click({
    $script:isSwapped = !$script:isSwapped
    [MouseSwitch]::SwapMouseButton([int]$isSwapped)
    
    if ($isSwapped) {
        $switchButton.Text = "Restore Default"
        $statusLabel.Text = "Current: Buttons Swapped"
        $switchButton.BackColor = [System.Drawing.Color]::LightCoral
    } else {
        $switchButton.Text = "Switch Mouse Buttons"
        $statusLabel.Text = "Current: Normal Setup"
        $switchButton.BackColor = [System.Drawing.Color]::LightBlue
    }
})

# Add controls to form
$form.Controls.Add($switchButton)
$form.Controls.Add($statusLabel)

# Show the form
$form.ShowDialog()