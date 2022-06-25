import winim/[core, extra, utils, winstr]
import std/[segfaults, os, strutils]

const
  payload = block:
    echo staticExec r"nim c dll/loader.nim"
    staticRead"memecube.dll"

  targetProcess = "ac_client.exe"

  tempName = "temp.dll"

proc findProcess(): PROCESSENTRY32  =
  let hSnapshot = CreateToolhelp32Snapshot(TH32CS_SNAPALL, 0)

  if hSnapshot == INVALID_HANDLE_VALUE:
    echo "[-] Couldn't take snapshot"
    echo $GetLastError()
    quit()

  result.dwSize = DWORD sizeof result

  if Process32First(hSnapshot, &result) == false.WINBOOL:
    echo "[-] Couldn't get first process"
    echo $GetLastError()
    quit()

  # $$ doesn't delete \0
  while strip($$(result.szExeFile), chars = {'\0'}) != targetProcess:
    if Process32Next(hSnapshot, &result) == false.WINBOOL:
      echo "[-] Couldn't find target process"
      echo $GetLastError()
      quit()

  echo "[+] Proc found: " & $result.th32ProcessID

  discard CloseHandle(hSnapshot)

proc main() =
  echo "[*] $$ LoadLibraryA Injector $$ started"

  let
    procEntry = findProcess()
    modulePath = cstring(absolutePath(tempName))
    modulePathLen = len(modulePath) * sizeof char

  echo "[*] Module Path: ", modulePath

  let hProcess = OpenProcess(PROCESS_ALL_ACCESS, false, procEntry.th32ProcessID)

  if hProcess == 0.DWORD:
    echo "[-] Can't open process"
    echo "[*] Error ", $GetLastError()
    quit()

  echo "[+] Process handle: ", hProcess

  let szModule = VirtualAllocEx(
    hProcess, 
    NULL, 
    (modulePathLen).DWORD, 
    MEM_COMMIT or MEM_RESERVE, 
    PAGE_READWRITE
  )

  if szModule == nil:
    let error = GetLastError()

    echo "[-] Can't allocate memory"
    echo "[*] Error ", $error
    quit()

  echo "[+] Allocated memory"

  let bWritten = WriteProcessMemory(
    hProcess,
    szModule,
    unsafeAddr modulePath[0],
    (modulePathLen).SIZE_T,
    NULL
  )

  if bWritten == 0:
    let error = GetLastError()

    echo "[-] Can't write memory"
    echo "[*] Error ", $error
    quit()

  echo "[+] Wroten memory" 

  writeFile(tempName, payload)

  let hKernel = LoadLibraryA("Kernel32")
  let pLoadLib = GetProcAddress(hKernel, "LoadLibraryA")

  let hThread = CreateRemoteThreadEx(
    hProcess,
    nil,
    0.DWORD,
    cast[LPTHREAD_START_ROUTINE](pLoadLib),
    szModule,
    0.DWORD,
    nil,
    nil
  )

  if hThread == 0.Handle:
    let error = GetLastError()

    echo "[-] Can't start thread"
    echo "[*] Error ", $error
    quit()

  echo "[+] Started thread"

  WaitForSingleObject(hThread, high(int).DWORD)

  let threadExitCode: DWORD = 1
  if GetExitCodeThread(hThread, unsafeAddr threadExitCode) == FALSE:
    let error = GetLastError()

    echo "[-] Can't get thread exit code"
    echo "[*] Error ", $error
    quit()
  else:
    echo "[*] Thread exit code: ", $threadExitCode
  

  if VirtualFreeEx(hProcess, szModule, 0.SIZE_T, MEM_RELEASE) == FALSE:
    let error = GetLastError()

    echo "[-] Can't dealloc memory"
    echo "[*] Error ", $error

    quit()

  CloseHandle(hProcess)

  removeFile(tempName)

main()