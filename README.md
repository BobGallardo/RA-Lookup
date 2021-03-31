# RA-Lookup
Here's a Powershell module that will communicate with the RetroAchievements API (https://retroachievements.org/APIDemo.php) and allow you to capture public user profile data.<br>
<br>
The only requirement is that you have your RetroAchievements user name and API key stored in a local "encrypted" file.<br>
Run this Powershell command in the same directory as the module to create the API key file.<br>
<br>
`Get-Credential -Message "Enter your RetroAchievements API key for the password." | Export-Clixml -Path .\RAcreds.xml`
