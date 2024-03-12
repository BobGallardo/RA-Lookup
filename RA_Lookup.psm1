<#
.SYNOPSIS
This PowerShell module is designed to interact with the RetroAchievements.org API.

.DESCRIPTION
The module includes functions to retrieve various data from RetroAchievements.org, such as top users, game lists, user summaries, and more. It requires an API user name and key, which should be stored securely.

.NOTES
Author: bobbyG
API Details: https://retroachievements.org/APIDemo.php
#>

# RetroAchievementsAPI.psm1

function Set-RACredentialsInMemory {
    <#
    .SYNOPSIS
    Prompts the user to enter their RetroAchievements credentials and saves them in memory.
    
    .DESCRIPTION
    This function prompts the user for their RetroAchievements username and API key. 
    The credentials are saved in the global scope for the current PowerShell session.
    
    .EXAMPLE
    Set-RACredentialsInMemory
    #>

    $Global:RACredentials = Get-Credential -Message "Enter your RetroAchievements username and the API key for the password."
}

function Get-RACredentialsFromMemory {
    <#
    .SYNOPSIS
    Retrieves the stored RetroAchievements credentials from memory.
    
    .DESCRIPTION
    This function retrieves the username and API key for RetroAchievements stored in memory.
    
    .EXAMPLE
    $creds = Get-RACredentialsFromMemory
    #>

    if ($null -eq $Global:RACredentials) {
        Write-Warning "Credentials not found in memory. Please run Set-RACredentialsInMemory."
        return $null
    }

    $username = $Global:RACredentials.UserName
    $apiKeySecureString = $Global:RACredentials.Password
    $apiKeyBSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($apiKeySecureString)
    
    try {
        $apiKey = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($apiKeyBSTR)
    }
    finally {
        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($apiKeyBSTR)
    }

    return @{ UserName = $username; ApiKey = $apiKey }
}

function Invoke-RARestMethod {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$Action,
        [Parameter(Mandatory)]
        [hashtable]$QueryParameters
    )

    $creds = Get-RACredentialsFromMemory
    if ($null -eq $creds) {
        Write-Error "Credentials not found in memory. Please run Set-RACredentialsInMemory."
        return
    }

    # Merge credentials with the caller's query parameters
    $queryParams = @{
        z = $creds['UserName']
        y = $creds['ApiKey']
    } + $QueryParameters

    $uri = Build-RAUri -Action $Action -QueryParameters $queryParams

    try {
        $response = Invoke-RestMethod -Uri $uri -Method Get -ErrorAction Stop
        return $response
    }
    catch {
        Write-Error "API call to $Action failed: $_"
    }
}

    function Build-RAUri {
    <#
    .SYNOPSIS
    Helper function to build API request URIs.
    
    .DESCRIPTION
    This function constructs a URI for API requests based on the specified action and query parameters.
    
    .PARAMETER Action
    The API action to perform.
    
    .PARAMETER QueryParameters
    A hashtable of query parameters for the request.
    
    .EXAMPLE
    $uri = Build-RAUri -Action 'API_GetTopTenUsers.php' -QueryParameters @{ z = 'UserName'; y = 'APIKey' }
    
    #>
        param (
            [string]$Action,
            [hashtable]$QueryParameters
        )
    
        $builder = New-Object System.UriBuilder
        $builder.Scheme = 'https'
        $builder.Host = 'retroachievements.org'
        $builder.Port = 443
        $builder.Path = "API/$Action"
    
        $query = $QueryParameters.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" } -join '&'
        $builder.Query = $query
    
        return $builder.Uri.AbsoluteUri
    }
    
<#
.SYNOPSIS
Retrieves a list of console IDs from RetroAchievements.

.DESCRIPTION
This function makes a call to the RetroAchievements API to fetch a list of all available console IDs along with their names. This is useful for identifying consoles in other API calls.

.EXAMPLE
Get-RAConID

Retrieves the list of console IDs and their names.

