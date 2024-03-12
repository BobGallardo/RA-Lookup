<#
.SYNOPSIS
This PowerShell module is designed to interact with the RetroAchievements.org API.

.DESCRIPTION
The module includes functions to retrieve various data from RetroAchievements.org, such as top users, game lists, user summaries, and more. It requires an API user name and key, which should be stored securely.

.NOTES
Author: bobbyG
API Details: https://retroachievements.org/APIDemo.php
#>

# Check for API credentials and prompt for them if not found
$RAcredsCheck = "$PSScriptRoot\RA_creds.xml"
if (-not (Test-Path -Path $RAcredsCheck -PathType Leaf)) {
    Set-RACredentials
}
$RAcreds = Import-Clixml $RAcredsCheck
$apiUser = $RAcreds.UserName
$apiKey = [System.Net.NetworkCredential]::new("", $RAcreds.Password).Password

<#
.SYNOPSIS
Prompts the user to enter their RetroAchievements credentials and saves them securely.

.DESCRIPTION
This function will ask the user for their RetroAchievements username and API key, then save these credentials securely to a file. If the credentials file already exists, it will be overwritten.

.EXAMPLE
Set-RACredentials

.NOTES
The credentials are stored in an encrypted XML file specific to the user's Windows account.
#>
function Set-RACredentials {
    [CmdletBinding()]
    param ()

    do {
        $credential = Get-Credential -Message "Enter your RetroAchievements username and the API key for the password."
        $credential | Export-Clixml -Path $RAcredsCheck
    }
    while (-not (Test-Path -Path $RAcredsCheck -PathType Leaf))
}

# Define a helper function to build API request URIs
function Build-RAUri {
    # Function definition remains the same as previously provided
}

# Define API interaction functions (e.g., Get-RATop10)
function Get-RATop10 {
    # Function definition remains the same as previously provided
}

# Additional functions follow the same template as Get-RATop10

