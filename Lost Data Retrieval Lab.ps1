# Task 3 — Lost Data Retrieval Lab (SAFE)
# This script:
# 1) Creates sample files on a chosen drive/folder
# 2) Logs hashes BEFORE delete
# 3) Deletes them (simulating accidental deletion)
# 4) Creates a CSV template for recovery results

param(
  [Parameter(Mandatory=$true)]
  [string]$LabRoot,   # Example: "E:\RecoveryLab" (use your USB/test drive)

  [switch]$Permanent  # If set, uses permanent delete (no recycle bin)
)

$ErrorActionPreference = "Stop"
New-Item -ItemType Directory -Force -Path $LabRoot | Out-Null
$SampleDir = Join-Path $LabRoot "sample_files"
$LogDir    = Join-Path $LabRoot "logs"
New-Item -ItemType Directory -Force -Path $SampleDir | Out-Null
New-Item -ItemType Directory -Force -Path $LogDir | Out-Null

# Create sample files
$files = @(
  @{Name="doc1.txt"; SizeKB=32},
  @{Name="doc2.txt"; SizeKB=64},
  @{Name="image1.bin"; SizeKB=128},
  @{Name="report1.bin"; SizeKB=256}
)

"Creating sample files in: $SampleDir"
foreach ($f in $files) {
  $path = Join-Path $SampleDir $f.Name
  # random bytes to simulate data
  $bytes = New-Object byte[] ($f.SizeKB * 1024)
  (New-Object System.Random).NextBytes($bytes)
  [System.IO.File]::WriteAllBytes($path, $bytes)
}

# Log hashes BEFORE deletion (integrity baseline)
$hashLog = Join-Path $LogDir "before_delete_hashes.csv"
"file_name,full_path,sha256" | Out-File -Encoding utf8 $hashLog
Get-ChildItem $SampleDir -File | ForEach-Object {
  $h = (Get-FileHash $_.FullName -Algorithm SHA256).Hash
  "$($_.Name),$($_.FullName),$h" | Out-File -Append -Encoding utf8 $hashLog
}
"Saved hash log: $hashLog"

# Delete files (simulate accidental deletion)
$deleteMethod = if ($Permanent) { "Permanent" } else { "RecycleBin" }
"Deleting files using: $deleteMethod"

if ($Permanent) {
  Get-ChildItem $SampleDir -File | Remove-Item -Force
} else {
  # Recycle Bin delete using Shell.Application (Windows)
  $shell = New-Object -ComObject Shell.Application
  $folder = $shell.Namespace($SampleDir)
  $folder.Items() | ForEach-Object { $_.InvokeVerb("delete") }
}

# Create recovery results CSV template for you to fill after Recuva/TestDisk
$results = Join-Path $LogDir "recovery_results.csv"
@"
file_name,original_path,deleted_method,tool_used,scan_mode,found,restored,integrity_ok,notes
doc1.txt,$SampleDir,$deleteMethod,Recuva/PhotoRec,Quick/Deep,,,, 
doc2.txt,$SampleDir,$deleteMethod,Recuva/PhotoRec,Quick/Deep,,,, 
image1.bin,$SampleDir,$deleteMethod,Recuva/PhotoRec,Quick/Deep,,,, 
report1.bin,$SampleDir,$deleteMethod,Recuva/PhotoRec,Quick/Deep,,,, 
"@ | Out-File -Encoding utf8 $results

"Recovery results template created: $results"
"Next: Run Recuva/TestDisk to recover to a DIFFERENT folder/drive, then fill recovery_results.csv"