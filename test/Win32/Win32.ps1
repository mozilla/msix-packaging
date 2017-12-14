
$global:TESTFAILED=0
$global:BINDIR=""

function FindBinFolder {
    write-host "Searching under" (Get-Item -Path ".\" -Verbose).FullName
    if (Test-Path "..\..\.vs\bin\MakeXplat.exe" )
    {
        $global:BINDIR="..\..\.vs\bin"
    }
    elseif (Test-Path "..\..\.vscode\bin\MakeXplat.exe" )
    {
        $global:BINDIR="..\..\.vscode\bin"        
    }
    elseif (Test-Path "..\..\build\bin\MakeXplat.exe")
    {
        $global:BINDIR="..\..\build\bin"        
    }
    else
    {
        write-host "ERROR: Could not find build binaries"
        exit 2
    }

    write-host "found $global:BINDIR"
}

function CleanupUnpackFolder {
    if (Test-Path ".\..\unpack\*" )
    {
        write-host "cleaning up .\..\unpack"
        Remove-Item ".\..\unpack\*" -recurse
    }
    else {
        write-host "creating .\..\unpack"
        New-Item -ItemType Directory -Force ".\..\unpack"
    }
    if (Test-Path ".\..\unpack\*" )
    {
        write-host "ERROR: Could not cleanup .\..\unpack directory"
        exit
    }
}

function RunTest([int] $SUCCESSCODE, [string] $PACKAGE, [string] $OPT) {
    CleanupUnpackFolder
    $OPTIONS = "unpack -d .\..\unpack -p $PACKAGE $OPT"
    write-host  "------------------------------------------------------"
    write-host  "$BINDIR\MakeXplat.exe $OPTIONS"
    write-host  "------------------------------------------------------"

    $p = Start-Process $BINDIR\MakeXplat.exe -ArgumentList "$OPTIONS" -wait -NoNewWindow -PassThru
    #$p.HasExited
    $ERRORCODE = $p.ExitCode
    $a = "{0:x0}" -f $SUCCESSCODE
    $b = "{0:x0}" -f $ERRORCODE
    write-host  "expect: $a, got: $b"
    if ( $ERRORCODE -eq $SUCCESSCODE ) 
    {
        write-host  "succeeded"
    }
    else
    {
        write-host  "FAILED"
        $global:TESTFAILED=1    
    }
}

#RunTest 0x134 .\appx\SignedMismatchedPublisherName-ERROR_BAD_FORMAT.appx
FindBinFolder
RunTest 0x8bad0002 .\..\appx\Empty.appx "-sv"
RunTest 0x00000000 .\..\appx\HelloWorld.appx "-ss"
RunTest 0x8bad0042 .\..\appx\SignatureNotLastPart-ERROR_BAD_FORMAT.appx
RunTest 0x8bad0042 .\..\appx\SignedTamperedBlockMap-TRUST_E_BAD_DIGEST.appx
RunTest 0x8bad0041 .\..\appx\SignedTamperedBlockMap-TRUST_E_BAD_DIGEST.appx "-sv"
RunTest 0x8bad0042 .\..\appx\SignedTamperedCD-TRUST_E_BAD_DIGEST.appx
RunTest 0x8bad0042 .\..\appx\SignedTamperedCodeIntegrity-TRUST_E_BAD_DIGEST.appx
RunTest 0x8bad0042 .\..\appx\SignedTamperedContentTypes-TRUST_E_BAD_DIGEST.appx
RunTest 0x8bad0042 .\..\appx\SignedUntrustedCert-CERT_E_CHAINING.appx
RunTest 0x00000000 .\..\appx\StoreSigned_Desktop_x64_MoviesTV.appx
RunTest 0x00000000 .\..\appx\TestAppxPackage_Win32.appx "-ss"
RunTest 0x00000000 .\..\appx\TestAppxPackage_x64.appx "-ss"
RunTest 0x8bad0012 .\..\appx\UnsignedZip64WithCI-APPX_E_MISSING_REQUIRED_FILE.appx
RunTest 0x8bad0001 .\..\appx\BlockMap\FileDoesNotExist.appx "-ss"
RunTest 0x8bad0051 .\..\appx\BlockMap\Missing_Manifest_in_blockmap.appx "-ss"
RunTest 0x8bad0051 .\..\appx\BlockMap\ContentTypes_in_blockmap.appx "-ss"
RunTest 0x8bad0041 .\..\appx\BlockMap\Invalid_Bad_Block.appx "-ss"
RunTest 0x00000000 .\..\appx\BlockMap\Size_wrong_uncompressed.appx "-ss"
RunTest 0x00000000 .\..\appx\BlockMap\HelloWorld.appx "-ss"
RunTest 0x80070002 .\..\appx\BlockMap\Extra_file_in_blockmap.appx "-ss"
RunTest 0x8bad0051 .\..\appx\BlockMap\File_missing_from_blockmap.appx "-ss"
RunTest 0x80070002 .\..\appx\BlockMap\No_blockmap.appx "-ss"
RunTest 0x8bad1003 .\..\appx\BlockMap\Bad_Namespace_Blockmap.appx "-ss"
RunTest 0x8bad0051 .\..\appx\BlockMap\Duplicate_file_in_blockmap.appx "-ss"

CleanupUnpackFolder

write-host "-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-="
if ( $global:TESTFAILED -eq 1 )
{
    write-host "                           FAILED                                 "
    exit 134
}
else
{
    write-host "                           passed                                 "
    exit 0
}