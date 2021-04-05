# RA-Lookup
This Powershell module that will communicate with the RetroAchievements API (https://retroachievements.org/APIDemo.php) and allow you to capture public user profile data.<br>
<br>
<h2>Requirements:</h2>
Enter your RetroAchievements username and API key when you import the module. You can run RA_GetCreds.ps1 in the module directory if you need to manually add your API key.
<br><br><h2>In Progress:</h2> 
<li>An update to a couple of the functions that will pass additional variables to the API call.</li> 
<li>Complete help documentation for all functions.</li> 
<br><h2>Troubleshooting:</h2>
You may need to unblock the .ps1 and .psm1 files 
<br><code>
Unblock-File RA_GetCreds.ps1
</code>
<br><code>
Unblock-File RA_Lookup.psm1
</code>
