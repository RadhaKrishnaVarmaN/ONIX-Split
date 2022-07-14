
$shortnames=$true

$path = Split-Path $script:MyInvocation.MyCommand.Path
#"path: $path"

$files_count = Get-ChildItem -Path $path -Filter *.xml -File | Measure-Object | %{$_.Count}
#"files: $files_count"

if ($files_count -eq 0) {
    Write-Host "No XML file exists" -ForegroundColor Red
    Read-Host "Press Enter to close..."
    Exit
}

Get-ChildItem -Path $path -Filter *xml | ForEach-Object {

    $file = $_.FullName
    $fileName = $_.Name
    $fileNameExt = $_.Extension
    $fileNameWithoutExt = [IO.Path]::GetFileNameWithoutExtension($fileName)
    $fileNameDirectory = [IO.Path]::Combine($path, $fileNameWithoutExt)

    Write-Host ""
    Write-Host (Get-Date).ToString("HH.mm.ss : ") "file: $file"

    if ((Test-Path $fileNameDirectory) -ne 0){
        Write-Host (Get-Date).ToString("HH.mm.ss : ") "Skipped File $fileName as directory will filename already exists ($fileNameWithoutExt)" -ForegroundColor Red
        Write-Host ""
        return
    }

    #Create Sub-Directory
    New-Item -Path $fileNameDirectory -ItemType Directory | Out-Null

    #Read file
    Write-Host (Get-Date).ToString("HH.mm.ss : ") "Read file Started..."
    $xml = New-Object -TypeName XML
    $xml.XmlResolver = $null
    $xml.Load($file)
    Write-Host (Get-Date).ToString("HH.mm.ss : ") "Read file Completed."

    $allproducts = @($xml.SelectNodes("//product"))
    Write-Host (Get-Date).ToString("HH.mm.ss : ") "Products Identified = " $allproducts.Count

    $fileid = 0
    $sep = "_"

    foreach ($p in $allproducts) {
        $fileid++

        $unqId = if ($shortnames) 
                      { ($p.ProductIdentifier | Where-Object {$_.b221 -eq 15} | Select-Object b244).b244 } 
                 else { ($p.ProductIdentifier | Where-Object {$_.ProductIDType -eq 15} | Select-Object IDValue).IDValue }

        if (!$unqId) {
            $unqId = if ($shortnames) { "b005_" + $p.b005 } else { "rref_" + $p.RecordReference }
        } else {
            $unqId = if ($shortnames) { "b224_" + $unqId } else { "pi15_" + $unqId }
        }

        $newfilename = [IO.Path]::Combine($fileNameDirectory, "$unqId$fileNameExt")
        if (Test-Path $newfilename) {
            $newfilename = [IO.Path]::Combine($fileNameDirectory, "$unqId$sep$fileid$fileNameExt")
        }
        #"newFile-$fileid : $newfilename"
        if ($fileid % 1000 -eq 0) {
             Write-Host (Get-Date).ToString("HH.mm.ss : ") "Products completed - $fileid"
        }

        $newFile = [xml]($p.OuterXml)
        $newFile.Save($newfilename)
    }

    $allproducts = $null

}

Read-Host "Press Enter to close..."
