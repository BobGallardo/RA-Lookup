function Clear-RACredentialsFromMemory {
    <#
    .SYNOPSIS
    Clears RetroAchievements credentials from memory.

    .DESCRIPTION
    This function clears the stored RetroAchievements credentials from memory.

    .EXAMPLE
    Clear-RACredentialsFromMemory
    #>

    Write-Verbose "Clearing RetroAchievements credentials from memory..."
    $Global:RACredentials = $null

    # Adding a check to confirm the credentials are cleared
    if ($null -eq $Global:RACredentials) {
        Write-Verbose "RetroAchievements credentials cleared successfully."
    } else {
        Write-Verbose "Failed to clear RetroAchievements credentials from memory."
    }
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

    Write-Verbose "Retrieving RetroAchievements credentials from memory..."
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

    $credentials = @{ UserName = $username; ApiKey = $apiKey }
    Write-Verbose "RetroAchievements credentials retrieved from memory: $credentials"
    return $credentials
}

function Set-RACredentialsInMemory {
    <#
    .SYNOPSIS
    Prompts the user to enter their RetroAchievements credentials and saves them in memory.
    
    .DESCRIPTION
    This function prompts the user for their RetroAchievements username and API key separately.
    The credentials are saved securely in the global scope for the current PowerShell session.
    
    .EXAMPLE
    Set-RACredentialsInMemory -Verbose
    #>

    Write-Verbose "Prompting the user to enter RetroAchievements credentials..."

    # Prompt the user for their username
    $username = Read-Host -Prompt "Enter your RetroAchievements username"
    # Prompt the user for their API key, securely
    $apiKey = Read-Host -Prompt "Enter your RetroAchievements API key" -AsSecureString

    # Create a PSCredential object. This is a secure way to store and manage credentials.
    $creds = [PSCredential]::new($username, $apiKey)

    # Store the credentials in the global scope so they can be accessed from anywhere in the session.
    $Global:RACredentials = $creds

    Write-Verbose "Credentials stored in memory."
}

function Invoke-RARestMethod {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$Action,
        [Parameter(Mandatory)]
        [hashtable]$QueryParameters
    )

    Write-Verbose "Invoking RetroAchievements REST method..."
    $creds = Get-RACredentialsFromMemory
    if ($null -eq $creds) {
        Write-Error "Credentials not found in memory. Please run Set-RACredentialsInMemory."
        return
    }

    $queryParameters['z'] = $creds.UserName
    $queryParameters['y'] = $creds.ApiKey

    $uri = Build-RAUri -Action $Action -QueryParameters $queryParameters
    Write-Verbose "URI: $uri"

    try {
        $response = Invoke-RestMethod -Uri $uri -Method Get -ErrorAction Stop
        if ($response) {
            $response.GetType().FullName
            $response | Get-Member -MemberType Properties | ForEach-Object {
                $propName = $_.Name
                $propValue = $response.$propName

                # Convert property value to string, handling complex objects
                $propValueString = if ($propValue -is [System.Collections.IEnumerable] -and -not ($propValue -is [string])) {
                    ($propValue | Out-String).Trim()
                } else {
                    $propValue.ToString()
                }

                # Use concatenation to avoid parser errors in PowerShell 7
                Write-Host ($propName + ": " + $propValueString)
            }
        } else {
            Write-Host "API call successful but the response is empty."
        }
    }
    catch {
        $statusCode = $_.Exception.Response.StatusCode.Value__
        $statusDescription = $_.Exception.Response.StatusDescription
        $errorMessage = $_.Exception.Message
        Write-Error "API call to $Action failed with status code $statusCode ($statusDescription): $errorMessage"
    }
}

function Build-RAUri {
    param (
        [string]$Action,
        [hashtable]$QueryParameters
    )

    $uri = "https://retroachievements.org/API/$Action"
    $query = ($QueryParameters.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join '&'
    if ($query) {
        $uri += "?$query"
    }
    return $uri
}

function Get-RAConID {
    [CmdletBinding()]
    param ()

    # Retrieve stored credentials
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

    # Construct the API request URI
    $uri = "https://retroachievements.org/API/API_GetConsoleIDs.php?z=$($creds.UserName)&y=$($creds.ApiKey)"

    try {
        # Make the API call and return the results
        $consoles = Invoke-RestMethod -Uri $uri -Method Get
        return $consoles
    }
    catch {
        # Handle any errors that occur during the API call
        Write-Error "Failed to fetch consoles: $_"
    }
}

function Get-RAGameList {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [int]$consoleID
    )

    # Assuming this part retrieves credentials correctly
    $creds = Get-RACredentialsFromMemory
    if ($null -eq $creds) {
        Write-Error "Credentials not found. Exiting."
        return
    }

    $uri = "https://retroachievements.org/API/API_GetGameList.php?z=$($creds.UserName)&y=$($creds.ApiKey)&i=$consoleID"

    try {
        # Directly return the parsed JSON objects
        return Invoke-RestMethod -Uri $uri
    }
    catch {
        Write-Error "Failed to fetch game list: $_"
    }
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

<#
.SYNOPSIS
Retrieves the profile information of a user from RetroAchievements.

.DESCRIPTION
This function retrieves the profile information of a user from RetroAchievements API based on the specified user ID. If RetroAchievements credentials are not found in memory, it prompts the user to enter their credentials using Set-RACredentialsInMemory.

.PARAMETER UserId
The ID of the user whose profile information is to be retrieved.

.EXAMPLE
Get-RAUserProfile -UserId '12345'

Retrieves the profile information of the user with the ID '12345' from RetroAchievements.

.NOTES
For more information about the RetroAchievements API, visit: https://api-docs.retroachievements.org/v1/get-user-profile.html
#>
function Get-RAUserProfile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$UserId
    )

    # Check if credentials are present, if not, request them
    $creds = Get-RACredentialsFromMemory
    if ($null -eq $creds) {
        Write-Host "RetroAchievements credentials not found. Please enter your credentials."
        Set-RACredentialsInMemory
        $creds = Get-RACredentialsFromMemory
        if ($null -eq $creds) {
            Write-Error "Unable to retrieve credentials. Operation cancelled."
            return
        }
    }

    $action = 'API_GetUserProfile.php'
    $queryParameters = @{
        'z' = 'UserID'
        'y' = $UserId
    }

    $response = Invoke-RARestMethod -Action $action -QueryParameters $queryParameters

    return $response
}
