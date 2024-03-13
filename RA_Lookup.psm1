<#
.SYNOPSIS
Prompts the user to enter their RetroAchievements credentials and saves them in memory.

.DESCRIPTION
This function prompts the user for their RetroAchievements username and API key separately. The credentials are then saved securely in the global scope for the current PowerShell session, allowing other functions in the module to access and use these credentials for authenticated requests to the RetroAchievements API.

.EXAMPLE
Set-RACredentialsInMemory -Verbose
This example demonstrates how to run the function with verbose output, providing detailed messages about the process of storing credentials in memory.

.PARAMETER None
This function does not accept parameters. It directly prompts the user for input.

.INPUTS
None. You cannot pipe input to Set-RACredentialsInMemory.

.OUTPUTS
None. This function does not produce any direct output. However, it stores the credentials in a globally accessible variable for use in the session.

.NOTES
- It's crucial to use this function at the beginning of a session before attempting to interact with RetroAchievements.org API through other functions in the module.
- The function stores the API key as a SecureString to enhance security. However, the username is stored as a plain string since it is considered non-sensitive information.
- Ensure that PowerShell is configured to allow script execution as this function may be part of a script or module requiring execution permissions.

.LINK
https://retroachievements.org/API/

#>
function Set-RACredentialsInMemory {
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

<#
.SYNOPSIS
Clears stored RetroAchievements credentials from memory.

.DESCRIPTION
This function clears any stored RetroAchievements credentials from the current PowerShell session. It sets the credentials stored in the global variable $Global:RACredentials to $null, effectively removing the credentials from memory.

.EXAMPLE
Clear-RACredentialsFromMemory
Executes the function to clear any stored RetroAchievements credentials from memory.

.INPUTS
None. You cannot pipe objects to Clear-RACredentialsFromMemory.

.OUTPUTS
None. This function does not produce any output, but it will write verbose messages indicating the success or failure of clearing the credentials.

.NOTES
- This function is intended to be used as part of a PowerShell module for interacting with the RetroAchievements API. It provides a way to clear credentials from memory for security purposes.
- After clearing credentials using this function, any subsequent API calls requiring authentication will fail until new credentials are set using the Set-RACredentialsInMemory function.
- Use this function with caution to avoid unintentionally removing credentials needed for ongoing operations.

.LINK
https://retroachievements.org/API/

#>
function Clear-RACredentialsFromMemory {
    Write-Verbose "Clearing RetroAchievements credentials from memory..."
    $Global:RACredentials = $null

    # Adding a check to confirm the credentials are cleared
    if ($null -eq $Global:RACredentials) {
        Write-Verbose "RetroAchievements credentials cleared successfully."
    } else {
        Write-Verbose "Failed to clear RetroAchievements credentials from memory."
    }
}

<#
.SYNOPSIS
Retrieves the stored RetroAchievements credentials from memory.

.DESCRIPTION
This function retrieves the username and API key for RetroAchievements stored in memory. The credentials are expected to be stored in a secure manner using the Set-RACredentialsInMemory function. This retrieval is necessary for making authenticated requests to the RetroAchievements API.

.PARAMETER None
This function does not accept any parameters.

.EXAMPLE
$creds = Get-RACredentialsFromMemory
This command retrieves the stored RetroAchievements credentials from memory and stores them in the variable $creds.

.INPUTS
None. You cannot pipe objects to Get-RACredentialsFromMemory.

.OUTPUTS
System.Collections.Hashtable
The function outputs a hashtable containing two keys: UserName and ApiKey, representing the stored username and decrypted API key, respectively.

.NOTES
- Before using Get-RACredentialsFromMemory, ensure that credentials have been stored in the current session using the Set-RACredentialsInMemory function. If credentials are not found, the function will issue a warning.
- The function decrypts the API key securely stored as a SecureString. It is important to handle the returned plaintext API key with care to avoid exposing sensitive information.
- This function is part of a module designed to interact with the RetroAchievements.org API, requiring authentication for most actions.

.LINK
https://retroachievements.org/API/

#>
function Get-RACredentialsFromMemory {
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

<#
.SYNOPSIS
Invokes a specified RetroAchievements.org REST API method.

.DESCRIPTION
The Invoke-RARestMethod function performs a REST API call to the specified RetroAchievements.org API endpoint. It constructs the request URI using the specified action and query parameters, incorporating the user's stored credentials for authentication. This function is designed to facilitate communication with the RetroAchievements API, handling credential insertion and response processing.

.PARAMETER Action
The specific API method to invoke. This string should correspond to the latter part of the URI path that specifies the desired API endpoint (e.g., 'API_GetGameList.php').

.PARAMETER QueryParameters
A hashtable of query parameters to be included in the request. Keys represent parameter names, and values represent parameter values. The function automatically adds authentication parameters based on stored credentials.

.EXAMPLE
Invoke-RARestMethod -Action 'API_GetGameList.php' -QueryParameters @{i=1}
This example invokes an API method to retrieve the game list for the console with ID 1, using the user's stored credentials for authentication.

.EXAMPLE
Invoke-RARestMethod -Action 'API_GetUserSummary.php' -QueryParameters @{u='RetroUser'; c=5; m=5}
This example retrieves a summary for the user 'RetroUser', including data for the last 5 recently played games and the last 5 mastered games.

.INPUTS
None. You cannot pipe objects to Invoke-RARestMethod.

.OUTPUTS
System.Object
Depending on the specific API method invoked, this function returns various types of objects or data structures as provided by the RetroAchievements API.

.NOTES
- Requires the user's RetroAchievements credentials to be previously stored in memory using the Set-RACredentialsInMemory function. If credentials are not found or are invalid, the function will return an error.
- The function handles both successful API calls and various error conditions, including network errors and API-specific errors indicated by the response status code.

.LINK
https://retroachievements.org/API/

#>
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

# <#
# .SYNOPSIS
# Builds a URI for accessing the RetroAchievements API.

# .DESCRIPTION
# The Build-RAUri function constructs a URI based on a specified API action and a hashtable of query parameters. It's designed to simplify the creation of API request URIs for RetroAchievements.org.

# .PARAMETER Action
# The API action to perform. This is a part of the URI path that specifies which API endpoint to access. For example, 'API_GetGameList.php'.

# .PARAMETER QueryParameters
# A hashtable containing the query parameters to be included in the URI. Each key-value pair in the hashtable represents a query parameter name and its value.

# .EXAMPLE
# $uri = Build-RAUri -Action 'API_GetGameList.php' -QueryParameters @{i=1}
# This command builds a URI to fetch the game list for the console with ID 1.

# .EXAMPLE
# $uri = Build-RAUri -Action 'API_GetAchievementInfo.php' -QueryParameters @{i=12345}
# This command builds a URI to fetch information about a specific achievement with ID 12345.

# .INPUTS
# None. You cannot pipe input to Build-RAUri.

# .OUTPUTS
# String
# The function outputs a string that represents the fully constructed URI ready to be used for API requests.

# .NOTES
# This function is a utility designed to support other functions that interact with the RetroAchievements API. It simplifies the process of creating request URIs by automatically formatting action paths and query parameters.

# .LINK
# https://retroachievements.org/API/

# #>
# function Build-RAUri {
#     param (
#         [string]$Action,
#         [hashtable]$QueryParameters
#     )

#     $uri = "https://retroachievements.org/API/$Action"
#     $query = ($QueryParameters.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join '&'
#     if ($query) {
#         $uri += "?$query"
#     }
#     return $uri
# }

####################
## USER FUNCTIONS ##
####################

<#
.SYNOPSIS
Retrieves the profile information for the current user from RetroAchievements.org.

.DESCRIPTION
This function fetches the profile information for the currently authenticated user from the RetroAchievements API. The profile includes data such as the user's ID, username, total points, rank, and more. This operation requires the user's RetroAchievements credentials to be set in the session.

.EXAMPLE
$profileInfo = Get-RAUserProfile
This example fetches the current user's profile information and stores it in the variable $profileInfo.

.EXAMPLE
Get-RAUserProfile | Format-List
This example fetches the current user's profile information and formats the output as a list for readability.

.PARAMETER None
This function does not accept any parameters. It uses the username stored in memory by the Set-RACredentialsInMemory function.

.INPUTS
None. You cannot pipe objects to Get-RAUserProfile.

.OUTPUTS
PSCustomObject
The function outputs a custom PowerShell object representing the user's profile information, including fields returned by the RetroAchievements API.

.NOTES
- Ensure that RetroAchievements credentials are set in the current session using Set-RACredentialsInMemory before attempting to use this function. The function relies on these credentials to authenticate the API request.
- The actual fields and data available in the user's profile may vary depending on the RetroAchievements API's current implementation and the information available for the user.
- This function is designed for ease of use, automatically using the stored credentials for the API request.

.LINK
https://api-docs.retroachievements.org/v1/get-user-profile.html

#>
function Get-RAUserProfile {
    [CmdletBinding()]

    $creds = Get-RACredentialsFromMemory
    if ($null -eq $creds) {
        Write-Error "Credentials not found in memory. Please run Set-RACredentialsInMemory."
        return
    }

    $uri = "https://retroachievements.org/API/API_GetUserProfile.php?z=$($creds.UserName)&y=$($creds.ApiKey)&u=$($creds.UserName)"

    try {
        $response = Invoke-RestMethod -Uri $uri -Method Get
        return $response
    }
    catch {
        Write-Error "Failed to fetch user profile information: $_"
    }
}

<#
.SYNOPSIS
Retrieves the most recent achievements for the currently authenticated RetroAchievements user.

.DESCRIPTION
This function fetches the most recent achievements unlocked by the currently authenticated user on RetroAchievements.org, providing a snapshot of their latest accomplishments across all games.

.EXAMPLE
Get-RARecentUserAchievements

This command retrieves the most recent achievements unlocked by the currently authenticated user.

.NOTES
- Requires that the RetroAchievements credentials, including the username and API key, are already set in the current session using Set-RACredentialsInMemory.
- If credentials are not found, the function will prompt the user to set them using Set-RACredentialsInMemory.
- The function leverages the stored credentials to authenticate the request and fetch data specific to the authenticated user.

.LINK
https://api-docs.retroachievements.org/#api-GetUserRecentAchievements
#>

function Get-RARecentUserAchievements {
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

    # Construct the API request URI using the stored username and API key
    $uri = "https://retroachievements.org/API/API_GetUserRecentAchievements.php?z=$($creds.UserName)&y=$($creds.ApiKey)&u=$($creds.UserName)"

    try {
        # Use Invoke-RestMethod to make the API request and return the response
        $response = Invoke-RestMethod -Uri $uri -Method Get
        return $response
    }
    catch {
        # Handle any errors that may occur during the API call
        Write-Error "Failed to fetch user's recent achievements: $_"
    }
}

<#
.SYNOPSIS
Retrieves a list of achievements earned by the user between two specified dates.

.DESCRIPTION
This function retrieves achievements earned by the currently authenticated user between two specified dates. The dates must be provided in the format 'yyyy-MM-dd'. The function uses the user's credentials stored in memory to authenticate the request.

.PARAMETER dateFrom
The start date in 'yyyy-MM-dd' format from which to begin retrieving achievements.

.PARAMETER dateTo
The end date in 'yyyy-MM-dd' format up to which to retrieve achievements.

.EXAMPLE
Get-RAEarnedBetween -dateFrom '2023-01-01' -dateTo '2023-01-31'
This example retrieves achievements earned by the user between January 1, 2023, and January 31, 2023.

.EXAMPLE
$dateFrom = '2023-02-01'
$dateTo = '2023-02-28'
Get-RAEarnedBetween -dateFrom $dateFrom -dateTo $dateTo
This example demonstrates how to use variables for the date parameters to retrieve achievements earned between February 1, 2023, and February 28, 2023.

.NOTES
Requires that the RetroAchievements credentials are already set in the current session using Set-RACredentialsInMemory. If credentials are not found, the function will prompt the user to enter them. The dates must be provided in the format 'yyyy-MM-dd'.

.LINK
https://api-docs.retroachievements.org/v1/get-achievements-earned-between.html

#>
function Get-RAEarnedBetween {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$dateFrom,

        [Parameter(Mandatory)]
        [string]$dateTo
    )

    # Parse the input dates from string to DateTime objects
    $parsedDateFrom = [datetime]::ParseExact($dateFrom, 'yyyy-MM-dd', $null)
    $parsedDateTo = [datetime]::ParseExact($dateTo, 'yyyy-MM-dd', $null)

    # Convert the DateTime objects to Unix Epoch timestamps
    $epochStart = [datetime]'1970-01-01T00:00:00Z'
    $timestampFrom = [int][double]::Parse(($parsedDateFrom.ToUniversalTime() - $epochStart).TotalSeconds)
    $timestampTo = [int][double]::Parse(($parsedDateTo.ToUniversalTime() - $epochStart).TotalSeconds)

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

    # Construct API request URI with correct endpoint and timestamps
    $uri = "https://retroachievements.org/API/API_GetAchievementsEarnedBetween.php?z=$($creds.UserName)&y=$($creds.ApiKey)&u=$($creds.UserName)&f=$($timestampFrom)&t=$($timestampTo)"

    try {
        # Execute API request and return results
        $response = Invoke-RestMethod -Uri $uri -Method Get
        return $response
    }
    catch {
        Write-Error "An error occurred: $($_.Exception.Message)"
        }
}

#########################################################
# <#
# .SYNOPSIS
# Retrieves achievements earned by a user on a specific date on RetroAchievements.

# .DESCRIPTION
# This function fetches a list of achievements that the specified user earned on the given date on RetroAchievements.org. It will prompt for credentials if they are not already set in the session.

# .PARAMETER user
# The username of the RetroAchievements user whose achievements earned on the specific date are being requested.

# .PARAMETER dateInput
# The date for which to retrieve the achievements earned by the user, in a DateTime format.

# .EXAMPLE
# Get-RAEarnedOn -user 'PlayerName' -dateInput '2023-01-01'

# Retrieves the achievements 'PlayerName' earned on January 1st, 2023.

# .NOTES
# Will prompt for credentials if not found in memory.
# #>
# function Get-RAEarnedOn {
#     [CmdletBinding()]
#     param (
#         [Parameter(Mandatory)]
#         [string]$user,

#         [Parameter(Mandatory)]
#         [datetime]$dateInput
#     )

#     # Check for credentials in memory; if not found, prompt the user to enter them
#     $creds = Get-RACredentialsFromMemory
#     if ($null -eq $creds) {
#         Write-Host "Credentials not found in memory."
#         Set-RACredentialsInMemory
#         $creds = Get-RACredentialsFromMemory
#         if ($null -eq $creds) {
#             Write-Error "Unable to retrieve credentials. Operation cancelled."
#             return
#         }
#     }

#     # Correctly format the date for the API request
#     $formattedDate = $dateInput.ToString('yyyy-MM-dd')

#     $action = 'API_GetAchievementsEarnedOnDay.php'
#     $response = Invoke-RARestMethod -Action $action -QueryParameters @{
#         u = $user
#         d = $formattedDate  # Use the correctly formatted date
#     }

#     return $response
# }

# function Get-RAGameInfoAndUserProgress { # https://api-docs.retroachievements.org/v1/get-game-info-and-user-progress.html}

# function Get-RAUserCompletionProgress { # https://api-docs.retroachievements.org/v1/get-user-completion-progress.html}

# function Get-RAUserCompletionProgress { # https://api-docs.retroachievements.org/v1/get-user-completion-progress.html}

# function Get-RAUserAwards { # https://api-docs.retroachievements.org/v1/get-user-awards.html}

# function Get-RAGetUserClaims { # https://api-docs.retroachievements.org/v1/get-user-claims.html}

# function Get-RAUserGameRankAndScore { # https://api-docs.retroachievements.org/v1/get-user-game-rank-and-score.html}

# function Get-RAGetUserPoints { # https://api-docs.retroachievements.org/v1/get-user-points.html}

# <#
# .SYNOPSIS
# Retrieves the progress of a specified user for a list of games on RetroAchievements.

# .DESCRIPTION
# This function fetches the user's progress for a specified list of games by their IDs on RetroAchievements.org.

# .PARAMETER user
# The username of the RetroAchievements user whose progress is being requested.

# .PARAMETER gameIDCSV
# A comma-separated list of game IDs for which the user's progress is requested.

# .EXAMPLE
# Get-RAUserProgress -user 'PlayerName' -gameIDCSV '1,2,3'

# Retrieves the progress for 'PlayerName' for games with IDs 1, 2, and 3.

# .NOTES
# Requires that credentials are already set in the current session using Set-RACredentialsInMemory.
# #>
# function Get-RAUserProgress {
#     [CmdletBinding()]
#     param (
#         [Parameter(Mandatory)]
#         [string]$user,

#         [Parameter(Mandatory)]
#         [string]$gameIDCSV  # Updated to string to accept a comma-separated list
#     )

#     # Retrieve credentials from memory
#     $creds = Get-RACredentialsFromMemory
#     if ($null -eq $creds) {
#         Write-Error "Credentials not found in memory. Please run Set-RACredentialsInMemory."
#         return
#     }

#     # API action and URI construction
#     $action = 'API_GetUserProgress.php'
#     $response = Invoke-RARestMethod -Action $action -QueryParameters @{
#         u = $user
#         i = $gameIDCSV  # Ensure this is treated as a string representing comma-separated values
#     }

#     return $response
# }

# <#
# .SYNOPSIS
# Retrieves recently played games for a specified RetroAchievements user.

# .DESCRIPTION
# This function fetches a list of recently played games for a user on RetroAchievements.org,
# identified by their username. It prompts for credentials if they are not already set.

# .PARAMETER user
# The username of the RetroAchievements user whose recently played games are being requested.

# .EXAMPLE
# Get-RARecentGames -user 'PlayerName'

# Retrieves the list of recently played games for 'PlayerName'.

# .NOTES
# Will prompt for credentials if not found in memory.
# #>
# function Get-RARecentGames {
#     [CmdletBinding()]
#     param (
#         [Parameter(Mandatory)]
#         [string]$user
#     )

#     # Check for credentials in memory; if not found, prompt the user to enter them
#     $creds = Get-RACredentialsFromMemory
#     if ($null -eq $creds) {
#         Write-Host "Credentials not found in memory."
#         Set-RACredentialsInMemory
#         $creds = Get-RACredentialsFromMemory
#         if ($null -eq $creds) {
#             Write-Error "Unable to retrieve credentials. Operation cancelled."
#             return
#         }
#     }

#     # API action and URI construction
#     $action = 'API_GetUserRecentlyPlayedGames.php'
#     # Assuming $count and $offset should be parameters or predefined values. Adding them as optional parameters for this example
#     $response = Invoke-RARestMethod -Action $action -QueryParameters @{
#         u = $user
#         # Add g and o parameters if they are indeed required and were missing in the original function definition
#     }

#     return $response
# }

# <#
# .SYNOPSIS
# Retrieves a summary of a user's activity and recent games from RetroAchievements.

# .DESCRIPTION
# This function fetches a user's summary including recent game activity on RetroAchievements.org,
# using the user's name and an optional parameter for the number of recent games to retrieve.

# .PARAMETER user
# The username of the RetroAchievements user whose summary is being requested.

# .PARAMETER numRecentGames
# The number of recent games to include in the summary. Default is 5.

# .EXAMPLE
# Get-RAUserSummary -user 'PlayerOne'

# Retrieves the user summary for 'PlayerOne', including the default number of recent games (5).

# .EXAMPLE
# Get-RAUserSummary -user 'PlayerTwo' -numRecentGames 10

# Retrieves the user summary for 'PlayerTwo', including the 10 most recent games.

# .NOTES
# Requires that credentials are already set in the current session using Set-RACredentialsInMemory.
# #>
# function Get-RAUserSummary {
#     [CmdletBinding()]
#     param (
#         [Parameter(Mandatory)]
#         [string]$user,

#         [int]$numRecentGames = 5
#     )

#     # Retrieve credentials from memory
#     $creds = Get-RACredentialsFromMemory
#     if ($null -eq $creds) {
#         Write-Error "Credentials not found in memory. Please run Set-RACredentialsInMemory."
#         return
#     }

#     # API action and URI construction
#     $action = 'API_GetUserSummary.php'
#     $response = Invoke-RARestMethod -Action $action -QueryParameters @{
#         u = $user
#         g = $numRecentGames
#     }

#     return $response
# }
############################################

<#
.SYNOPSIS
Retrieves the list of games a user has completed on RetroAchievements.

.DESCRIPTION
This function fetches a list of games that the specified user has completed 100% of achievements for on RetroAchievements.org. It includes games where the user has unlocked all achievements.

.PARAMETER None
This function does not accept parameters directly. It uses the username and API key stored in memory from the Set-RACredentialsInMemory function.

.EXAMPLE
Get-RACompleted

Retrieves a list of completed games for the currently authenticated user.

.NOTES
- Requires that the RetroAchievements credentials are already set in the current session using Set-RACredentialsInMemory.
- If credentials are not found, the function will prompt the user to enter them.
- The function makes a call to the RetroAchievements API and returns a list of completed games based on the authenticated user's achievements.

.LINK
https://api-docs.retroachievements.org/v1/get-user-completed-games.html
#>
function Get-RACompleted {
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

    # Construct the API request URI using the stored username and API key
    $uri = "https://retroachievements.org/API/API_GetUserCompletedGames.php?z=$($creds.UserName)&y=$($creds.ApiKey)&u=$($creds.UserName)"

    try {
        # Use Invoke-RestMethod to make the API request and return the response
        $response = Invoke-RestMethod -Uri $uri -Method Get
        return $response
    }
    catch {
        # Handle any errors that may occur during the API call
        Write-Error "Failed to fetch user's recent achievements: $_"
    }
}

####################
## GAME FUNCTIONS ##
####################

<#
.SYNOPSIS
Retrieves detailed information about a specific game from RetroAchievements.

.DESCRIPTION
The Get-RAGameNfo function fetches detailed information about a game by its ID from the RetroAchievements API. It requires that the user's RetroAchievements credentials are already stored in memory.

.PARAMETER gameID
The ID of the game for which information is being requested.

.EXAMPLE
$gameInfo = Get-RAGameNfo -gameID 1234
Retrieves information for the game with ID 1234 and stores it in the $gameInfo variable.

.EXAMPLE
Get-RAGameNfo -gameID 5678 | Format-List
Fetches detailed information for the game with ID 5678 and formats the output as a list for easy reading.

.INPUTS
Int32
You can input the game ID as an integer.

.OUTPUTS
PSCustomObject
Outputs a custom object containing the game's detailed information, such as title, console name, number of achievements, and more.

.NOTES
Ensure that you have previously stored your RetroAchievements credentials in memory using the appropriate function before attempting to fetch game information.

#>
function Get-RAGameNfo {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [int]$gameID
    )

    # Retrieve stored credentials from memory
    $creds = Get-RACredentialsFromMemory
    if ($null -eq $creds) {
        Write-Error "Credentials not found. Exiting."
        return
    }

    # Construct the API request URI including credentials and game ID
    $uri = "https://retroachievements.org/API/API_GetGame.php?z=$($creds.UserName)&y=$($creds.ApiKey)&i=$gameID"

    try {
        # Use Invoke-RestMethod to make the request and directly return the response
        $response = Invoke-RestMethod -Uri $uri -Method Get
        return $response
    }
    catch {
        # Handle any errors that occur during the API call
        Write-Error "Failed to fetch game information: $_"
    }
}

