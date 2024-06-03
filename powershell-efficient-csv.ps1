$infilename = Join-Path $PSScriptRoot 'documents.csv'
$outfilename = Join-Path $PSScriptRoot 'VMC_DOCUMENTS.csv'
$bufsize = 1mb
$rowsep = "`r?`n"
$fieldsep = ","

New-Item -Force -Type "file" $outfilename

$readstream = New-Object -TypeName System.IO.StreamReader -ArgumentList $infilename
$writestream = New-Object -TypeName System.IO.StreamWriter -ArgumentList $outfilename

$writestream.WriteLine($readstream.ReadLine())
$partial = ''
$continue = $true
while ($continue) {
    [char[]]$chunk = New-Object char[] $bufsize
    $received = $readstream.Read($chunk, 0, $bufsize)
    $continue = ($received -gt 0)
    if ($continue -eq $false) {
        break
    }
    $chunkstr = $chunk -join ""
    $lines = (($partial, $chunkstr) -join "") -split $rowsep
    $partial = $lines[-1]
    for ($i = 0; $i -lt $lines.Length - 1; $i++) {
        $row = $lines[$i] -split ($fieldsep)
        
        # Process row/fields here:
        $new = ($row[0].ToUpper(), $row[1].ToLower(), $row[2]) -join $fieldsep 

        $writestream.WriteLine($new)
    }
}
$readstream.Close()
$writestream.Close()
