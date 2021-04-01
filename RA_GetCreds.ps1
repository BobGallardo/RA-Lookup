$RAcredsCheck = ".\RA_creds.xml"

while (-not(Test-Path -Path $RAcredsCheck -PathType Leaf)) {
    Get-Credential -Message "Enter your RetroAchievements username and the API key for the password." | Export-Clixml -Path .\RA_creds.xml
}