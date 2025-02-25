#2/25/25 - vereseg

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
)

$programs =@(
    [PSCustomObject]@{
        name = "Chrome"
        add = {winget install -e --id Google.Chrome}
        remove = {winget uninstall -e --id Google.Chrome}
        state = "none"
        type = "program"
    }
    [PSCustomObject]@{
        name = "Firefox"
        add = {winget install -e --id Mozilla.Firefox}
        remove = {winget uninstall -e --id Mozilla.Firefox}
        state = "none"
        type = "program"
    }
    [PSCustomObject]@{
        name = "Brave"
        add = {winget install -e --id Brave.Brave}
        remove = {winget uninstall -e --id Brave.Brave}
        state = "none"
        type = "program"
    }
    [PSCustomObject]@{
        name = "VLC Media Player"
        add = {winget install -e --id VideoLAN.VLC}
        remove = {winget uninstall -e --id VideoLAN.VLC}
        state = "none"
        type = "program"
    }
    [PSCustomObject]@{
        name = "PowerToys"
        add = {winget install -e --id Microsoft.PowerToys}
        remove = {winget uninstall -e --id Microsoft.PowerToys}
        state = "none"
        type = "program"
    }
    [PSCustomObject]@{
        name = "OBS Studio"
        add = {winget install -e --id OBSProject.OBSStudio}
        remove = {winget uninstall -e --id OBSProject.OBSStudio}
        state = "none"
        type = "program"
    }
)

$programsDev =@(
    [PSCustomObject]@{
        name = "Git"
        add = {winget install -e --id Git.Git}
        remove = {winget uninstall -e --id Git.Git}
        state = "none"
        type = "program"
    }
    [PSCustomObject]@{
        name = "VSCode"
        add = {winget install -e --id Microsoft.VisualStudioCode}
        remove = {winget uninstall -e --id Microsoft.VisualStudioCode}
        state = "none"
        type = "program"
    }
    [PSCustomObject]@{
        name = "Notepad++"
        add = {winget install -e --id Notepad++.Notepad++}
        remove = {winget uninstall -e --id Notepad++.Notepad++}
        state = "none"
        type = "program"
    }
    [PSCustomObject]@{
        name = "Visual Studio Community"
        add = {winget install -e --id Microsoft.VisualStudio.2022.Community}
        remove = {winget uninstall -e --id Microsoft.VisualStudio.2022.Community}
        state = "none"
        type = "program"
    }
)

$programsSysadmin =@(
    [PSCustomObject]@{
        name = "Process Explorer"
        add = {winget install -e --id Microsoft.Sysinternals.ProcessExplorer}
        remove = {winget uninstall -e --id Microsoft.Sysinternals.ProcessExplorer}
        state = "none"
        type = "program"
    }
)

$sections = @(
    [PSCustomObject]@{
        name = "------------------------------------------------"
        type = "empty"
    }
    [PSCustomObject]@{
        name = "--------------------Settings--------------------"
        type = "empty"
    }
    [PSCustomObject]@{
        name = "----------------------Apps----------------------"
        type = "empty"
    }
    [PSCustomObject]@{
        name = "--------------------DevTools--------------------"
        type = "empty"
    }
    [PSCustomObject]@{
        name = "---------------------System---------------------"
        type = "empty"
    }
)

#add all items to menu for displaying
$menu = @()
$menu += $sections[1]
$menu += $settings
$menu += $sections[2]
$menu += $programs
$menu += $sections[3]
$menu += $programsDev
$menu += $sections[4]
$menu += $programsSysadmin
$menu += $sections[0] #0 is ending section

$cursorPosition = 1

function ShowMenu {
    Clear-Host
    $header = @("`n   ARROWS: move | ENTER: apply | ESC: cancel    ",
    "   SPACE: add | Backspace: remove | 'A': all    ",
    ""
    )
    $footer = @("","       [√]: addition | [X]: removal")

    #find window height and calculate viewable lines
    $windowHeight = [Console]::WindowHeight
    $instructionLines = $header.Count + $footer.Count
    $viewportLimit = $windowHeight - $instructionLines #size of viewport without instructions

    #handle viewport start and end position
    if($viewportLimit -gt 4)
    {
        if($cursorPosition -lt $viewportLimit) {$startIndex = 0}
        else{$startIndex = $cursorPosition - $header.Count}
        $endIndex = [Math]::Min($startIndex + $viewportLimit, $menu.Count)
    }
    else #handle tiny window
    {
        $viewportLimit = 0
        $startIndex = 0
        $endIndex = 0
    }

    #draw header
    for($i = 0; $i -lt $header.Count; $i++)
    {
        Write-Host $header[$i] -ForegroundColor Magenta
    }

    for ($i = $startIndex; $i -lt $endIndex; $i++) {
        $items = $menu[$i]
        if($items.Type -eq "empty")
        {
            #creates section titles
            Write-Host "$($items.name)" -ForegroundColor Cyan
        }
        else
        {
            #active selection indicators
            $prefix = if($items.state -eq "add"){ "[√]|[ ]" }
            elseif($items.state -eq "remove"){ "[ ]|[X]" }
            else{ "[ ]|[ ]" }

            if($i -eq $cursorPosition)
            {
                Write-Host "> $prefix $($menu[$i].name)" -BackgroundColor DarkGray
            }
            else
            {
                Write-Host "  $prefix $($menu[$i].name)"
            }
        }
    }

    #draw footer
    for($i = 0; $i -lt $footer.Count; $i++)
    {
        Write-Host $footer[$i] -ForegroundColor Magenta
    }
}

$inLoop = $true
$widthLast = [Console]::WindowWidth
$heightLast = [Console]::WindowHeight

ShowMenu
while ($inLoop) {
    #failsafe
    if(($menu[$cursorPosition].type -eq "empty") -or ($menu[$cursorPosition].Count -lt 0) -or ($menu[$cursorPosition].Count -gt $menu.Count  -1))
    {
        Write-Host "`nError: invalid position." -ForegroundColor Red
        exit
    }

    if([Console]::KeyAvailable)
    {
        $keyState = [Console]::ReadKey($true)
        switch($keyState.Key){
            'UpArrow'{
                if(($menu[$cursorPosition - 1].type -eq "empty") -and ($cursorPosition - 2 -gt 1)){$cursorPosition -= 2}
                elseif($cursorPosition -gt 1){$cursorPosition--}
                else{}
            }
            'DownArrow'{
                if(($menu[$cursorPosition + 1].type -eq "empty") -and ($cursorPosition + 2 -lt $menu.Count - 1)){$cursorPosition += 2}
                elseif($cursorPosition -lt $menu.Count - 2){$cursorPosition++} #menu minus 2 because of closing section
                else{}
            }
            'A'{
                for($i = 0; $i -lt $menu.Count; $i++)
                {
                    if($menu[$i].type -ne "empty"){
                        $menu[$i].state = "add"
                    }
                }
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
                $inLoop = $false
            }
            'Escape'{
                Write-Host "`nExiting without changes." -ForegroundColor Yellow
                exit
            }
        }
        ShowMenu
    }
    else
    {
        Start-Sleep -Milliseconds 100
        $width = [Console]::WindowWidth
        $height = [Console]::WindowHeight
        if(($width -ne $widthLast) -or ($height -ne $heightLast))
        {
            $widthLast = $width
            $heightLast = $height
            ShowMenu
        }
    }
}

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