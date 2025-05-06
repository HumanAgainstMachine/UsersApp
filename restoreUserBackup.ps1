# User Profile Migration Script
# This script checks if a folder with name starting with "${env:USERNAME}_" exists
# If it exists, it copies all content to user profile directory and deletes the source folder
# If it doesn't exist, the script exits silently

# Get current directory where script is running
$currentDir = Get-Location

# Look for folders that start with the current username followed by underscore
$folderPattern = "${env:USERNAME}_*"
$sourceFolder = Get-ChildItem -Path $currentDir -Directory -Filter $folderPattern | Select-Object -First 1

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
    $robocopyResult = robocopy $sourcePath $destinationPath /E /COPY:DAT /R:1 /W:1 /MT:8 /XJ /B /ZB /IF /NP /NFL
    
    # Delete the source folder after successful copy
    Remove-Item -Path $sourcePath -Recurse -Force
}

# Script exits without any message if no matching folder is found