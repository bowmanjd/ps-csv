#!/usr/bin/env pwsh
<#
.SYNOPSIS
Escape unescaped double quotes in non-compliant CSV
.DESCRIPTION
Some systems, such as FoxPro, do not escape double quotes properly in CSV files.
Repair-CSV will find isolated double quotes and escape them as ""
.EXAMPLE
Repair-CSV *.csv
#>
function Repair-CSV
{
  param(
    [Parameter(Mandatory=$false, ValueFromPipeline, ValueFromPipelineByPropertyName)]
    [String[]] $files = @("*.csv"),
    [switch] $inplace = $false
  )
  $tempdir = Join-Path ([System.IO.Path]::GetTempPath()) "Repair-CSV"
  New-Item -Force -ItemType Directory $tempdir | Out-Null

  Get-ChildItem $files | ForEach-Object {
    $bufsize = 1mb
    $rowsep = "`r?`n"
    $fieldsep = ","
    $outfile = Join-Path $tempdir $_.Name

    $readstream = [System.IO.StreamReader] $_.FullName

    if (-not $inplace) {
      New-Item -Force $outfile | Out-Null
    }

    $writestream = [System.IO.StreamWriter] $outfile

    $partial = ''
    $continue = $true
    while ($continue)
    {
      [char[]]$chunk = [char[]]::new($bufsize)
      $received = $readstream.Read($chunk, 0, $bufsize)
      $continue = ($received -gt 0)
      if ($continue -eq $false)
      {
        break
      }
      $chunkstr = $chunk -join ""
      $lines = (($partial, $chunkstr) -join "") -split $rowsep
      $partial = $lines[-1]
      for ($i = 0; $i -lt $lines.Length - 1; $i++)
      {
        $row = $lines[$i] -replace '(?<=[^,"]|,"|^")"(?=[^,"]|",|"$)', '""'
        $writestream.WriteLine($row)
      }
    }
    $readstream.Close()
    $writestream.Close()

    if ($inplace) {
      Move-Item -Force $outfile $_
    } else {
      Get-Content $outfile
    }
  }
}
