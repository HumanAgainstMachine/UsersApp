# User Profile Migration Script

# Get path to profile backups
$backupDir = (Split-Path -Qualifier $env:windir) + "\UsersApp\backups"

# Look for folders that start with the current username followed by underscore
$folderPattern = "${env:USERNAME}_*"
$sourceFolder = Get-ChildItem -Path $backupDir -Directory -Filter $folderPattern | Select-Object -First 1

# If a matching folder is found, proceed with copying
if ($sourceFolder) {
    $sourcePath = $sourceFolder.FullName
    $destinationPath = $env:USERPROFILE
    
    # Use robocopy to copy all contents to user profile
    # /E - Copy subdirectories, including empty ones
    # /COPY:DAT - Copy Data, Attributes, and Timestamps
    # /R:1 - Retry once on fail
    # /W:1 - Wait 1 second between retries
    # /MT - Multithreaded copying with 8 threads
    # /XJ - Skip junction points (to avoid potential loops)
    # /B - Use backup mode (allows copying of files that would otherwise be restricted)
    # /ZB - Use restartable mode, if access denied use backup mode
    # /IF - Ignore failures
    # /NP - No progress
    # /NFL - No file list
     & robocopy $sourcePath $destinationPath /E /COPY:DAT /XJ /R:1 /W:1 /IF /NP /NFL | Out-Null
    
    # Delete the source folder after successful copy
    Remove-Item -Path $sourcePath -Recurse -Force
}

# Script exits without any message if no matching folder is found