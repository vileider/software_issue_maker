# Main.ps1
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create main form
$form = New-Object System.Windows.Forms.Form
$form.Text = "System Controller"
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false

# Function to load component
function Load-Component {
    param (
        [string]$filePath
    )
    
    if (Test-Path $filePath) {
        return & $filePath
    }
    return $null
}

# Function to create component panel
function Create-ComponentPanel {
    param (
        $component,
        $yPosition
    )
    
    Write-Host "Creating panel for $($component.Name) at position $yPosition"
    
    # Create main container
    $groupBox = New-Object System.Windows.Forms.GroupBox
    $groupBox.Location = New-Object System.Drawing.Point(10, $yPosition)
    $groupBox.Size = New-Object System.Drawing.Size($component.Width, $component.Height)
    $groupBox.Text = $component.Name
    
    # Create status indicator as button (more reliable than Label)
    $statusButton = New-Object System.Windows.Forms.Button
    $statusButton.Location = New-Object System.Drawing.Point(20, 30)
    $statusButton.Size = New-Object System.Drawing.Size(15, 15)
    $statusButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $statusButton.BackColor = [System.Drawing.Color]::Red
    $statusButton.Enabled = $false
    
    # Create Enable button
    $enableButton = New-Object System.Windows.Forms.Button
    $enableButton.Location = New-Object System.Drawing.Point(50, 25)
    $enableButton.Size = New-Object System.Drawing.Size(80, 30)
    $enableButton.Text = "Enable"
    
    # Create Disable button
    $disableButton = New-Object System.Windows.Forms.Button
    $disableButton.Location = New-Object System.Drawing.Point(140, 25)
    $disableButton.Size = New-Object System.Drawing.Size(80, 30)
    $disableButton.Text = "Disable"
    
    # Add click handlers
    $enableButton.Add_Click({
        Write-Host "Enable clicked for $($component.Name)"
        if (& $component.Actions.Enable) {
            $statusButton.BackColor = [System.Drawing.Color]::Green
            $statusButton.Refresh()
        }
    }.GetNewClosure())
    
    $disableButton.Add_Click({
        Write-Host "Disable clicked for $($component.Name)"
        if (& $component.Actions.Disable) {
            $statusButton.BackColor = [System.Drawing.Color]::Red
            $statusButton.Refresh()
        }
    }.GetNewClosure())
    
    # Add controls to group box
    $groupBox.Controls.Add($statusButton)
    $groupBox.Controls.Add($enableButton)
    $groupBox.Controls.Add($disableButton)
    
    return $groupBox
}

# Load all components from code directory
$codeDirectory = Join-Path $PSScriptRoot "code"
$yPosition = 10
$maxWidth = 400  # Default width

Write-Host "Starting software issues..."
Write-Host "Loading components from: $codeDirectory"

# Get all PS1 files from code directory
$componentFiles = Get-ChildItem -Path $codeDirectory -Filter "*.ps1"
Write-Host "Found $($componentFiles.Count) components"

foreach ($file in $componentFiles) {
    Write-Host "Loading component from: $($file.Name)"
    $component = Load-Component $file.FullName
    
    if ($component) {
        Write-Host "Creating panel for component: $($component.Name)"
        $panel = Create-ComponentPanel $component $yPosition
        [void]$form.Controls.Add($panel)
        $yPosition += $component.Height + 10
        
        # Update form width if component is wider
        $maxWidth = [Math]::Max($maxWidth, $component.Width + 30)
    }
}

# Set final form size
$formWidth = $maxWidth
$formHeight = $yPosition + 40
$form.Size = New-Object System.Drawing.Size $formWidth, $formHeight

# Show the form
$form.ShowDialog()