<#
.SYNOPSIS
Retrieves extended information for a specified game from RetroAchievements.org.

.DESCRIPTION
This function fetches detailed information about a specified game from the RetroAchievements API, including its achievements, rich presence, leaderboards, and developer credits. The data retrieved provides a comprehensive overview of the game, useful for developers, gamers, and content creators.

.PARAMETER gameID
The unique identifier (ID) for the game whose extended information is being requested. The ID must be a valid game ID present on RetroAchievements.org.

.EXAMPLE
$gameExtInfo = Get-RAGameExt -gameID 12345
Retrieves extended information for the game with ID 12345 and stores it in the variable $gameExtInfo.

.EXAMPLE
Get-RAGameExt -gameID 6789 | Format-List
Retrieves the extended game information for the game with ID 6789 and formats the output as a list for better readability.

.INPUTS
None. You cannot pipe objects to Get-RAGameExt.

.OUTPUTS
System.Management.Automation.PSCustomObject
Outputs a custom object containing detailed information about the specified game. The structure includes achievements, leaderboards, and other metadata associated with the game.

.NOTES
- Requires RetroAchievements credentials to be set in the current session using Set-RACredentialsInMemory. If credentials are not found, it prompts the user to input them.
- This function enhances the interaction with the RetroAchievements.org API by providing in-depth information about a game's components and features.

