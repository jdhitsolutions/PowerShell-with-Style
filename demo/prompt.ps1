
function prompt {

    $location = $executionContext.SessionState.Path.CurrentLocation.path
    #detect .git folder
    if (Test-Path .git) {
        #change the pointer to bright green
        $pointer = "$($PSStyle.Foreground.BrightGreen)$([char]::ConvertFromUtf32(0x25B6))$($PSStyle.Reset)"
    }
    else {
        $pointer = [char]::ConvertFromUtf32(0x25B6)
    }
    #Some code to shorten long paths in the prompt
    #what is the maximum length of the path before you begin truncating?
    [int]$len = $Host.UI.RawUI.MaxWindowSize.width / 3 #33

    if ($location.length -gt $len) {
        $diff = ($location.length - $len)
        #split on the path delimiter which might be different on non-Windows platforms
        $dsc = [system.io.path]::DirectorySeparatorChar
        #escape the separator character to treat it as a literal
        #filter out any blank entries which might happen if the path ends with the delimiter
        $split = $location -split "\$($dsc)" | Where-Object { $_ -match '\S+' }
        #reconstruct a shorted path
        if ($split.count -gt 2) {
            $here = "{0}$dsc{1}...$dsc{2}" -f $split[0], ($split[1][0..$diff] -join ''), $split[-1]
        }
        else {
            #I'm in a long top-level folder name
            $here = "{0}$dsc{1}..." -f $split[0], ($split[1][0..$diff] -join '')
        }
    }
    else {
        #length is ok so use the current location
        $here = $location
    }

    $dt = Get-Date -Format 'dd MMM HH:mm tt'
    Write-Host "[$($PSStyle.Foreground.FromRgb(255,215,0))$($PSStyle.Italic)$dt$($PSStyle.ItalicOff)] " -NoNewline
    #use truncated long path
    Write-Host "$($PSStyle.Bold)PS$($PSVersionTable.PSversion.major).$($PSVersionTable.PSversion.minor)$($PSStyle.BoldOff) $($PSStyle.Background.blue)$here$($PSStyle.Reset)$($pointer * ($nestedPromptLevel + 1))" -NoNewline

    Write-Output ' '
}
