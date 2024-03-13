#requires -version 7.4

<#
This function requires the gh.exe command line tool
which you can install with Winget.

You many encounter API rate restrictions under heavy use.
#>

#load the custom formatting file
Update-FormatData $PSScriptRoot\ghLabelStatus.format.ps1xml

Function Get-ghIssueLabelCount {
    [cmdletbinding()]
    [OutputType('ghLabelStatus')]
    [alias('ghlc')]
    Param(
        [Parameter(
            Position = 0,
            Mandatory,
            ValueFromPipeline,
            HelpMessage = 'Specify the Github owner and repo in the format: owner/repo. You might need to match casing with GitHub.'
        )]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern('\w+/\w+$', ErrorMessage = 'Please use the format OWNER/Repository. e.g. jdhitsolutions/psreleasetools')]
        [string]$Repository,

        [Parameter(HelpMessage = 'Specify the first X number of issue labels sorted by count in descending order.')]
        [ValidateScript({ $_ -gt 0 }, ErrorMessage = 'Enter a value greater than 0.')]
        [int]$First = 25,

        [Parameter(HelpMessage = 'Specify the number of issues to analyze')]
        [ValidateScript({ $_ -gt 0 }, ErrorMessage = 'Enter a value greater than 0.')]
        [int]$Limit = 1000
    )

    Begin {
        Write-Verbose "[$((Get-Date).TimeOfDay) BEGIN  ] Starting $($MyInvocation.MyCommand)"
        Write-Verbose "[$((Get-Date).TimeOfDay) BEGIN  ] Running under PowerShell version $($PSVersionTable.PSVersion)"
        Write-Verbose "[$((Get-Date).TimeOfDay) BEGIN  ] Using host: $($Host.Name)"
        $ReportDate = Get-Date
    } #begin

    Process {
        Try {
            $gh = Get-Command -Name gh.exe -ErrorAction Stop
            Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] Using $( gh.exe --version | Select-Object -First 1)"
            Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] Processing $Limit issues from $Repository"

            <#
                gitHub issue Available JSON fields:
                assignees
                author
                body
                closed
                closedAt
                comments
                createdAt
                id
                labels
                milestone
                number
                projectCards
                projectItems
                reactionGroups
                state
                title
                updatedAt
                url
            #>
            $ghData = gh.exe issue list --repo $Repository --limit $Limit --json 'id,title,labels' | ConvertFrom-Json
            Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] Found $($ghData.count) items"
        } #Try
        Catch {
            Write-Warning 'This command requires the gh.exe command-line utility.'
        } #Catch

        If ($ghData.count -gt 0) {
            Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] Getting top $First issue labels"
            $data = $ghData.labels |
            Group-Object -Property Name -NoElement |
            Sort-Object Count, Name -Descending |
            Select-Object -First $First

            foreach ($Item in $data) {
                #create a custom object
                if ($item.Name -match '\s') {
                    $escName = '%22{0}%22' -f ($item.Name -replace '\s', '+')
                    $uri = "https://github.com/$Repository/issues?q=is%3Aissue+is%3Aopen+label%3A$escName"
                }
                else {
                    $uri = "https://github.com/$Repository/issues?q=is%3Aissue+is%3Aopen+label%3A$($Item.Name)"
                }
                [PSCustomObject]@{
                    PStypeName = 'ghLabelStatus'
                    Count      = $Item.Count
                    PctTotal   = ($item.Count / $ghData.Count) * 100
                    Label      = $Item.Name
                    LabelUri   = $uri
                    Repository = $Repository
                    IssueCount = $ghData.Count
                    ReportDate = $ReportDate
                }
            }
        } #if data found
        else {
            Write-Warning "No open issues found in $Repository"
        }
    } #process

    End {
        Write-Verbose "[$((Get-Date).TimeOfDay) END    ] Ending $($MyInvocation.MyCommand)"
    } #end

} #close Get-ghIssueLabelCount

<#

Challenge:

Using whatever tools and techniques you want, write a PowerShell function that
will query the Issues section of a GitHub repository and create output showing
the number of open issues by label and the percentage of all open issues.
Remember that multiple labels may be used with an issue.

For example, if there are 54 open issues and the bug label is used 23 times,
your output would show a count of 23 and a total percentage of 42.59 for the bug
label.

The function should work for any GitHub repository, but test it with the PowerShell
repository. Naturally, the function should follow community accepted best practices,
have parameter validation, and proper error handling.

Bonuses:

Once you have the function, add custom formatting to display the results in a table,
including the repository name or path.

Create an alternative view that will also display the repository and the label URI
that GitHub uses to create a filtered page view.

Finally, create a control script using the function to create a markdown report
for the PowerShell repository showing the top 25 labels. The markdown report should
have clickable links.

#>

#also see ghLabelReport.ps1