.LINK
API Documentation: https://api-docs.retroachievements.org/v1/get-game-extended.html

#>
function Get-RAGameExt {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [int]$gameID
    )

    $creds = Get-RACredentialsFromMemory
    if ($null -eq $creds) {
        Write-Error "RetroAchievements credentials not found. Please run Set-RACredentialsInMemory."
        return
    }

    $uri = "https://retroachievements.org/API/API_GetGameExtended.php?z=$($creds.UserName)&y=$($creds.ApiKey)&i=$gameID"

    try {
        $response = Invoke-RestMethod -Uri $uri -Method Get
        return $response
    }
    catch {
        Write-Error "Failed to fetch extended game information: $($_.Exception.Message)"
    }
}

# function Get-RAAchievementCount { # https://api-docs.retroachievements.org/v1/get-achievement-count.html}

# function Get-RAAchievementDistribution { # https://api-docs.retroachievements.org/v1/get-achievement-distribution.html}

# <#
# .SYNOPSIS
# Retrieves the rank and score of a specified RetroAchievements user.

# .DESCRIPTION
# This function fetches the rank and total score for a user on RetroAchievements.org,
# identified by their username.

# .PARAMETER user
# The username of the RetroAchievements user whose rank and score are being requested.

# .EXAMPLE
# Get-RAUserRankAndScore -user 'PlayerName'