.NOTES
Requires that the RetroAchievements credentials are already set in the current session using Set-RACredentialsInMemory.
#>
function Get-RAConID {
    [CmdletBinding()]
    param ()

    $action = 'API_GetConsoleIDs.php'
    $response = Invoke-RARestMethod -Action $action -QueryParameters @{}

    return $response
}

    
    function Get-RAGameList {
        [CmdletBinding()]
        param (
            [Parameter(Mandatory)]
            [int]$consoleID
        )
    
        # Retrieve credentials from memory
        $creds = Get-RACredentialsFromMemory
        if ($null -eq $creds) {
            Write-Error "Credentials not found in memory. Please run Set-RACredentialsInMemory."
            return
        }
    
        # API action and URI construction
        $action = 'API_GetGameList.php'
        $uri = Build-RAUri -Action $action -QueryParameters @{
            z = $creds['UserName']
            y = $creds['ApiKey']
            i = $consoleID
        }
    
        try {
            # Make the API request
            $gameList = Invoke-RestMethod -Uri $uri -Method Get -ErrorAction Stop
            return $gameList
        }
        catch {
            Write-Error "Failed to retrieve game list for console ID $consoleID: $_"
        }
    }
    
    function Get-RAGameNfo {
        [CmdletBinding()]
        param (
            [Parameter(Mandatory)]
            [int]$gameID
        )
    
        # Retrieve credentials from memory
        $creds = Get-RACredentialsFromMemory
        if ($null -eq $creds) {
            Write-Error "Credentials not found in memory. Please run Set-RACredentialsInMemory."
            return
        }
    
        # API action and URI construction
        $action = 'API_GetGame.php'
        $uri = Build-RAUri -Action $action -QueryParameters @{
            z = $creds['UserName']
            y = $creds['ApiKey']
            i = $gameID
        }
    
        try {
            # Make the API request
            $gameNfo = Invoke-RestMethod -Uri $uri -Method Get -ErrorAction Stop
            return $gameNfo
        }
        catch {
            Write-Error "Failed to retrieve game information for Game ID $gameID: $_"
        }
    }
    
    function Get-RAGameExt {
        [CmdletBinding()]
        param (
            [Parameter(Mandatory)]
            [int]$gameID
        )
    
        # Retrieve credentials from memory
        $creds = Get-RACredentialsFromMemory
        if ($null -eq $creds) {
            Write-Error "Credentials not found in memory. Please run Set-RACredentialsInMemory."
            return
        }
    
        # API action and URI construction
        $action = 'API_GetGameExtended.php'
        $uri = Build-RAUri -Action $action -QueryParameters @{
            z = $creds['UserName']
            y = $creds['ApiKey']
            i = $gameID
        }
    
        try {
            # Make the API request
            $gameExt = Invoke-RestMethod -Uri $uri -Method Get -ErrorAction Stop
            return $gameExt
        }
        catch {
            Write-Error "Failed to retrieve extended game information for game ID $gameID: $_"
        }
    }
    
    function Get-RAFeed {
        [CmdletBinding()]
        param (
            [Parameter(Mandatory)]
            [string]$user,
    
            [int]$count = 0,
            [int]$offset = 0
        )
    
        # Retrieve credentials from memory
        $creds = Get-RACredentialsFromMemory
        if ($null -eq $creds) {
            Write-Error "Credentials not found in memory. Please run Set-RACredentialsInMemory."
            return
        }
    
        # Correcting the parameter concatenation in the URI
        $action = 'API_GetFeed.php'
        $uri = Build-RAUri -Action $action -QueryParameters @{
            z = $creds['UserName']
            y = $creds['ApiKey']
            u = $user
            c = $count
            o = $offset
        }
    
        try {
            # Make the API request
            $gameFeed = Invoke-RestMethod -Uri $uri -Method Get -ErrorAction Stop
            return $gameFeed
        }
        catch {
            Write-Error "Failed to retrieve feed for user '$user': $_"
        }
    }
    
    function Get-RACompleted {
        [CmdletBinding()]
        param (
            [Parameter(Mandatory)]
            [string]$user
        )
    
        # Retrieve credentials from memory
        $creds = Get-RACredentialsFromMemory
        if ($null -eq $creds) {
            Write-Error "Credentials not found in memory. Please run Set-RACredentialsInMemory."
            return
        }
    
        # API action and URI construction
        $action = 'API_GetUserCompletedGames.php'
        $uri = Build-RAUri -Action $action -QueryParameters @{
            z = $creds['UserName']
            y = $creds['ApiKey']
            u = $user
        }
    
        try {
            # Make the API request
            $gameFeed = Invoke-RestMethod -Uri $uri -Method Get -ErrorAction Stop
            return $gameFeed
        }
        catch {
            Write-Error "Failed to retrieve completed games for user '$user': $_"
        }
    }
    
