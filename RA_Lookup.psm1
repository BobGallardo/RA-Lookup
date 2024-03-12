# RetroAchievementsAPI.psm1

<#
.SYNOPSIS
Prompts the user to enter their RetroAchievements credentials and saves them in memory.

.DESCRIPTION
This function prompts the user for their RetroAchievements username and API key. 
The credentials are saved in the global scope for the current PowerShell session.

.EXAMPLE
Set-RACredentialsInMemory
#>
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

<#
.SYNOPSIS
Retrieves the stored RetroAchievements credentials from memory.

.DESCRIPTION
This function retrieves the username and API key for RetroAchievements stored in memory.

.EXAMPLE
$creds = Get-RACredentialsFromMemory
#>
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

<#
.SYNOPSIS
Invokes a REST method with RetroAchievements credentials.

.DESCRIPTION
This function merges the stored RetroAchievements credentials with caller's query parameters 
and invokes a REST method to make an API call.

.PARAMETER Action
The API action to perform.

.PARAMETER QueryParameters
A hashtable of query parameters for the request.

.EXAMPLE
$response = Invoke-RARestMethod -Action 'API_Action.php' -QueryParameters @{ param1 = 'value1'; param2 = 'value2' }
#>
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
This function retrieves a list of console IDs from the RetroAchievements API along with their names. Console IDs are useful for identifying consoles in other API calls.

If RetroAchievements credentials are not found in memory, the function prompts the user to enter their credentials using Set-RACredentialsInMemory.

.PARAMETER None
This function does not accept any parameters.

.EXAMPLE
Get-RAConID

Retrieves the list of console IDs and their names.

.NOTES
Requires that the RetroAchievements credentials are already set in the current session using Set-RACredentialsInMemory.
#>
function Get-RAConID {
    [CmdletBinding()]
    param ()

    $creds = Get-RACredentialsFromMemory
    if ($null -eq $creds) {
        Write-Host "RetroAchievements credentials not found. Please enter your credentials."
        Set-RACredentialsInMemory
        $creds = Get-RACredentialsFromMemory
    }

    if ($null -eq $creds) {
        Write-Error "Credentials not found. Exiting."
        return
    }

    $action = 'API_GetConsoleIDs.php'
    $response = Invoke-RARestMethod -Action $action -QueryParameters @{}

    return $response
}

<#
.SYNOPSIS
Retrieves a list of games for a specified console from RetroAchievements.

.DESCRIPTION
This function retrieves a list of games for a specified console from the RetroAchievements API. The console is identified by its console ID.

If RetroAchievements credentials are not found in memory, the function prompts the user to enter their credentials using Set-RACredentialsInMemory.

.PARAMETER consoleID
The ID of the console for which to retrieve the game list.

.EXAMPLE
Get-RAGameList -consoleID 5

Retrieves the list of games for the console with ID 5.

.NOTES
Requires that the RetroAchievements credentials are already set in the current session using Set-RACredentialsInMemory.
#>
function Get-RAGameList {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [int]$consoleID
    )

    $creds = Get-RACredentialsFromMemory
    if ($null -eq $creds) {
        Write-Host "RetroAchievements credentials not found. Please enter your credentials."
        Set-RACredentialsInMemory
        $creds = Get-RACredentialsFromMemory
    }

    if ($null -eq $creds) {
        Write-Error "Credentials not found. Exiting."
        return
    }

    $action = 'API_GetGameList.php'
    $response = Invoke-RARestMethod -Action $action -QueryParameters @{
        i = $consoleID
    }

    return $response
}
    
<#
.SYNOPSIS
Retrieves information for a specified game from RetroAchievements.

.DESCRIPTION
This function retrieves information for a specified game from the RetroAchievements API. The game is identified by its game ID.

If RetroAchievements credentials are not found in memory, the function prompts the user to enter their credentials using Set-RACredentialsInMemory.

.PARAMETER gameID
The ID of the game for which to retrieve information.

.EXAMPLE
Get-RAGameNfo -gameID 12345

Retrieves information for the game with ID 12345.

.NOTES
Requires that the RetroAchievements credentials are already set in the current session using Set-RACredentialsInMemory.
#>
function Get-RAGameNfo {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [int]$gameID
    )

    $creds = Get-RACredentialsFromMemory
    if ($null -eq $creds) {
        Write-Host "RetroAchievements credentials not found. Please enter your credentials."
        Set-RACredentialsInMemory
        $creds = Get-RACredentialsFromMemory
    }

    if ($null -eq $creds) {
        Write-Error "Credentials not found. Exiting."
        return
    }

    $action = 'API_GetGame.php'
    $response = Invoke-RARestMethod -Action $action -QueryParameters @{
        i = $gameID
    }

    return $response
}

<#
.SYNOPSIS
Retrieves extended information for a specified game from RetroAchievements.

.DESCRIPTION
This function retrieves extended information for a specified game from the RetroAchievements API. The game is identified by its game ID.

If RetroAchievements credentials are not found in memory, the function prompts the user to enter their credentials using Set-RACredentialsInMemory.

.PARAMETER gameID
The ID of the game for which to retrieve extended information.

.EXAMPLE
Get-RAGameExt -gameID 12345

Retrieves extended information for the game with ID 12345.

