<#
.SYNOPSIS
    Launch the GUI for LocalUsers module

#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create the main form
$form = New-Object System.Windows.Forms.Form
$form.Text = 'Users App'
$form.Size = New-Object System.Drawing.Size(750,600)
$form.StartPosition = 'CenterScreen'

# Create DataGridView
$userGrid = New-Object System.Windows.Forms.DataGridView
$userGrid.Size = New-Object System.Drawing.Size(653,420)
$userGrid.Location = New-Object System.Drawing.Point(50,30)
$userGrid.AllowUserToAddRows = $false
$userGrid.AllowUserToDeleteRows = $false
$userGrid.MultiSelect = $true
$userGrid.SelectionMode = 'FullRowSelect'
$userGrid.RowHeadersVisible = $false
$userGrid.EnableHeadersVisualStyles = $false
$userGrid.ColumnHeadersDefaultCellStyle.SelectionBackColor = $userGrid.ColumnHeadersDefaultCellStyle.BackColor

# Create columns
$userGrid.Columns.Add("Username", "Username") | Out-Null
$userGrid.Columns.Add("AccountSource", "AccountSource") | Out-Null
$userGrid.Columns.Add("LocalPath", "LocalPath") | Out-Null
$userGrid.Columns.Add("isAdmin", "Admn") | Out-Null

# Set column widths
$userGrid.Columns["Username"].Width = 130
$userGrid.Columns["AccountSource"].Width = 120
$userGrid.Columns["LocalPath"].Width = 330
$userGrid.Columns["isAdmin"].Width = 70

# Create Remove button and Backup checkbox with larger sizes
$removeButton = New-Object System.Windows.Forms.Button
$removeButton.Location = New-Object System.Drawing.Point(50,460) 
$removeButton.Size = New-Object System.Drawing.Size(130,25)
$removeButton.Text = 'Remove selected'

$backupCheckbox = New-Object System.Windows.Forms.CheckBox
$backupCheckbox.Location = New-Object System.Drawing.Point(185,463) 
$backupCheckbox.Size = New-Object System.Drawing.Size(110,25)
$backupCheckbox.Text = "and Backup"

# Create horizontal separator line
$separator = New-Object System.Windows.Forms.Label
$separator.Location = New-Object System.Drawing.Point(50,495) 
$separator.Size = New-Object System.Drawing.Size(700,2)
$separator.BorderStyle = [System.Windows.Forms.BorderStyle]::Fixed3D

# Create new user controls
$usernameLabel = New-Object System.Windows.Forms.Label
$usernameLabel.Location = New-Object System.Drawing.Point(50,505) 
$usernameLabel.Size = New-Object System.Drawing.Size(75,20)
$usernameLabel.Text = 'Username:'

$usernameTextBox = New-Object System.Windows.Forms.TextBox
$usernameTextBox.Location = New-Object System.Drawing.Point(125,505) 
$usernameTextBox.Size = New-Object System.Drawing.Size(150,20)

$isAdminCheckbox = New-Object System.Windows.Forms.CheckBox
$isAdminCheckbox.Location = New-Object System.Drawing.Point(280,505) 
$isAdminCheckbox.Size = New-Object System.Drawing.Size(90,20)
$isAdminCheckbox.Text = 'isAdmin' # Internal text remains unchanged

# Moved Create button and increased size
$createButton = New-Object System.Windows.Forms.Button
$createButton.Location = New-Object System.Drawing.Point(380,503) 
$createButton.Size = New-Object System.Drawing.Size(100,23)
$createButton.Text = 'Create User'

# Function to populate the grid
function Update-UserGrid {
    $userGrid.Rows.Clear()
    # Assuming Get-User, New-User, Remove-User are available in the scope
    # Import-Module .\LocalUsers.psm1 -Force # Might be needed if functions are in a module
    $users = Get-User
    foreach ($user in $users) {
        $rowIndex = $userGrid.Rows.Add(
            $user.Username,
            $user.AccountSource,
            $user.LocalPath,
            $(if ($user.isAdmin) { "Yes" } else { "No" })
        )
        $userGrid.Rows[$rowIndex].Tag = $user
    }
}

# Add click handlers
$removeButton.Add_Click({
    if ($userGrid.SelectedRows.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("No users selected.", "Warning")
        return
    }

    foreach ($row in $userGrid.SelectedRows) {
        $user = $row.Tag
        # Basic check if Tag contains expected data
        if ($null -eq $user -or -not $user.PSObject.Properties.Name.Contains('SID')) {
             Write-Warning "Skipping row - user data or SID not found in Tag property."
             continue
        }
        $params = @{
            SID = $user.SID # Still need SID for removal logic
        }
        if ($backupCheckbox.Checked) {
            $params.Add('Backup', $true)
        }

        # Add basic error handling for the core function
        try {
            Remove-User @params -ErrorAction Stop
        } catch {
            [System.Windows.Forms.MessageBox]::Show("Error removing user $($user.Username): $($_.Exception.Message)", "Removal Error")
            # Decide whether to continue or stop on error
            # return # Stop processing
            continue # Continue with next selected user
        }


        [System.Windows.Forms.Application]::DoEvents() # Keep DoEvents to prevent GUI freeze during long operations
    }

    Update-UserGrid
})

$createButton.Add_Click({
    $newUsername = $usernameTextBox.Text.Trim() # Trim whitespace
    if ($newUsername) { # Check if not empty after trimming
        $params = @{
            Name = $newUsername
        }
        if ($isAdminCheckbox.Checked) {
            $params.Add('isAdmin', $true)
        }

        # Add basic error handling for the core function
        try {
            New-User @params -ErrorAction Stop
            Update-UserGrid

            $usernameTextBox.Text = ''
            $isAdminCheckbox.Checked = $false
        } catch {
             [System.Windows.Forms.MessageBox]::Show("Error creating user $($newUsername): $($_.Exception.Message)", "Creation Error")
        }

    } else {
         [System.Windows.Forms.MessageBox]::Show("Username cannot be empty.", "Input Error")
         $usernameTextBox.Focus()
    }
})

# Add all controls to the form
$form.Controls.AddRange(@(
    $userGrid,
    $removeButton,
    $backupCheckbox,
    $separator,
    $usernameLabel,
    $usernameTextBox,
    $isAdminCheckbox,
    $createButton
))

# Initial population of the grid
try {
    Update-UserGrid -ErrorAction Stop
} catch {
     [System.Windows.Forms.MessageBox]::Show("Error loading initial user list: $($_.Exception.Message)", "Loading Error")
}


# Show the form
# Using try/finally ensures Dispose is called even if ShowDialog errors
try {
    $form.ShowDialog()
}
finally {
    $form.Dispose()
}