<#
.SYNOPSIS
Retrieves a summary of a user's activity and recent games from RetroAchievements.

.DESCRIPTION
This function fetches a user's summary including recent game activity on RetroAchievements.org,
using the user's name and an optional parameter for the number of recent games to retrieve.

.PARAMETER user
The username of the RetroAchievements user whose summary is being requested.

.PARAMETER numRecentGames
The number of recent games to include in the summary. Default is 5.

.EXAMPLE
Get-RAUserSummary -user 'PlayerOne'

Retrieves the user summary for 'PlayerOne', including the default number of recent games (5).

.EXAMPLE
Get-RAUserSummary -user 'PlayerTwo' -numRecentGames 10

Retrieves the user summary for 'PlayerTwo', including the 10 most recent games.

.NOTES
Requires that credentials are already set in the current session using Set-RACredentialsInMemory.
#>
function Get-RAUserSummary {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$user,

        [int]$numRecentGames = 5
    )

    # Retrieve credentials from memory
    $creds = Get-RACredentialsFromMemory
    if ($null -eq $creds) {
        Write-Error "Credentials not found in memory. Please run Set-RACredentialsInMemory."
        return
    }

    # API action and URI construction
    $action = 'API_GetUserSummary.php'
    $uri = Build-RAUri -Action $action -QueryParameters @{
        z = $creds['UserName']
        y = $creds['ApiKey']
        u = $user
        g = $numRecentGames
    }

    try {
        # Make the API request
        $userSummary = Invoke-RestMethod -Uri $uri -Method Get -ErrorAction Stop
        return $userSummary
    }
    catch {
        Write-Error "Failed to retrieve user summary for '$user': $_"
    }
}

<#
.SYNOPSIS
Retrieves the rank and score of a specified RetroAchievements user.

.DESCRIPTION
This function fetches the rank and total score for a user on RetroAchievements.org,
identified by their username.

.PARAMETER user
The username of the RetroAchievements user whose rank and score are being requested.

.EXAMPLE
Get-RAUserRankAndScore -user 'PlayerName'

Retrieves the rank and score for 'PlayerName' from RetroAchievements.org.

.NOTES
Requires that credentials are already set in the current session using Set-RACredentialsInMemory.
#>
function Get-RAUserRankAndScore {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$user
    )

    # Retrieve credentials from memory
    $creds = Get-RACredentialsFromMemory
    if ($null -eq $creds) {
        Write-Error "Credentials not found in memory. Please run Set-RACredentialsInMemory."
        return
    }

    # API action and URI construction
    $action = 'API_GetUserRankAndScore.php'
    $uri = Build-RAUri -Action $action -QueryParameters @{
        z = $creds['UserName']
        y = $creds['ApiKey']
        u = $user
    }

    try {
        # Make the API request
        $userRankAndScore = Invoke-RestMethod -Uri $uri -Method Get -ErrorAction Stop
        return $userRankAndScore
    }
    catch {
        Write-Error "Failed to retrieve rank and score for user '$user': $_"
    }
}

<#
.SYNOPSIS
Retrieves the progress of a specified user for a list of games on RetroAchievements.

.DESCRIPTION
This function fetches the user's progress for a specified list of games by their IDs on RetroAchievements.org.

.PARAMETER user
The username of the RetroAchievements user whose progress is being requested.

.PARAMETER gameIDCSV
A comma-separated list of game IDs for which the user's progress is requested.

.EXAMPLE
Get-RAUserProgress -user 'PlayerName' -gameIDCSV '1,2,3'

Retrieves the progress for 'PlayerName' for games with IDs 1, 2, and 3.