# Retrieves the rank and score for 'PlayerName' from RetroAchievements.org.

# .NOTES
# Requires that credentials are already set in the current session using Set-RACredentialsInMemory.
# #>
# function Get-RAUserRankAndScore {
#     [CmdletBinding()]
#     param (
#         [Parameter(Mandatory)]
#         [string]$user
#     )

#     # Retrieve credentials from memory
#     $creds = Get-RACredentialsFromMemory
#     if ($null -eq $creds) {
#         Write-Error "Credentials not found in memory. Please run Set-RACredentialsInMemory."
#         return
#     }

#     # API action and URI construction
#     $action = 'API_GetUserRankAndScore.php'
#     $response = Invoke-RARestMethod -Action $action -QueryParameters @{
#         u = $user
#     }

#     return $response
# }

######################
## SYSTEM FUNCTIONS ##
######################

<#
.SYNOPSIS
Retrieves a list of console IDs and their names from RetroAchievements.org.

.DESCRIPTION
The Get-RAConID function fetches a list of all gaming consoles available on RetroAchievements.org, including their IDs, names, and icon URLs. It uses stored user credentials for authentication against the RetroAchievements API.

.PARAMETER None
This function does not accept any parameters.

.EXAMPLE
$consoles = Get-RAConID
This command retrieves a list of all consoles from RetroAchievements.org and stores the result in the variable $consoles.

