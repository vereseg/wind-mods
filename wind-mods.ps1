#2/23/25 - vereseg

if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Script requires PowerShell to be ran as Admin" -ForegroundColor Red
    exit
}

#states "none","add","remove"
#types "empty","setting","program"
$settings =@(
    [PSCustomObject]@{
        name = "Remove web results from Start Menu"
        add = {reg add "HKCU\Software\Policies\Microsoft\Windows\Explorer" /v DisableSearchBoxSuggestions /T REG_DWORD /d 1}
        remove = {reg delete "HKCU\Software\Policies\Microsoft\Windows\Explorer" /v DisableSearchBoxSuggestions /f}
        state = "none"
        type = "setting"
    }
    [PSCustomObject]@{
        name = "Use old context menu by default"
        add = {reg add "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /f /ve}
        remove = {reg delete "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}" /f}
        state = "none"
        type = "setting"
    }
    [PSCustomObject]@{
        name = "Disable Windows error reporting"
        add = {Disable-WindowsErrorReporting}
        remove = {Enable-WindowsErrorReporting}
        state = "none"
        type = "setting"
    }
    [PSCustomObject]@{
        name = "Remove cross device programs (unreversable)"
        add = {Get-AppxPackage MicrosoftWindows.CrossDevice | Remove-AppxPackage; Get-AppxPackage Microsoft.YourPhone | Remove-AppxPackage}
        remove = {Write-Host unavailable -ForegroundColor Red}
        state = "none"
        type = "setting"
    }
)

$programs =@(
    [PSCustomObject]@{
        name = "VLC Media Player"
        add = {winget install -e --id VideoLAN.VLC -i}
        remove = {winget uninstall -e --id VideoLAN.VLC}
        state = "none"
        type = "program"
    }
    [PSCustomObject]@{
        name = "Peazip"
        add = {winget install -e --id Giorgiotani.Peazip -i}
        remove = {winget uninstall -e --id Giorgiotani.Peazip}
        state = "none"
        type = "program"
    }
    [PSCustomObject]@{
        name = "OBS Studio"
        add = {winget install -e --id OBSProject.OBSStudio -i}
        remove = {winget uninstall -e --id OBSProject.OBSStudio}
        state = "none"
        type = "program"
    }
)

$sections = @(
    [PSCustomObject]@{
        name = "--------------------Settings-------------------"
        type = "empty"
    }
    [PSCustomObject]@{
        name = "--------------------Programs--------------------"
        type = "empty"
    }
)

$menu = @()
$menu += $sections[0]
$menu += $settings
$menu += $sections[1]
$menu += $programs

$cursorPosition = 1

function ShowMenu {
    Clear-Host
    Write-Host "  ARROWS: move | ENTER: apply | ESC: cancel" -ForegroundColor Yellow
    Write-Host "      SPACE: add | Backspace: remove" -ForegroundColor Yellow
    Write-Host "       'A': all | 'R': recommended" -ForegroundColor Yellow
    
    for ($i = 0; $i -lt $menu.Count; $i++) {
        $items = $menu[$i]
        if($menu[$i].Type -eq "empty")
        {
            Write-Host "$($items.name)" -ForegroundColor Cyan
        }
        else
        {
            $prefix = if($items.state -eq "add"){ "[√]" }
            elseif($items.state -eq "remove"){ "[X]" }
            else{ "[ ]" }

            if($i -eq $cursorPosition)
            {
                Write-Host "> $prefix $($menu[$i].name)" -ForegroundColor White -BackgroundColor DarkGray
            }
            else
            {
                Write-Host "  $prefix $($menu[$i].name)"
            }

        }
    }

    Write-Host "------------------------------------------------" -ForegroundColor Cyan
    Write-Host "       [√]: addition | [X]: removal" -ForegroundColor Yellow
}

while ($true) {
    ShowMenu

    $keyState = [Console]::ReadKey($true)

    #failsafe
    if(($menu[$cursorPosition].type -eq "empty") -or ($menu[$cursorPosition].Count -lt 0) -or ($menu[$cursorPosition].Count -gt $menu.Count  -1))
    {
        Write-Host "`nError: invalid position." -ForegroundColor Red
        exit
    }

    switch($keyState.Key){
        'UpArrow'{
            if(($menu[$cursorPosition - 1].type -eq "empty") -and ($cursorPosition - 2 -gt 1)){$cursorPosition -= 2}
            elseif($cursorPosition -gt 1){$cursorPosition--}
            else{}
        }
        'DownArrow'{
            if(($menu[$cursorPosition + 1].type -eq "empty") -and ($cursorPosition + 2 -lt $menu.Count - 1)){$cursorPosition += 2}
            elseif($cursorPosition -lt $menu.Count -1){$cursorPosition++}
            else{}
        }
        'Spacebar'{
            if ($menu[$cursorPosition].state -eq "add") { $menu[$cursorPosition].state = "none" }
            else { ($menu[$cursorPosition].state = "add") }
        }
        'Backspace'{
            if ($menu[$cursorPosition].state -eq "remove") { $menu[$cursorPosition].state = "none" }
            else { $menu[$cursorPosition].state = "remove" }
        }
        'Enter'{
            break
        }
        'Escape'{
            Write-Host "`nExiting without changes." -ForegroundColor Yellow
            exit
        }
    }}

$selectedAdd = $menu | Where-Object { $_.state -eq "add" }
$selectedRemove = $menu | Where-Object { $_.state -eq "remove" }

if (($selectedAdd.Count -eq 0) -and ($selectedRemove.Count -eq 0)) {
    Write-Host "`nExiting without changes." -ForegroundColor Yellow
    exit
}

#add
if ($selectedAdd.Count -gt 0) {
    Write-Host "`nApplying selected changes" -ForegroundColor Yellow
    foreach ($items in $selectedAdd) {
        & $items.add
        if($items.type -eq "program"){Write-Host "`n$($items.name) - installed." -ForegroundColor Green}
        else{Write-Host "`n$($items.name) - applied." -ForegroundColor Green}  
    }
}

#remove
if ($selectedRemove.Count -gt 0) {
    Write-Host "`nReverting selected changes" -ForegroundColor Yellow
    foreach ($items in $selectedRemove) {
        & $items.remove
        Write-Host "`n$($items.name) - removed." -ForegroundColor Red  
    }
}