.NOTES
Requires that credentials are already set in the current session using Set-RACredentialsInMemory.
#>
function Get-RAUserProgress {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$user,

        [Parameter(Mandatory)]
        [string]$gameIDCSV  # Updated to string to accept a comma-separated list
    )

    # Retrieve credentials from memory
    $creds = Get-RACredentialsFromMemory
    if ($null -eq $creds) {
        Write-Error "Credentials not found in memory. Please run Set-RACredentialsInMemory."
        return
    }

    # API action and URI construction
    $action = 'API_GetUserProgress.php'
    $uri = Build-RAUri -Action $action -QueryParameters @{
        z = $creds['UserName']
        y = $creds['ApiKey']
        u = $user
        i = $gameIDCSV  # Ensure this is treated as a string representing comma-separated values
    }

    try {
        # Make the API request
        $userProgress = Invoke-RestMethod -Uri $uri -Method Get -ErrorAction Stop
        return $userProgress
    }
    catch {
        Write-Error "Failed to retrieve progress for user '$user' and games '$gameIDCSV': $_"
    }
}

<#
.SYNOPSIS
Retrieves recently played games for a specified RetroAchievements user.

.DESCRIPTION
This function fetches a list of recently played games for a user on RetroAchievements.org,
identified by their username. It prompts for credentials if they are not already set.

.PARAMETER user
The username of the RetroAchievements user whose recently played games are being requested.

.EXAMPLE
Get-RARecentGames -user 'PlayerName'

Retrieves the list of recently played games for 'PlayerName'.

.NOTES
Will prompt for credentials if not found in memory.
#>
function Get-RARecentGames {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$user
    )

    # Check for credentials in memory; if not found, prompt the user to enter them
    $creds = Get-RACredentialsFromMemory
    if ($null -eq $creds) {
        Write-Host "Credentials not found in memory."
        Set-RACredentialsInMemory
        $creds = Get-RACredentialsFromMemory
        if ($null -eq $creds) {
            Write-Error "Unable to retrieve credentials. Operation cancelled."
            return
        }
    }

    # API action and URI construction
    $action = 'API_GetUserRecentlyPlayedGames.php'
    # Assuming $count and $offset should be parameters or predefined values. Adding them as optional parameters for this example
    $uri = Build-RAUri -Action $action -QueryParameters @{
        z = $creds['UserName']
        y = $creds['ApiKey']
        u = $user
        # Add g and o parameters if they are indeed required and were missing in the original function definition
    }

    try {
        # Make the API request
        $userRecent = Invoke-RestMethod -Uri $uri -Method Get -ErrorAction Stop
        return $userRecent
    }
    catch {
        Write-Error "Failed to retrieve recently played games for user '$user': $_"
    }
}

<#
.SYNOPSIS
Retrieves game information and user progress for a specified game and RetroAchievements user.

.DESCRIPTION
This function fetches detailed information and the user's progress for a specific game by its ID on RetroAchievements.org,
identified by the username and game ID. It prompts for credentials if they are not already set.

.PARAMETER user
The username of the RetroAchievements user whose game information and progress are being requested.

.PARAMETER gameID
The ID of the game for which information and user progress are requested.

.EXAMPLE
Get-RAGameUser -user 'PlayerName' -gameID 1234

Retrieves game information and 'PlayerName's progress for the game with ID 1234.

.NOTES
Will prompt for credentials if not found in memory.
#>
function Get-RAGameUser {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$user,

        [Parameter(Mandatory)]
        [int]$gameID
    )

    # Check for credentials in memory; if not found, prompt the user to enter them
    $creds = Get-RACredentialsFromMemory
    if ($null -eq $creds) {
        Write-Host "Credentials not found in memory."
        Set-RACredentialsInMemory
        $creds = Get-RACredentialsFromMemory
        if ($null -eq $creds) {
            Write-Error "Unable to retrieve credentials. Operation cancelled."
            return
        }
    }

    # Correctly use the gameID in the query
    $action = 'API_GetGameInfoAndUserProgress.php'
    $uri = Build-RAUri -Action $action -QueryParameters @{
        z = $creds['UserName']
        y = $creds['ApiKey']
        u = $user
        g = $gameID  # Corrected to use the variable
    }

    try {
        # Make the API request
        $userGameUser = Invoke-RestMethod -Uri $uri -Method Get -ErrorAction Stop
        return $userGameUser
    }
    catch {
        Write-Error "Failed to retrieve game information and user progress for user '$user' and game ID '$gameID': $_"
    }
}

<#
.SYNOPSIS
Retrieves achievements earned by a user on a specific date on RetroAchievements.

