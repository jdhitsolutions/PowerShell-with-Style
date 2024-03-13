#requires -version 7.4

return "This is a demo script file."

<#
These commands should work in the integreated console in Visual Studio Code,
but you might have the best experience copying and pasting them into a PowerShell 7.4 console.
I recommend using Windows Terminal.
#>

#region ANSI integration

#the host has to support it - No ISE

Get-PSReadLineOption

#building strings
$esc = "$([char]27)"
$Green = "$esc[92m"
$italic = "$esc[3m"
$off  =  "$esc[0m"

$string = "This is a string with $($green)green text$($off) and $($italic)italic text$($off)."
$string

#Install-Module PSScriptTools
Show-ANSISequence
Show-ANSISequence -Foreground -Background

#endregion
#region PSStyle basics

$PSStyle
$PSStyle | Get-Member

#Get-TypeMember is from PSScriptTools
Get-TypeMember system.management.automation.PSStyle

$PSStyle.Foreground
$PSStyle.Background
$PSStyle.Formatting

#I created a custom format file for PSStyle
Update-FormatData .\PSStyle.format.ps1xml
$PSStyle | Format-List -view basic

#endregion
#region Private data and formatting

$host.PrivateData
$PSStyle.Progress
$PSStyle.Formatting

Write-Warning "Danger, Will Robinson!"
#here's how you can combine settings
$PSStyle.Formatting.Warning = $PSStyle.Foreground.Black+$PSStyle.Italic+$PSStyle.Background.BrightMagenta
Write-Warning

#you can also customize the string
$warn = "$($PSStyle.Blink)$($PSStyle.Foreground.Green)Danger$($PSStyle.BlinkOff)$($PSStyle.reset), Will Robinson!"
Write-Warning $warn

cls

$PSStyle.Formatting.Error = $PSStyle.Foreground.BrightGreen
1/0
#put these changes in your PowerShell profile script

Get-Service b*
$PSStyle.Formatting.TableHeader = "`e[1;3;38;5;153m"
Get-Service b*

$PSStyle.Formatting.FormatAccent =$PSStyle.Foreground.Cyan
$PSStyle.Formatting

#endregion
#region Filesystem
cls
$PSStyle.FileInfo

dir

$PSStyle.FileInfo.Directory = $PSStyle.Foreground.BrightBlue+$PSStyle.Italic

#file types stored in a dictionary
$PSStyle.FileInfo.Extension
$PSStyle.FileInfo.Extension[".psm1"].ToString().replace("`e","``e")
$PSStyle.FileInfo.Extension[".psm1"]="`e[38;5;111m"

#add a new file type
$PSStyle.FileInfo.Extension[".png"]="`e[38;5;225m"
dir
#my management functions
psedit .\PSStyleFileInfo.ps1
psedit .\fileinfo.json
. .\PSStyleFileInfo.ps1
Import-PSStyleFileInfo -FilePath .\fileinfo.json

#endregion
#region customizing
cls
Get-TypeMember System.ConsoleColor
"$($PSStyle.Foreground.FromConsoleColor("magenta"))I am the walrus$($PSStyle.reset)"

$PSStyle.Foreground.FromRgb.OverloadDefinitions

#use my module
Import-Module .\DrawingColorTools.psm1
Get-DrawingColor
Get-DrawingColor aliceblue | Select *

Get-DrawingColor | Format-Table

Get-RGB -Name aliceblue

$yg = Get-DrawingColor yellowgreen | Convert-RGBtoAnsi
"I am $($yg)$($PSStyle.Underline)$($PSStyle.Italic)special$($PSStyle.reset) text"

#endregion
#region Scripting

#message strings
#escape sequence codes will be captured in text files
$info = "`nRunning $($PSStyle.Background.Blue)PowerShell$($PSStyle.Reset) $($PSStyle.Foreground.Yellow)v{0}$($PSStyle.Reset) on $($PSStyle.Foreground.BrightCyan){1}$($PSStyle.Reset)." -f $($psversiontable.PSVersion),(get-ciminstance win32_operatingsystem).caption
Write-Host $info

#reset warning
$PSStyle.Formatting.Warning = "`e[38;5;215m"
$msg = "Could not find part of path: {0}{1}{2}{3}" -f $PSStyle.Italic,$PSStyle.Foreground.FromRgb(228,112,214),"c:\work",$PSStyle.Reset
Write-Warning $msg

cls
psedit .\get-ghissuestats.ps1
#this file has been modified from the original gist
psedit .\ghLabelStatus.format.ps1xml

$r = Get-ghIssueLabelCount -Repository jdhitsolutions/psscripttools
$r

$r | Format-Table -view uri

#PSScriptTools includes custom format files
Get-PSScriptTools
Get-PSWho
Get-Service | Format-Table -view Ansi

psedit .\prompt.ps1

. .\prompt.ps1

#endregion
#region disabling
$PSStyle.OutputRendering = "plaintext"
Get-Service bits
dir

$PSStyle.OutputRendering = "ansi"
Get-Service bits
dir
$PSStyle.OutputRendering = "host"

#endregion