.EXAMPLE
Get-RAConID | Where-Object Name -like "*Nintendo*"
This command retrieves the list of all consoles and filters the results to only show consoles with "Nintendo" in their name.

.INPUTS
None. You cannot pipe input to Get-RAConID.

.OUTPUTS
System.Management.Automation.PSCustomObject
The function outputs a collection of objects, each representing a console. These objects include properties such as ID, Name, and IconURL.

.NOTES
- Requires the user's RetroAchievements credentials to be previously stored in memory using the Set-RACredentialsInMemory function. If credentials are not found or are invalid, the function will terminate with an error message.
- The function's success and the accuracy of the returned data are dependent on the availability and response format of the RetroAchievements API.

.LINK
https://api-docs.retroachievements.org/v1/get-console-ids.html

#>
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

<#
.SYNOPSIS
Retrieves a list of games for a specified console from RetroAchievements.org.

.DESCRIPTION
The Get-RAGameList function fetches a list of games available for a specific console from RetroAchievements.org. It requires a valid console ID as input and uses stored credentials to authenticate the API request.

.PARAMETER consoleID
The unique identifier for the console whose games list is being requested. This parameter is mandatory.

.EXAMPLE
$games = Get-RAGameList -consoleID 3
This command retrieves a list of games for the console with ID 3 and stores the result in the variable $games.

