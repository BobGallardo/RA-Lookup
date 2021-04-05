## This is a Powershell module with functions to collect data from RetroAchievements.org and to test my PS abilities, or lack there of.
# API details at https://retroachievements.org/APIDemo.php
# Authored by bobbyG

$RAcredsCheck = "$PSScriptRoot\RA_creds.xml"
If (-not(Test-Path -Path $RAcredsCheck -PathType Leaf)) {
    Set-Content -path $PSScriptRoot\RA_Error.txt -Value 'Please run RA_GetCreds.ps1 to import your RetroAchievements API key'
    break
}
else {
    $RAcreds = Import-Clixml $RAcredsCheck
    $apiUser = $RAcreds.UserName
    $apiKey = ConvertFrom-SecureString -AsPlainText $RAcreds.Password
}
function Get-RATop10 {
    param ()
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
    param (
        [Parameter(Mandatory)][string]$user
    )
    $action = 'API_GetFeed.php'
    $builder = New-Object System.UriBuilder
    $builder.Scheme = 'https'
    $builder.Host = 'retroachievements.org'
    $builder.Port = 443
    $builder.Path = ('API', "$action" -join '/')
    $builder.Query = ("z=$apiUser", "y=$apiKey", "u=$user" -join '&')
    $uri = $builder.ToString()
    $gameFeed = Invoke-RestMethod -Uri $uri
    return $gameFeed
}
function Get-RACompleted {
    param (
        [Parameter(Mandatory)][string]$user
    )
    $action = 'API_GetUserCompletedGames.php'
    $builder = New-Object System.UriBuilder
    $builder.Scheme = 'https'
    $builder.Host = 'retroachievements.org'
    $builder.Port = 443
    $builder.Path = ('API', "$action" -join '/')
    $builder.Query = ("z=$apiUser", "y=$apiKey", "u=$user" -join '&')
    $uri = $builder.ToString()
    $gameFeed = Invoke-RestMethod -Uri $uri
    return $gameFeed
}
function Get-RAUserSummary {
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
    param (
        [Parameter(Mandatory)][string]$user
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