.NOTES
Requires that the RetroAchievements credentials are already set in the current session using Set-RACredentialsInMemory.
#>
function Get-RAGameExt {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [int]$gameID
    )

    $creds = Get-RACredentialsFromMemory
    if ($null -eq $creds) {
        Write-Host "RetroAchievements credentials not found. Please enter your credentials."
        Set-RACredentialsInMemory
        $creds = Get-RACredentialsFromMemory
    }

    if ($null -eq $creds) {
        Write-Error "Credentials not found. Exiting."
        return
    }

    $action = 'API_GetGameExtended.php'
    $response = Invoke-RARestMethod -Action $action -QueryParameters @{
        i = $gameID
    }

    return $response
}
    
<#
.SYNOPSIS
Retrieves the feed for a specified user from RetroAchievements.

.DESCRIPTION
This function retrieves the feed for a specified user from the RetroAchievements API.

If RetroAchievements credentials are not found in memory, the function prompts the user to enter their credentials using Set-RACredentialsInMemory.

.PARAMETER user
The username for which to retrieve the feed.

.PARAMETER count
The number of items to retrieve from the feed. Default is 0, which retrieves all items.

.PARAMETER offset
The offset for paging through the feed. Default is 0.

.EXAMPLE
Get-RAFeed -user "exampleuser" -count 10 -offset 0

Retrieves the feed for the user "exampleuser", retrieving 10 items starting from the first item.

.NOTES
Requires that the RetroAchievements credentials are already set in the current session using Set-RACredentialsInMemory.
#>
function Get-RAFeed {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$user,

        [int]$count = 0,
        [int]$offset = 0
    )

    $creds = Get-RACredentialsFromMemory
    if ($null -eq $creds) {
        Write-Host "RetroAchievements credentials not found. Please enter your credentials."
        Set-RACredentialsInMemory
        $creds = Get-RACredentialsFromMemory
    }

    if ($null -eq $creds) {
        Write-Error "Credentials not found. Exiting."
        return
    }

    $action = 'API_GetFeed.php'
    $response = Invoke-RARestMethod -Action $action -QueryParameters @{
        u = $user
        c = $count
        o = $offset
    }

    return $response
}

<#
.SYNOPSIS
Retrieves completed games for a specified user from RetroAchievements.

.DESCRIPTION
This function retrieves completed games for a specified user from the RetroAchievements API.

If RetroAchievements credentials are not found in memory, the function prompts the user to enter their credentials using Set-RACredentialsInMemory.

.PARAMETER user
The username for which to retrieve completed games.

.EXAMPLE
Get-RACompleted -user "exampleuser"

Retrieves completed games for the user "exampleuser".

.NOTES
Requires that the RetroAchievements credentials are already set in the current session using Set-RACredentialsInMemory.
#>
function Get-RACompleted {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$user
    )

    $creds = Get-RACredentialsFromMemory
    if ($null -eq $creds) {
        Write-Host "RetroAchievements credentials not found. Please enter your credentials."
        Set-RACredentialsInMemory
        $creds = Get-RACredentialsFromMemory
    }

    if ($null -eq $creds) {
        Write-Error "Credentials not found. Exiting."
        return
    }

    $action = 'API_GetUserCompletedGames.php'
    $response = Invoke-RARestMethod -Action $action -QueryParameters @{
        u = $user
    }

    return $response
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
    $response = Invoke-RARestMethod -Action $action -QueryParameters @{
        u = $user
        g = $numRecentGames
    }

    return $response
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
    $response = Invoke-RARestMethod -Action $action -QueryParameters @{
        u = $user
    }

    return $response
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
    $response = Invoke-RARestMethod -Action $action -QueryParameters @{
        u = $user
        i = $gameIDCSV  # Ensure this is treated as a string representing comma-separated values
    }

    return $response
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
    $response = Invoke-RARestMethod -Action $action -QueryParameters @{
        u = $user
        # Add g and o parameters if they are indeed required and were missing in the original function definition
    }

    return $response
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
    $response = Invoke-RARestMethod -Action $action -QueryParameters @{
        u = $user
        g = $gameID  # Corrected to use the variable
    }

    return $response
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
    $response = Invoke-RARestMethod -Action $action -QueryParameters @{
        u = $user
        d = $formattedDate  # Use the correctly formatted date
    }

    return $response
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
    $response = Invoke-RARestMethod -Action $action -QueryParameters @{
        u = $user
        f = $formattedDateFrom
        t = $formattedDateTo
    }

    return $response
}

<#
.SYNOPSIS
Retrieves achievement unlocks for a specified user and game from RetroAchievements.

.DESCRIPTION
This function retrieves achievement unlocks for a specified user and game from the RetroAchievements API.

.PARAMETER user
The username of the RetroAchievements user whose achievement unlocks are being requested.

.PARAMETER gameID
The ID of the game for which achievement unlocks are requested.

.EXAMPLE
Get-RAAchievementUnlocks -user 'PlayerName' -gameID 1234

Retrieves the achievement unlocks for 'PlayerName' for the game with ID 1234.

.NOTES
Will prompt for credentials if not found in memory.
#>
function Get-RAAchievementUnlocks {
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

    # API action and URI construction
    $action = 'API_GetAchievementUnlocks.php'
    $response = Invoke-RARestMethod -Action $action -QueryParameters @{
        u = $user
        g = $gameID
    }

    return $response
}
