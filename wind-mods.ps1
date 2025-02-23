#2/23/25 - vereseg

if(!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
{
    Write-Host "Script requires PowerShell to be ran as Admin" -ForegroundColor Red
    exit
}

$cursorPosition = 0

$itemList = @(
    @{ name = "Remove web results from Start Menu"; add = {reg add "HKCU\Software\Policies\Microsoft\Windows\Explorer" /v DisableSearchBoxSuggestions /T REG_DWORD /d 1}; revert = {reg delete "HKCU\Software\Policies\Microsoft\Windows\Explorer" /v DisableSearchBoxSuggestions /f} },
    @{ name = "Use old context menu by default"; add = {reg add "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /f /ve}; revert = {reg delete "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}" /f} },
    @{ name = "Disable Windows error reporting"; add = {Disable-WindowsErrorReporting}; revert = {Enable-WindowsErrorReporting} }
    @{ name = "Uninstall cross device programs"; add = {Get-AppxPackage MicrosoftWindows.CrossDevice | Remove-AppxPackage; Get-AppxPackage Microsoft.YourPhone | Remove-AppxPackage}; revert = {Write-Host unavailable} }
)

#tracks selection state
$itemList = foreach ($setting in $itemList){
    [PSCustomObject]@{
        name = $setting.name
        add = $setting.add
        revert = $setting.revert
        #action states "none", "add", "revert"
        action = "none"
    }
}

function ShowMenu{
    Write-host "      Config Menu      `n" -ForegroundColor Cyan

    for($i = 0; $i -lt $itemList.Count; $i++)
    {
        $prefix = if($itemList[$i].action -eq "add") { "[√]" } elseif($itemList[$i].action -eq "revert") { "[X]" } else { "[ ]" }

        if($i -eq $cursorPosition)
        {
            Write-Host "> $prefix $($itemList[$i].name)" -ForegroundColor White -BackgroundColor DarkGray
        }
        else
        {
            Write-Host "  $prefix $($itemList[$i].name)"
        }
    }

    Write-Host "`nUse arrow keys to scroll, Space to select, Backspace to revert, Enter to apply, or ESC to cancel." -ForegroundColor Yellow
}

while($true)
{
    ShowMenu

    $keyState = [Console]::ReadKey($true)

    if($keyState.Key -eq [ConsoleKey]::UpArrow)
    {
        if($cursorPosition -gt 0) { $cursorPosition-- }
    }
    elseif($keyState.Key -eq [ConsoleKey]::DownArrow) 
    {
        if($cursorPosition -lt $itemList.Count - 1) { $cursorPosition++ }
    }
    elseif($keyState.Key -eq [ConsoleKey]::Spacebar)
    {
        if($itemList[$cursorPosition].action -eq "add") {$itemList[$cursorPosition].action = "none"}
        else{($itemList[$cursorPosition].action = "add")}
    }
    elseif($keyState.Key -eq [ConsoleKey]::Backspace)
    {
        if($itemList[$cursorPosition].action -eq "revert") {$itemList[$cursorPosition].action = "none"}
        else{$itemList[$cursorPosition].action = "revert"}
    }
    elseif($keyState.Key -eq [ConsoleKey]::Enter)
    {
        break
    }
    elseif($keyState.Key -eq [ConsoleKey]::Escape)
    {
        Write-Host "`nExiting without changes." -ForegroundColor Yellow
        exit
    }
}

$configAdd = $itemList | Where-Object { $_.action -eq "add" }
$configRevert = $itemList | Where-Object { $_.action -eq "revert" }

if(($configAdd.Count -eq 0) -and ($configRevert.Count -eq 0))
{
    Write-Host "`nExiting without changes." -ForegroundColor Yellow
    exit
}

#add config
if($configAdd.Count -gt 0)
{
    Write-Host "`nApplying selected changes" -ForegroundColor Yellow
    foreach($itemList in $configAdd)
    {
        & $itemList.add
        Write-Host "`n$($itemList.name) - Applied." -ForegroundColor Green  
    }
}

#revert config
if($configRevert.Count -gt 0)
{
    Write-Host "`nReverting selected changes" -ForegroundColor Yellow
    foreach($itemList in $configRevert)
    {
        & $itemList.revert
        Write-Host "`n$($itemList.name) - Reverted." -ForegroundColor Red  
    }
}