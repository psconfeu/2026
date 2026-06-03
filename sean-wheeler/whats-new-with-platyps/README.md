# What's new with PlatyPS

## Abstract

In this session I will introduce the new version of PlatyPS, the tool Microsoft uses to create help
for PowerShell.

Microsoft.PowerShell.PlatyPS is the new version of PlatyPS. This version is a complete rewrite in C#
leveraging markdig for parsing Markdown. This release includes several improvements:
- Provides a more accurate description of a PowerShell cmdlet and its parameters
- Increased performance - processes 1000s of Markdown files in seconds
- Creates an object model of the help file that you can manipulate in memory
- Provides cmdlets that you can chain together to perform complex operations
- Defines a new Markdown schema that includes all elements needed for Get-Help, plus information
  that was previously unavailable.
- Provide automatic conversion of existing Markdown (using the old schema) to new objects, enabling
  you to export to new Markdown, YAML, or MAML.

## Presentation material

You can find this presentation on my website at:

- [What's new with PlatyPS](https://seanonit.org/docs/platyps/)

Demo scripts and data used in this presentation

- [demo-data.zip](https://github.com/sdwheeler/seanonit/blob/main/content/downloads/platyps/demo-data.zip)
- [demo.ps1](https://github.com/sdwheeler/seanonit/blob/main/content/downloads/platyps/demo.ps1)
- [Test-ParameterInfo.ps1](https://github.com/sdwheeler/seanonit/blob/main/content/downloads/platyps/Test-ParameterInfo.ps1)