.EXAMPLE
Get-RAGameList -consoleID 10 | Select-Object Title, ID
This command retrieves the games list for the console with ID 10 and pipes the results to Select-Object to display only the Title and ID properties of each game.

.INPUTS
None. You cannot pipe objects to Get-RAGameList.

.OUTPUTS
System.Management.Automation.PSCustomObject
The function outputs a collection of objects, each representing a game. These objects include properties such as Title, ID, ConsoleID, ConsoleName, ImageIcon, NumAchievements, NumLeaderboards, Points, DateModified, and ForumTopicID.

.NOTES
Requires the user's RetroAchievements credentials to be stored in memory using the Set-RACredentialsInMemory function. If credentials are not found or are invalid, the function will return an error.

The function directly interacts with the RetroAchievements.org API and is dependent on the availability and response format of their API.

.LINK
https://api-docs.retroachievements.org/v1/get-game-list.html

#>
function Get-RAGameList {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [int]$consoleID
    )

    # Retrieve stored credentials
    $creds = Get-RACredentialsFromMemory
    if ($null -eq $creds) {
        Write-Host "RetroAchievements credentials not found. Please enter your credentials."
        Set-RACredentialsInMemory
        $creds = Get-RACredentialsFromMemory
    }

    # Construct API request URI
    $uri = "https://retroachievements.org/API/API_GetGameList.php?z=$($creds.UserName)&y=$($creds.ApiKey)&i=$consoleID"

    try {
        # Execute API request and return results
        return Invoke-RestMethod -Uri $uri
    }
    catch {
        Write-Error "Failed to fetch game list: $_"
    }
}

