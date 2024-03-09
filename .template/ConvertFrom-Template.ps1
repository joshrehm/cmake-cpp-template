<#
    .SYNOPSIS
    Generate a project from an existing template

    .DESCRIPTION
    Creates a new project directory based on a template. Template files are copied
    to the target location.
    
    Variables in the path name will be expanded.

    Variables in content will be expanded if the path to the file matches a glob
    pattern in the .template\templates files.
    
    Available variables are:
      - PROJECT_NAME            As-Typed
      - PROJECT_NAME_PASCAL     AsTyped
      - PROJECT_NAME_CAMEL      asTyped
      - PROJECT_NAME_SNAKE      as_typed
      - PROJECT_NAME_DEFINE     AS_TYPED
    
    .PARAMETER Path
    The target location to which the project should be created

    .PARAMETER Project
    The name of the project. This name will be used for variable expansion in
    the project.

    .PARAMETER Force
    Force project creation even if the target Path is not empty
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$Project,

    [Parameter(Mandatory=$true)]
    [string]$Path,

    [switch]$Force
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'
 
# Convert some_words or some-words SomeWords
function ConvertTo-PascalCase($value) {
    $result = ''
    $value = $value.Trim();

    $upper = $false
    $upperrun = $false
    $hyphen = $false

    for($a = 0; $a -lt $value.Length; ++$a) {
        $c = $value[$a]

        if ($a -eq 0 -or $hyphen) {
            $upper = $true
            $upperrun = $false
            $hyphen = $false
        }
        elseif ($c -eq '_' -or $c -eq '-' -or $c -eq ' ') {
            $hyphen = $true
        }
        elseif ($upperrun) {
            if ($a + 1 -lt $value.Length -and [char]::IsLower($value[$a + 1])) {
                $upper = $true
                $upperrun = $false
            }
            elseif (![char]::IsUpper($c)) {
                $upperrun = $false
            }
        }
        elseif ([char]::IsUpper($c)) {
            if ($upper -eq $true) {
                $upperrun = $true
                $upper = $false
            }
            else {
                $upper = $true
            }
        }
        else {
            $upperrun = $false
            $upper = $false
        }

        if ($c -ne '_' -and $c -ne '-' -and $c -ne ' ') {
            if ($upper) { $result += [char]::ToUpper($c); }
            else        { $result += [char]::ToLower($c); }
        }
    }
    $result
}

# Convert some_words or some-words to someWords
function ConvertTo-CamelCase($value) {
    $result = ConvertTo-PascalCase $value
    if ($result.Length -gt 0) {
        $result = [char]::ToLower($result[0]) + $result.Substring(1);
    }
    $result
}

# Convert SomeWords to some_words
function ConvertTo-SnakeCase($value) {
    $result = '';
    $incap = $false
    $value = $value.Trim();

    for($a = 0; $a -lt $value.Length; ++$a) {
        $c = $value[$a];
        if ($c -eq '-' -or $c -eq ' ') {
            $c = '_'
        }
        elseif ([char]::IsUpper($c) -and !$incap) {
            $incap = $true
            if ($a -gt 0 -and $result[$result.Length - 1] -ne '_') {
                $result += '_';
            }
        }
        elseif([char]::IsLower($c)) {
            $incap = $false
        }
        elseif ($incap -and ($a + 1) -lt $value.Length -and [char]::IsLower($value[$a + 1])) {
            if ($result[$result.Length - 1] -ne '_') {
                $result += '_';
            }
            $incap = $false
        }
        $result += [char]::ToLower($c);
    }

    $result
}


# Creates a regular expression from glob syntax
function ConvertFrom-GlobSyntax($Glob) {
    $Glob = $Glob.TrimEnd()
 
    $regex = ''
    for($i = 0; $i -lt $Glob.Length; ) {
        $c = $Glob[$i]
        if ($i + 1 -lt $Glob.length) {
            $n = $Glob[$i + 1]
        }
        else {
            $n = $null
        }
 
        switch($c) {
            # Escape Sequence
            '\' {
                if ($n -eq $null) {
                    throw 'Invalid Glob Syntax';
                }
                $regex += [regex]::Escape($n)
                ++$i
            }
            # Comment
            '#' {
                break
            }
            # * or **
            '*' {
                if ($n -eq '*') {    # ** means match everything
                    $regex += '.*';
                    ++$i
                }
                else {               # * means match this directory (match until the next /)
                    $regex += '[^/]*'
                }
            }
            # Match any single character that isn't a /
            '?' {
                $regex += '[^/]'
            }
            # Match a character sequence. The documentation is a little ambiguous here as to whether or not [ABCD]
            # is supported. It also doesn't seem to indicate if escape sequences are supported, so we just copy the
            # content between [ and ] verbatim, except for turning ! into ^. If it becomes a problem, we'll deal with
            # it.
            '[' {
                $regex += '['
                if ($n -eq '!') {
                    $regex += '^'
                    ++$i
                }
                for($j = $i+1; $j -lt $Glob.Length; ++$j) {
                    $regex += [regex]::Escape($Glob[$j])
                    if ($Glob[$j] -eq ']') {
                        break
                    }
                }
                $i = $j
            }
            default {
                $regex += [regex]::Escape($c);
            }
        }
 
        ++$i
    }
 
    $regex += '$'
    if ($regex[0] -eq '/') {
        $regex = '^' + $regex.Substring(1)
    }
 
    $regex
}
 
