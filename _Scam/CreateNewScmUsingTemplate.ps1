#***
#***Automatically create a copy of SCM_TemplateClean with given name***
#***

#It has to be run by powershell in the root location of SCM_TemplateClean
#It assumes there is a template structure named SCM_TemplateClean / eTpc / sTpc

#how to run:
#from twincat editor: right click on the tab above and choose: open containing folder
#in explorer right click this file and run with powershell
#it will ask for new names and then automatically adjust:
#   -file names
#   -create unique ID's'
#   -update state variable declaration + usage in SCM_xxxx

#@success
#import the generated folder with: import existing folder items


Write-Host "Enter new scam name (SCM_ will be added automatically).`nFor example: Infeed"
$NewName = Read-Host

Write-Host "`nEnter new states abbreviation name (to rename types: eTpc and sTpc + usages)`nFor example: Inf"
$NewTpcName = Read-Host

# Huidige scriptlocatie ophalen
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$OldFolderName = "SCM_TemplateClean"
$TemplatePath = Join-Path $ScriptDir $OldFolderName

if (-not (Test-Path $TemplatePath)) {
    Write-Error "Template folder '$TemplatePath' bestaat niet."
    exit 1
}

# Doelmap: gebruikersprofiel (bijv. C:\Users\Gebruiker\SCM_MachinePart123)
$UserHome = [Environment]::GetFolderPath("MyDocuments")
$NewFolderName = $OldFolderName -replace "TemplateClean", $NewName
$NewFolderPath = Join-Path $UserHome -ChildPath (Join-Path $NewFolderName $NewFolderName)

Write-Host "`n`nCopying from: '$OldFolderName' to: '$NewFolderPath'..."

# Stap 1: Kopieer hele directorystructuur
Copy-Item -Path $TemplatePath -Destination $NewFolderPath -Recurse -Force

# Stap 2: Bestanden hernoemen, inhoud vervangen en GUIDs genereren
$Files = Get-ChildItem -Path $NewFolderPath -Recurse -File
foreach ($file in $Files) {
    $oldFullPath = $file.FullName
    $newFullPath = $oldFullPath

    # Bestandsnaam hernoemen
    if ($file.Name -match "TemplateClean") {
        $newNameFile = $file.Name -replace "TemplateClean", $NewName
        $newFullPath = Join-Path $file.DirectoryName $newNameFile
        Rename-Item -Path $file.FullName -NewName $newNameFile
    }

    # Bestandsnaam zonder extensie voor inhoud-vervanging
    $oldBaseName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name) -replace $NewName, "TemplateClean"
    $newBaseName = $oldBaseName -replace "TemplateClean", $NewName

    # Inhoud laden en vervangen
    $content = Get-Content $newFullPath -Raw

    # Vervang bestandsnaam zonder extensie
    $content = $content -replace [regex]::Escape($oldBaseName), $newBaseName

    # Genereer nieuwe GUIDs voor TwinCAT elementen
    $content = [regex]::Replace($content, 'Id="\{[^}]+\}"', { 'Id="' + [guid]::NewGuid().ToString() + '"' })

    # Vervang "Tpc" met opgegeven waarde
    $content = $content -replace '\bTpc\b', $NewTpcName
    $content = $content -replace '\beTpc\b', "e$NewTpcName"
    $content = $content -replace '\bsTpc\b', "s$NewTpcName"

    # Replace HMI_[ERR/xxx]_TemplateClean in files for the new name
    $content = $content -replace '_TemplateClean', "_$NewName"

    # Schrijf terug naar bestand
    Set-Content $newFullPath -Value $content

    # Eventueel ook bestandsnamen hernoemen als ze eTpc of sTpc bevatten
    $newerName = $file.Name
    $newerName = $newerName -replace "eTpc", "e$NewTpcName"
    $newerName = $newerName -replace "sTpc", "s$NewTpcName"
    if ($newerName -ne $file.Name) {
        Rename-Item -Path $newFullPath -NewName $newerName
    }
}

Write-Host "`nDone! Location files: '$NewFolderPath'"
Read-Host "`n`n`nPress any key"
