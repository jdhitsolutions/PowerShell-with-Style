#requires -version 7.2

<#
These commands can be used to export FileInfo settings from $PSStyle and
then import them in another session. You might use the import command in
your PowerShell profile script. The export file must be a json file.
#>

Function Export-PSStyleFileInfo {

    [cmdletbinding(SupportsShouldProcess)]
    Param(
        [Parameter(
            Position = 0,
            Mandatory,
            HelpMessage = "Specify the path to a json file."
        )]
        [ValidatePattern("\.json$")]
        [ValidateScript({
            if ( Split-Path $_ | Test-Path) {
                $true
            }
            else {
                Throw "Can't validate part of the specified path: $_"
                $false
            }
        })]
        [string]$FilePath,
        [switch]$NoClobber,
        [switch]$Force
    )
    Begin {
        Write-Verbose "[$((Get-Date).TimeOfDay) BEGIN  ] Starting $($MyInvocation.MyCommand)"
        #initialize a list for extension data
        $ext = [System.Collections.Generic.list[object]]::new()
    } #begin

    Process {
        Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] Exporting PSStyle FileInfo settings to $FilePath "

        $h = @{
            Directory    = $PSStyle.FileInfo.Directory
            SymbolicLInk = $PSStyle.FileInfo.SymbolicLink
            Executable   = $PSStyle.FileInfo.Executable
        }

        Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] Exporting File Extensions"
        foreach ($key in $PSStyle.FileInfo.Extension.keys) {
            Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] --> $key"
            $e = @{Name = $key ; Setting = $PSStyle.FileInfo.Extension[$key] }
            $ext.Add($e)
        }
        #add  the extension list to the hashtable
        $h.Add("Extension", $ext)

        $h | ConvertTo-Json | Out-File @PSBoundParameters

    } #process

    End {
        Write-Verbose "[$((Get-Date).TimeOfDay) END    ] Ending $($MyInvocation.MyCommand)"
    } #end

} #close Export-PSStyleFileInfo


Function Import-PSStyleFileInfo {
    [cmdletbinding(SupportsShouldProcess)]
    Param(
        [Parameter(
            Position = 0,
            Mandatory,
            HelpMessage = "Specify the path to a json file."
        )]
        [ValidatePattern("\.json$")]
        [ValidateScript({
            if ( Split-Path $_ | Test-Path) {
                $true
            }
            else {
                Throw "Can't validate part of the specified path: $_"
                $false
            }
        })]
        [string]$FilePath
    )
    Begin {
        Write-Verbose "[$((Get-Date).TimeOfDay) BEGIN  ] Starting $($MyInvocation.MyCommand)"
    } #begin

    Process {
        Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] Importing settings from $FilePath"
        Try {
            $in = Get-Content -Path $FilePath | ConvertFrom-Json -ErrorAction stop
        }
        Catch {
            Throw $_
        }

        $props = "SymbolicLink", "Executable", "Directory"
        foreach ($prop in $props) {
            if ($in.$prop) {
                if ($PSCmdlet.ShouldProcess($prop)) {
                    $PSStyle.FileInfo.$prop = $in.$prop
                }
            }
        }

        foreach ($item in $in.extension) {
            if ($PSCmdlet.ShouldProcess($item.name)) {
                $PSStyle.FileInfo.Extension[$item.name] = $item.setting
            }
        }

    } #process

    End {
        Write-Verbose "[$((Get-Date).TimeOfDay) END    ] Ending $($MyInvocation.MyCommand)"
    } #end

} #close Import-PSStyleFileInfo
