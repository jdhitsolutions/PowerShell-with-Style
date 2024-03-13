#requires -version 7.2

#display system.color in ANSI values

<#
This is a simple PowerShell module with no manifest. The ps1xml files
are assumed to be in the same folder as this module file. Requires
a Windows Platform
#>

Try {
    Add-Type -AssemblyName System.Drawing -ErrorAction Stop
}
Catch {
    Throw 'These functions require the [System.Drawing.Color] .NET Class'
}

Function Convert-RGBToHex {
    [cmdletbinding()]
    [OutputType('string')]
    [alias('crh')]
    Param(
        [Parameter(
            Position = 0,
            Mandatory,
            ValueFromPipelineByPropertyName,
            HelpMessage = 'Enter the RED value'
        )]
        [ValidateNotNullOrEmpty()]
        [ValidateRange(0, 255)]
        [int]$Red,
        [Parameter(
            Position = 1,
            Mandatory,
            ValueFromPipelineByPropertyName,
            HelpMessage = 'Enter the GREEN value'
        )]
        [ValidateNotNullOrEmpty()]
        [ValidateRange(0, 255)]
        [int]$Green,
        [Parameter(
            Position = 2,
            Mandatory,
            ValueFromPipelineByPropertyName,
            HelpMessage = 'Enter the BLUE value'
        )]
        [ValidateNotNullOrEmpty()]
        [ValidateRange(0, 255)]
        [int]$Blue
    )

    Begin {
        Write-Verbose "[$((Get-Date).TimeOfDay) BEGIN  ] Starting $($MyInvocation.MyCommand)"
        Write-Verbose "[$((Get-Date).TimeOfDay) BEGIN  ] Running under PowerShell version $($PSVersionTable.PSVersion)"

    } #begin

    Process {
        Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] Processing $Red,$Green,$Blue "
        $r = [System.Drawing.Color]::FromArgb($Red,$Green,$Blue)
        #strip of the leading FF
        "#$($r.name.Substring(2))".ToUpper()

    } #process

    End {

        Write-Verbose "[$((Get-Date).TimeOfDay) END    ] Ending $($MyInvocation.MyCommand)"
    } #end

} #close Convert-RGBToHex

Function Convert-HTMLtoANSI {
    [cmdletbinding()]
    [OutputType("string")]
    [alias("cha")]
    Param(
        [Parameter(
            Position = 0,
            Mandatory,
            ValueFromPipeline,
            HelpMessage = "Specify an HTML color code like #13A10E"
        )]
        [ValidatePattern('^#[A-Z\d]{6}')]
        [string]$HTMLCode
    )
    Begin {
        Write-Verbose "[$((Get-Date).TimeOfDay) BEGIN  ] Starting $($MyInvocation.MyCommand)"
    } #begin

    Process {
        Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] Converting $HTMLCode"
        $code = [System.Drawing.ColorTranslator]::FromHtml($htmlCode)
        Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] RGB = $($code.r),$($code.g),$($code.b)"
        $ansi = '[38;2;{0};{1};{2}m' -f $code.R,$code.G,$code.B
        $ansi
    } #process
    End {
        Write-Verbose "[$((Get-Date).TimeOfDay) END    ] Ending $($MyInvocation.MyCommand)"
    } #end
} #close Convert-HTMLtoANSI

function Get-RGB {
    [cmdletbinding()]
    [OutputType('RGB')]
    Param(
        [Parameter(Mandatory, HelpMessage = 'Enter the name of a system color like Tomato')]
        [ValidateNotNullOrEmpty()]
        [string]$Name
    )
    Try {
        $Color = [System.Drawing.Color]::FromName($Name)
        [PSCustomObject]@{
            PSTypeName = 'RGB'
            Name       = $Name
            Red        = $color.R
            Green      = $color.G
            Blue       = $color.B
        }
    }
    Catch {
        Throw $_
    }
}
function Convert-RGBtoAnsi {
    #This will write an opening ANSI escape sequence to the pipeline
    [cmdletbinding(DefaultParameterSetName="rgbValues")]
    [OutputType('String')]
    Param(
        [Parameter(ParameterSetName="rgbArray", Mandatory, ValueFromPipelineByPropertyName)]
        [Object]$RGB,
        [parameter(Position = 0, ValueFromPipelineByPropertyName,ParameterSetName="rgbValues")]
        [int]$Red,
        [parameter(Position = 1, ValueFromPipelineByPropertyName,ParameterSetName="rgbValues")]
        [int]$Green,
        [parameter(Position = 2, ValueFromPipelineByPropertyName,ParameterSetName="rgbValues")]
        [int]$Blue
    )
    Process {
        <#
        For legacy powershell session you could create a string like this:
        "$([char]27)[38;2;{0};{1};{2}m" -f $red,$green,$blue
        #>
        if ($PSCmdlet.ParameterSetName -eq 'rgbValues') {
            $PSStyle.Foreground.FromRgb($Red, $Green, $Blue)
        }
        else {
            $PSStyle.Foreground.FromRgb($RGB.red, $RGB.Green, $RGB.Blue)

        }
    }
}

Function Get-DrawingColor {
    [cmdletbinding()]
    [alias('gdc')]
    [OutputType('PSColorSample')]
    Param(
        [Parameter(Position = 0, HelpMessage = 'Specify a color by name. Wildcards are allowed.')]
        [ValidateNotNullOrEmpty()]
        [string[]]$Name
    )

    Write-Verbose "Starting $($MyInvocation.MyCommand)"

    if ($PSBoundParameters.ContainsKey('Name')) {
        if ($Name[0] -match '\*') {
            Write-Verbose "Finding drawing color names that match $name"
            $colors = [system.drawing.color].GetProperties().name | Where-Object { $_ -like $name[0] }
        }
        else {
            $colors = @()
            foreach ($n in $name) {
                if ($n -as [system.drawing.color]) {
                    $colors += $n
                }
                else {
                    Write-Warning "The name $n does not appear to be a valid System.Drawing.Color value. Skipping this name."
                }
                Write-Verbose "Using parameter values: $($colors -join ',')"

            } #foreach name
        } #else
    } #if PSBoundParameters contains Name
    else {
        Write-Verbose 'Getting all drawing color names'
        $colors = [system.drawing.color].GetProperties().name | Where-Object { $_ -NotMatch '^\bIs|Name|[RGBA]\b' }
    }
    Write-Verbose "Processing $($colors.count) colors"
    if ($colors.count -gt 0) {
        foreach ($c in $colors) {
            Write-Verbose "...$c"
            $ansi = Get-RGB $c -OutVariable rgb | Convert-RGBtoAnsi
            #display an ANSI formatted sample string
            $sample = "$ansi$c$($PSStyle.reset)"

            #write a custom object to the pipeline
            [PSCustomObject]@{
                PSTypeName = 'PSColorSample'
                Name       = $c
                RGB        = $rgb
                ANSIString = $ansi.replace("`e", "``e")
                ANSI       = $ansi
                HTML       = Convert-RGBToHex -red $rgb.red -green $rgb.green -blue $rgb.blue
                Sample     = $sample
            }
        }
    } #if colors.count > 0
    else {
        Write-Warning 'No valid colors found.'
    }
    Write-Verbose "Ending $($MyInvocation.MyCommand)"
}

Update-FormatData $PSScriptRoot\pscolorsample.format.ps1xml