###########################
## ACHIEVEMENT FUNCTIONS ##
###########################

# <#
# .SYNOPSIS
# Retrieves achievement unlocks for a specified user and game from RetroAchievements.

# .DESCRIPTION
# This function retrieves achievement unlocks for a specified user and game from the RetroAchievements API.

# .PARAMETER user
# The username of the RetroAchievements user whose achievement unlocks are being requested.

# .PARAMETER gameID
# The ID of the game for which achievement unlocks are requested.

# .EXAMPLE
# Get-RAAchievementUnlocks -user 'PlayerName' -gameID 1234

# Retrieves the achievement unlocks for 'PlayerName' for the game with ID 1234.

# .NOTES
# Will prompt for credentials if not found in memory.
# #>
# function Get-RAAchievementUnlocks {
#     [CmdletBinding()]
#     param (
#         [Parameter(Mandatory)]
#         [string]$user,

#         [Parameter(Mandatory)]
#         [int]$gameID
#     )

#     # Check for credentials in memory; if not found, prompt the user to enter them
#     $creds = Get-RACredentialsFromMemory
#     if ($null -eq $creds) {
#         Write-Host "Credentials not found in memory."
#         Set-RACredentialsInMemory
#         $creds = Get-RACredentialsFromMemory
#         if ($null -eq $creds) {
#             Write-Error "Unable to retrieve credentials. Operation cancelled."
#             return
#         }
#     }

