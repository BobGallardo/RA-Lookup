## Powershell function to display the top 10 players on RetroAchievements.org and to test my PS abilities, or lack there of.
# API details at https://retroachievements.org/APIDemo.php
# Authored by bobbyG

$RAcredsCheck = "$PSScriptRoot\RA_creds.xml"
If (-not(Test-Path -Path $RAcredsCheck -PathType Leaf)) {
    Set-Content -path $PSScriptRoot\RA_Error.txt -Value 'Please run the following command to add your RetroAchievements API key'
    Add-Content -path $PSScriptRoot\RA_Error.txt -Value 'Get-Credential -Message "Enter your RetroAchievements username and the API key for the password." | Export-Clixml -Path $PSScriptRoot\RA_creds.xml'
    break
}
else {
    $RAcreds = Import-Clixml $RAcredsCheck
    $apiUser = $RAcreds.UserName
    $apiKey = ConvertFrom-SecureString -AsPlainText $RAcreds.Password
}
function Get-RATop10 {
    param ()
    <#
 .SYNOPSIS
  Captures achievement data from RetroAchievements.org.

 .DESCRIPTION
  Captures the Top 10 players on RetroAchievements (Username, Points, True Ratio).

 .EXAMPLE
  Get-RATop10
#>
    $action = 'API_GetTopTenUsers.php'
    $builder = New-Object System.UriBuilder
    $builder.Scheme = 'https'
    $builder.Host = 'retroachievements.org'
    $builder.Port = 443
    $builder.Path = ('API', "$action" -join '/')
    $builder.Query = ("z=$apiUser", "y=$apiKey" -join '&')
    $uri = $builder.ToString()
    $top10 = Invoke-RestMethod -Uri $uri
    return $top10
}
function Get-RAConID {
    param ()
    $action = 'API_GetConsoleIDs.php'
    $builder = New-Object System.UriBuilder
    $builder.Scheme = 'https'
    $builder.Host = 'retroachievements.org'
    $builder.Port = 443
    $builder.Path = ('API', "$action" -join '/')
    $builder.Query = ("z=$apiUser", "y=$apiKey" -join '&')
    $uri = $builder.ToString()
    $consoleIDs = Invoke-RestMethod -Uri $uri
    return $consoleIDs
}
function Get-RAGameList {
    <#
 .SYNOPSIS
  Captures achievement data from RetroAchievements.org.

 .DESCRIPTION
  Lists all the games on the console specified. Get the console ID with the Get-RAConID cmdlet.

 .EXAMPLE
   Get-RAGameList $consoleID
   Get-RAGameList 13
#>
    param (
        [Parameter(Mandatory)][int]$consoleID
    )
    $action = 'API_GetGameList.php'
    $builder = New-Object System.UriBuilder
    $builder.Scheme = 'https'
    $builder.Host = 'retroachievements.org'
    $builder.Port = 443
    $builder.Path = ('API', "$action" -join '/')
    $builder.Query = ("z=$apiUser", "y=$apiKey", "i=$consoleID" -join '&')
    $uri = $builder.ToString()
    $gameList = Invoke-RestMethod -Uri $uri
    return $gameList
}
function Get-RAGameNfo {
    # Get-RAGameNfo(game ID number from Get-RAGameList function)
    param (
        [Parameter(Mandatory)][int]$gameID
    )
    $action = 'API_GetGame.php'
    $builder = New-Object System.UriBuilder
    $builder.Scheme = 'https'
    $builder.Host = 'retroachievements.org'
    $builder.Port = 443
    $builder.Path = ('API', "$action" -join '/')
    $builder.Query = ("z=$apiUser", "y=$apiKey", "i=$gameID" -join '&')
    $uri = $builder.ToString()
    $gameNfo = Invoke-RestMethod -Uri $uri
    return $gameNfo
}
function Get-RAGameExt {
    # Get-RAGameExt(game ID number from Get-RAGameList function)
    param (
        [Parameter(Mandatory)][int]$gameID
    )
    $action = 'API_GetGameExtended.php'
    $builder = New-Object System.UriBuilder
    $builder.Scheme = 'https'
    $builder.Host = 'retroachievements.org'
    $builder.Port = 443
    $builder.Path = ('API', "$action" -join '/')
    $builder.Query = ("z=$apiUser", "y=$apiKey", "i=$gameID" -join '&')
    $uri = $builder.ToString()
    $gameExt = Invoke-RestMethod -Uri $uri
    return $gameExt
}
function Get-RAFeed {
    # Get-RAFeed ()
    param (
        [Parameter(Mandatory)][string]$user,
        [int]$count = 0,
        [int]$offset = 0
    )
    $action = 'API_GetFeed.php'
    $builder = New-Object System.UriBuilder
    $builder.Scheme = 'https'
    $builder.Host = 'retroachievements.org'
    $builder.Port = 443
    $builder.Path = ('API', "$action" -join '/')
    $builder.Query = ("z=$apiUser", "y=$apiKey", "u=$user", "c=$count", "o=$offset" -join '&')
    $uri = $builder.ToString()
    $gameFeed = Invoke-RestMethod -Uri $uri
    return $gameFeed
}
function Get-RAUserSummary {
    # Get-RAUserSummary ()
    param (
        [Parameter(Mandatory)][string]$user,
        [int]$numRecentGames = 5
    )
    $action = 'API_GetUserSummary.php'
    $builder = New-Object System.UriBuilder
    $builder.Scheme = 'https'
    $builder.Host = 'retroachievements.org'
    $builder.Port = 443
    $builder.Path = ('API', "$action" -join '/')
    $builder.Query = ("z=$apiUser", "y=$apiKey", "u=$user", "g=$numRecentGames" -join '&')
    $uri = $builder.ToString()
    $userSummary = Invoke-RestMethod -Uri $uri
    return $userSummary
}
function Get-RAUserRankAndScore {
    # RAUserRankAndScore (username)
    param (
        [Parameter(Mandatory)][string]$user
    )
    $action = 'API_GetUserRankAndScore.php'
    $builder = New-Object System.UriBuilder
    $builder.Scheme = 'https'
    $builder.Host = 'retroachievements.org'
    $builder.Port = 443
    $builder.Path = ('API', "$action" -join '/')
    $builder.Query = ("z=$apiUser", "y=$apiKey", "u=$user" -join '&')
    $uri = $builder.ToString()
    $userRankAndScore = Invoke-RestMethod -Uri $uri
    return $userRankAndScore
}
function Get-RAUserProgress {
    # Get-RAUserProgress (username, IDCSV)
    param (
        [Parameter(Mandatory)][string]$user,
        [Parameter(Mandatory)][int]$gameIDCSV
    )
    $action = 'API_GetUserProgress.php'
    $builder = New-Object System.UriBuilder
    $builder.Scheme = 'https'
    $builder.Host = 'retroachievements.org'
    $builder.Port = 443
    $builder.Path = ('API', "$action" -join '/')
    $builder.Query = ("z=$apiUser", "y=$apiKey", "u=$user", "i=$gameIDCSV" -join '&')
    $uri = $builder.ToString()
    $userProgress = Invoke-RestMethod -Uri $uri
    return $userProgress
}
function Get-RARecentGames {
    # Get-RARecentGames ()
    param (
        [Parameter(Mandatory)][string]$user,
        [int]$count = 5,
        [int]$offset = 0
    )
    $action = 'API_GetUserRecentlyPlayedGames.php'
    $builder = New-Object System.UriBuilder
    $builder.Scheme = 'https'
    $builder.Host = 'retroachievements.org'
    $builder.Port = 443
    $builder.Path = ('API', "$action" -join '/')
    $builder.Query = ("z=$apiUser", "y=$apiKey", "u=$user", "g=$count", "o=$offset" -join '&')
    $uri = $builder.ToString()
    $userRecent = Invoke-RestMethod -Uri $uri
    return $userRecent
}
function Get-RAGameUser {
    # Get-RAUserSummary ()
    param (
        [Parameter(Mandatory)][string]$user,
        [Parameter(Mandatory)][int]$gameID
    )
    $action = 'API_GetGameInfoAndUserProgress.php'
    $builder = New-Object System.UriBuilder
    $builder.Scheme = 'https'
    $builder.Host = 'retroachievements.org'
    $builder.Port = 443
    $builder.Path = ('API', "$action" -join '/')
    $builder.Query = ("z=$apiUser", "y=$apiKey", "u=$user", "g=gameID" -join '&')
    $uri = $builder.ToString()
    $userGameUser = Invoke-RestMethod -Uri $uri
    return $userGameUser
}
function Get-RAEarnedOn {
    # Get-RAEarnedOn ('username', 'date' ['2014-01-04'])
    param (
        [Parameter(Mandatory)][string]$user,
        [Parameter(Mandatory)][datetime]$dateInput
    )
    $action = 'API_GetAchievementsEarnedOnDay.php'
    $builder = New-Object System.UriBuilder
    $builder.Scheme = 'https'
    $builder.Host = 'retroachievements.org'
    $builder.Port = 443
    $builder.Path = ('API', "$action" -join '/')
    $builder.Query = ("z=$apiUser", "y=$apiKey", "u=$user", "d=$dateInput" -join '&')
    $uri = $builder.ToString()
    $earnedOn = Invoke-RestMethod -Uri $uri
    return $earnedOn
}
function Get-RAEarnedBetween {
    # Get-RAEarnedBetween ('username', dateFrom ['2013-12-31 20:00:00'], dateTo['2014-01-01 04:00:00'])
    param (
        [Parameter(Mandatory)][string]$user,
        [Parameter(Mandatory)][datetime]$dateFrom,
        [Parameter(Mandatory)][datetime]$dateTo
    )
    $action = 'API_GetAchievementsEarnedBetween.phpp'
    $builder = New-Object System.UriBuilder
    $builder.Scheme = 'https'
    $builder.Host = 'retroachievements.org'
    $builder.Port = 443
    $builder.Path = ('API', "$action" -join '/')
    $builder.Query = ("z=$apiUser", "y=$apiKey", "u=$user", "f=$dateFrom", "t=$dateTo" -join '&')
    $uri = $builder.ToString()
    $earnedBetween = Invoke-RestMethod -Uri $uri
    return $earnedBetween
}
