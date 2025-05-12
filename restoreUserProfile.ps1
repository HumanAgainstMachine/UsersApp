<#
.SYNOPSIS
    Automated script to restore a user's profile data upon logon and perform cleanup.

.DESCRIPTION
    This script is automatically generated and scheduled by the 'Reset-User' cmdlet
    (from the LocalUsers module) to run when a user logs on for the first time after
    their account has been reset.

    It performs the following actions:
    1. Identifies the current user and locates their profile backup in
       "C:\UsersApp\backups\<username>".
    2. If the backup directory exists, it uses Robocopy to restore the profile contents
       (Desktop, Documents, etc.) to the user's current profile path ($env:USERPROFILE).
       - Key Robocopy options: /E (subdirectories), /COPY:DAT (data, attributes, timestamps),
         /XJ (exclude junction points).
    3. After a successful restoration, the source backup folder
       ("C:\UsersApp\backups\<username>") is deleted to save space.
    4. Finally, it unregisters the scheduled task (e.g., "Restore_<username>_Profile")
       that launched this script, ensuring it only executes once.

.NOTES
    - This script is intended for unattended execution via a scheduled task under the
      user's context. It does not require manual intervention.
    - The backup location "C:\UsersApp\backups\<username>" is predetermined by the
      'Backup-UserProfile' function, which is called by 'Reset-User'.
    - The script path "C:\UsersApp\restoreUserProfile.ps1" is also defined by the
      'Reset-User' cmdlet when it creates this script and the associated scheduled task.
    - If the backup path is not found, the script will proceed to unregister the
      scheduled task without attempting a restore.
#>


# Get path to current user's profile backups
$driveLetter = Split-Path -Path $env:windir -Qualifier
$profilePath = Join-Path -Path $driveLetter -ChildPath "UsersApp\backups\$($env:USERNAME.ToLower())"

if (Test-Path -Path $profilePath) {
    $destinationPath = $env:USERPROFILE

    # /NP - No progress
    # /NFL - No file list
     & robocopy $profilePath $destinationPath /E /COPY:DAT /XJ /R:1 /W:1 /NP /NFL | Out-Null
    
    # Delete the source folder after successful copy
    Remove-Item -Path $profilePath -Recurse -Force
}


# Task name to remove (should match the registered task name)
$taskToRemove = "Restore_${env:USERNAME}_Profile"

# Remove the task without asking for confirmation
Unregister-ScheduledTask -TaskName $taskToRemove -Confirm:$false