.DESCRIPTION
This function fetches a list of achievements that the specified user earned on the given date on RetroAchievements.org. It will prompt for credentials if they are not already set in the session.

.PARAMETER user
The username of the RetroAchievements user whose achievements earned on the specific date are being requested.

.PARAMETER dateInput
The date for which to retrieve the achievements earned by the user, in a DateTime format.

.EXAMPLE
Get-RAEarnedOn -user 'PlayerName' -dateInput '2023-01-01'

Retrieves the achievements 'PlayerName' earned on January 1st, 2023.

.NOTES
Will prompt for credentials if not found in memory.
#>
function Get-RAEarnedOn {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$user,

        [Parameter(Mandatory)]
        [datetime]$dateInput
    )

    # Check for credentials in memory; if not found, prompt the user to enter them
    $creds = Get-RACredentialsFromMemory
    if ($null -eq $creds) {
        Write-Host "Credentials not found in memory."
        Set-RACredentialsInMemory
        $creds = Get-RACredentialsFromMemory
        if ($null -eq $creds) {
            Write-Error "Unable to retrieve credentials. Operation cancelled."
            return
        }
    }

    # Correctly format the date for the API request
    $formattedDate = $dateInput.ToString('yyyy-MM-dd')

    $action = 'API_GetAchievementsEarnedOnDay.php'
    $uri = Build-RAUri -Action $action -QueryParameters @{
        z = $creds['UserName']
        y = $creds['ApiKey']
        u = $user
        d = $formattedDate  # Use the correctly formatted date
    }

    try {
        # Make the API request
        $earnedOn = Invoke-RestMethod -Uri $uri -Method Get -ErrorAction Stop
        return $earnedOn
    }
    catch {
        Write-Error "Failed to retrieve achievements earned on $formattedDate for user '$user': $_"
    }
}

<#
.SYNOPSIS
Retrieves achievements earned by a user between two specific dates on RetroAchievements.

.DESCRIPTION
This function fetches a list of achievements that the specified user earned between the given start and end dates on RetroAchievements.org. It will prompt for credentials if they are not already set in the session.

.PARAMETER user
The username of the RetroAchievements user whose achievements earned between the specific dates are being requested.

.PARAMETER dateFrom
The start date of the period for which to retrieve the achievements earned by the user, in a DateTime format.

.PARAMETER dateTo
The end date of the period for which to retrieve the achievements earned by the user, in a DateTime format.

.EXAMPLE
Get-RAEarnedBetween -user 'PlayerName' -dateFrom '2023-01-01' -dateTo '2023-01-31'

Retrieves the achievements 'PlayerName' earned between January 1st, 2023, and January 31st, 2023.

.NOTES
Will prompt for credentials if not found in memory. This function might return a 404 Not Found error if the API endpoint or the parameters are incorrect.
#>
function Get-RAEarnedBetween {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$user,

        [Parameter(Mandatory)]
        [datetime]$dateFrom,

        [Parameter(Mandatory)]
        [datetime]$dateTo
    )

    # Check for credentials in memory; if not found, prompt the user to enter them
    $creds = Get-RACredentialsFromMemory
    if ($null -eq $creds) {
        Write-Host "Credentials not found in memory."
        Set-RACredentialsInMemory
        $creds = Get-RACredentialsFromMemory
        if ($null -eq $creds) {
            Write-Error "Unable to retrieve credentials. Operation cancelled."
            return
        }
    }

    # Correctly format the dates for the API request
    $formattedDateFrom = $dateFrom.ToString('yyyy-MM-dd')
    $formattedDateTo = $dateTo.ToString('yyyy-MM-dd')

    $action = 'API_GetAchievementsEarnedBetween.php'
    $uri = Build-RAUri -Action $action -QueryParameters @{
        z = $creds['UserName']
        y = $creds['ApiKey']
        u = $user
        f = $formattedDateFrom
        t = $formattedDateTo
    }

    try {
        # Make the API request
        $earnedBetween = Invoke-RestMethod -Uri $uri -Method Get -ErrorAction Stop
        return $earnedBetween
    }
    catch {
        Write-Error "Failed to retrieve achievements earned between $formattedDateFrom and $formattedDateTo for user '$user': $_"
    }
}