# Loads expandable paths from the templates file and converts glob patterns
# to regular expressions
function Get-ExpansionPaths($Path) {
    Get-Content "$Path/.template/templates" | ForEach-Object {
        $line = $_.Trim()
        if (![string]::IsNullOrEmpty($line)) {
            if ($line[0] -ne '#') {
                ConvertFrom-GlobSyntax $line
            }
        }
    }
}
 
# Tests if a path matches an expansion pattern
function Test-PathPattern($Patterns, $Path) {
    $Path = $Path -replace '\\', '/'
    foreach($pattern in $Patterns) {
        if ($Path -match $pattern) {
            return $pattern
        }
    }
    return $false
}
 
# Expands replacement variables in the text
function Expand-Text($Replacements, $Text) {
    foreach($key in $Replacements.Keys) {
        $pattern = '(?<!$)\${' + $key + '}'
        $Text = $Text -replace $pattern,$Replacements[$key]
    }
    $Text -replace '\$\$', '$'
}

# Expans replacement variables in the specified file. The original file
# is overwritten with the result
function Expand-File($Replacements, $FilePath) {
    $result = Get-Content $FilePath -Encoding utf8NoBOM | ForEach-Object {
        Expand-Text $Replacements $_
    }
    Set-Content $FilePath -Value $result -Encoding utf8NoBOM
}

# Fail if the target directory is not empty
if (!$Force -and (Test-Path $Path) -and @(Get-ChildItem $Path).Length -gt 0) {
    Write-Error "Directory is not empty"
}
 
# Find our template directory based on the location of this script
$source = Split-Path $PSScriptRoot -Parent
Write-Verbose "PROJECT TARGET:  $Path"
Write-Verbose "TEMPLATE SOURCE: $source"

# Create a map of variable names to values
$replacements = @{
    PROJECT_NAME        = $Project
    PROJECT_NAME_PASCAL = ConvertTo-PascalCase $Project
    PROJECT_NAME_CAMEL  = ConvertTo-CamelCase $Project
    PROJECT_NAME_SNAKE  = ConvertTo-SnakeCase $Project
    PROJECT_NAME_DEFINE = (ConvertTo-SnakeCase $Project).ToUpper()
}
Write-Verbose "VARIABLES:"
Write-Verbose "  PROJECT_NAME:        $($replacements.PROJECT_NAME)"
Write-Verbose "  PROJECT_NAME_PASCAL: $($replacements.PROJECT_NAME_PASCAL)"
Write-Verbose "  PROJECT_NAME_CAMEL:  $($replacements.PROJECT_NAME_CAMEL)"
Write-Verbose "  PROJECT_NAME_SNAKE:  $($replacements.PROJECT_NAME_SNAKE)"
Write-Verbose "  PROJECT_NAME_DEFINE: $($replacements.PROJECT_NAME_DEFINE)"

# Get the files to process
$files = Get-ChildItem $source -Recurse -File

# Filter out ignored files. This could be smarter. Perhaps something in the template 
# file like our globs?
$ignorePaths = @('.template')
$files = $files | Where-Object { $ignorePaths -notcontains (Split-Path (Split-Path $_.FullName -Parent) -Leaf) }

# Process the result
Write-Verbose "GENERATING:"
$expandPatterns = Get-ExpansionPaths $source
$files | ForEach-Object {
    $source_file = $_.FullName

    $relativePath = Resolve-Path -Path $source_file -RelativeBasePath $source -Relative
    $targetPath = Join-Path $Path $relativePath
    $targetPath = Expand-Text $replacements $targetPath

    $targetDir = Split-Path $targetPath -Parent
    Write-Verbose "  COPY: $source_file -> $targetPath"

    mkdir $targetDir -Force | Out-Null
    Copy-Item $source_file $targetPath

    if (Test-PathPattern $expandPatterns $source_file) {
        Write-Verbose "EXPAND: $targetPath"
        Expand-File $replacements $targetPath
    }
}
