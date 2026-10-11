Describe 'DupeLocatr' {
BeforeAll {
    $script:AppScript = Join-Path $PSScriptRoot '..\DupeLocatr.ps1'
    . $script:AppScript
}

BeforeEach {
    $script:TestRoot = Join-Path ([System.IO.Path]::GetTempPath()) ([guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $script:TestRoot | Out-Null

    $Script:RootPath = $script:TestRoot
    $Script:LogPath = Join-Path $script:TestRoot 'dupeLocatr_log.txt'
    $Script:ScriptSelf = Join-Path $script:TestRoot 'not-the-app.ps1'
    $Script:ExcludeFolders = @($Script:DupeFolderName, '.git', '.svn', 'node_modules', '$RECYCLE.BIN', 'System Volume Information', '.vs', '.vscode', '__pycache__')
    $Script:MinFileSizeBytes = 1
    $Script:SmallFileLimitBytes = 1MB
    $Script:LargeFileLimitBytes = 500MB
    $Script:SampleBytes = 65536
    $Script:HashAlgo = 'MD5'
    $Script:CategoryFilter = 'All'
    $Script:MaxThreads = 1
}

AfterEach {
    if (Test-Path -LiteralPath $script:TestRoot) {
        Remove-Item -LiteralPath $script:TestRoot -Recurse -Force
    }
}

Describe 'DupeLocatr scanning' {
    It 'finds files recursively and skips excluded folders' {
        $includedDir = Join-Path $script:TestRoot 'photos'
        $excludedDir = Join-Path $script:TestRoot '.git'
        New-Item -ItemType Directory -Path $includedDir | Out-Null
        New-Item -ItemType Directory -Path $excludedDir | Out-Null
        [System.IO.File]::WriteAllText((Join-Path $script:TestRoot 'root.txt'), 'root')
        [System.IO.File]::WriteAllText((Join-Path $includedDir 'photo.txt'), 'photo')
        [System.IO.File]::WriteAllText((Join-Path $excludedDir 'ignored.txt'), 'ignored')

        $files = @(Get-CandidateFiles)

        $files.Count | Should -Be 2
        ($files.FullName -join '|') | Should -Not -Match '\\.git\\'
    }
}

Describe 'DupeLocatr hashing' {
    It 'returns the expected MD5 for a file' {
        $filePath = Join-Path $script:TestRoot 'known.txt'
        [System.IO.File]::WriteAllText($filePath, 'hello')

        Get-FullFileHash -Path $filePath -Algorithm MD5 | Should -Be '5D41402ABC4B2A76B9719D911017C592'
    }
}

Describe 'DupeLocatr report export' {
    BeforeEach {
        $keepPath = Join-Path $script:TestRoot 'keep,copy.txt'
        $duplicatePath = Join-Path $script:TestRoot 'duplicate.txt'
        [System.IO.File]::WriteAllText($keepPath, 'same contents')
        [System.IO.File]::WriteAllText($duplicatePath, 'same contents')
        $script:ExportGroup = [PSCustomObject]@{
            Hash           = 'ABC123'
            SizeEach       = 13
            KeepFile       = Get-Item -LiteralPath $keepPath
            DuplicateFiles = @((Get-Item -LiteralPath $duplicatePath))
        }
    }

    It 'exports the group hash, size, roles, and paths to CSV' {
        Export-DuplicateReport -Results @($script:ExportGroup) -Format CSV
        $reportPath = Get-ChildItem -LiteralPath $script:TestRoot -Filter 'dupeLocatr_report_*.csv' | Select-Object -First 1
        $rows = @(Import-Csv -LiteralPath $reportPath.FullName)

        $rows.Count | Should -Be 2
        $rows[0].Hash | Should -Be 'ABC123'
        [long]$rows[0].SizeBytes | Should -Be 13
        $rows[0].Role | Should -Be 'KEEP'
        $rows[0].Path | Should -Be $script:ExportGroup.KeepFile.FullName
        $rows[1].Role | Should -Be 'DUPLICATE'
        $rows[1].Path | Should -Be $script:ExportGroup.DuplicateFiles[0].FullName
    }

    It 'exports grouped paths with roles to JSON' {
        Export-DuplicateReport -Results @($script:ExportGroup) -Format JSON
        $reportPath = Get-ChildItem -LiteralPath $script:TestRoot -Filter 'dupeLocatr_report_*.json' | Select-Object -First 1
        $groups = @(Get-Content -LiteralPath $reportPath.FullName -Raw | ConvertFrom-Json)

        $groups.Count | Should -Be 1
        $groups[0].Hash | Should -Be 'ABC123'
        [long]$groups[0].SizeBytes | Should -Be 13
        $groups[0].Paths.Count | Should -Be 2
        $groups[0].Paths[0].Role | Should -Be 'KEEP'
        $groups[0].Paths[0].Path | Should -Be $script:ExportGroup.KeepFile.FullName
        $groups[0].Paths[1].Role | Should -Be 'DUPLICATE'
        $groups[0].Paths[1].Path | Should -Be $script:ExportGroup.DuplicateFiles[0].FullName
    }
}

Describe 'DupeLocatr keep strategy' {
    BeforeEach {
        $nestedDir = Join-Path $script:TestRoot 'nested'
        $deepDir = Join-Path $nestedDir 'deep'
        New-Item -ItemType Directory -Path $deepDir | Out-Null

        $script:FirstPath = Join-Path $script:TestRoot 'a.txt'
        $script:OldestPath = Join-Path $nestedDir 'oldest.txt'
        $script:DeepPath = Join-Path $deepDir 'newest.txt'
        foreach ($filePath in @($script:FirstPath, $script:OldestPath, $script:DeepPath)) {
            [System.IO.File]::WriteAllText($filePath, 'same contents')
        }
        (Get-Item -LiteralPath $script:OldestPath).LastWriteTime = [datetime]'2020-01-01'
        (Get-Item -LiteralPath $script:FirstPath).LastWriteTime = [datetime]'2022-01-01'
        (Get-Item -LiteralPath $script:DeepPath).LastWriteTime = [datetime]'2024-01-01'
    }

    It 'keeps the alphabetically first path by default' {
        $Script:KeepStrategy = 'First'

        $results = @(Find-Duplicates)

        $results.Count | Should -Be 1
        $results[0].KeepFile.FullName | Should -Be $script:FirstPath
        $results[0].Hash | Should -Match '^[A-F0-9]{32}$'
        $results[0].SizeEach | Should -Be ([System.IO.File]::ReadAllBytes($script:FirstPath).Length)
    }

    It 'keeps the oldest file when configured' {
        $Script:KeepStrategy = 'Oldest'

        $results = @(Find-Duplicates)

        $results[0].KeepFile.FullName | Should -Be $script:OldestPath
    }

    It 'keeps the newest file when configured' {
        $Script:KeepStrategy = 'Newest'

        $results = @(Find-Duplicates)

        $results[0].KeepFile.FullName | Should -Be $script:DeepPath
    }

    It 'keeps the shortest path when configured' {
        $Script:KeepStrategy = 'ShortestPath'

        $results = @(Find-Duplicates)

        $results[0].KeepFile.FullName | Should -Be $script:FirstPath
    }
}
}
