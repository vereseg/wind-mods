$cursorPosition = 0

$configList = @(
    @{ name = "Old context menu"; command = "Write-Host Test context menu" },
    @{ name = "Start search"; command = "Write-Host Test Start search" }
)

$itemList = foreach ($setting in $configList){
    [PSCustomObject]@{
        name = $setting.Name
        command = $program.command
        selected = $false
    }
}

function ShowMenu{
    Clear-Host
    Write-host "      Config Menu      `n" -ForegroundColor Cyan
    
    for($i = 0; $i -lt $itemList.Count; $i++)
    {
        $prefix = if($itemList[$i].Selected) { "[X]" } else { "[ ]" }

        if($i -eq $cursorPosition)
        {
            Write-Host "> $prefix $($itemList[$i].name)" -ForegroundColor White -BackgroundColor DarkGray
        }
        else
        {
            Write-Host "  $prefix $($itemList[$i].name)"
        }
    }

    Write-Host "`nUse arrow keys to scroll, Space to select, Enter to apply, or ESC to cancel." -ForegroundColor Yellow
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
        $itemList[$cursorPosition].Selected = -not $itemList[$cursorPosition].Selected
    }
    elseif($keyState.Key -eq [ConsoleKey]::Enter)
    {
        break
    }
    elseif($keyState.Key -eq [ConsoleKey]::Escape)
    {
        Write-Host "`nExiting without changes" -ForegroundColor Yellow
        exit
    }
}

$selectedItems = $itemList | Where-Object { $_.Selected }
if($selectedItems.Count -eq 0)
{
    Write-Host "`nExiting without changes" -ForegroundColor Yellow
}

Write-Host "`nApplying selected changes" -ForegroundColor Green
foreach ($itemList in $selectedItems)
{
    $itemList.command
    Write-Host "Applied $($itemList.name)." -ForegroundColor Green
}