#     # API action and URI construction
#     $action = 'API_GetAchievementUnlocks.php'
#     $response = Invoke-RARestMethod -Action $action -QueryParameters @{
#         u = $user
#         g = $gameID
#     }

#     return $response
# }

###################
## FEED FUNCTIONS##
###################

# function Get-RAActiveClaims { # https://api-docs.retroachievements.org/v1/get-active-claims.html}

# function Get-RAInactiveClaims { # https://api-docs.retroachievements.org/v1/get-claims.html}

# function Get-RATopTenUsers { # https://api-docs.retroachievements.org/v1/get-top-ten-users.html}

#####################
## EVENT FUNCTIONS ##
#####################

# function Get-RAAchievementOfTheWeek { # https://api-docs.retroachievements.org/v1/get-achievement-of-the-week.html}


######################
## TICKET FUNCTIONS ##
######################

# function Get-RATicketData { # https://api-docs.retroachievements.org/v1/get-ticket-data/get-ticket-by-id.html}

# function Get-RAMostTicketedGames { # https://api-docs.retroachievements.org/v1/get-ticket-data/get-most-ticketed-games.html}

# function Get-RAMostRecentTickets { # https://api-docs.retroachievements.org/v1/get-ticket-data/get-most-recent-tickets.html}

# function Get-RAGameTicketStats { # https://api-docs.retroachievements.org/v1/get-ticket-data/get-game-ticket-stats.html}

# function Get-RADeveloperTicketStats { # https://api-docs.retroachievements.org/v1/get-ticket-data/get-developer-ticket-stats.html}

# function Get-RAAchievementTicketStats { # https://api-docs.retroachievements.org/v1/get-ticket-data/get-achievement-ticket-stats.html}
