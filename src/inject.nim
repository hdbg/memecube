import winim/[core, extra, utils, winstr]
import std/[segfaults, os, strutils]

import chronicles

const
  payload = block:
    let result = staticExec r"nim c --app:lib --passL:-Wl,--dynamicbase --passC:-m32 --passL:-m32 -o:memecube.dll main.nim"

    if "Error" in result:
      echo result
      raise Defect.newException("Dll compilation error!")

    staticRead"memecube.dll"

  targetProcess = "ac_client.exe"

  tempName = "temp.dll"


template safeCallBool(message: static string, expression) =
  if expression == FALSE:
    error message, code=GetLastError()
    quit()

template safeCall0(message: static string, expression) =
  if expression == 0:
    error message, code=GetLastError()
    quit()

proc findProcess(): PROCESSENTRY32  =
  let hSnapshot = CreateToolhelp32Snapshot(TH32CS_SNAPALL, 0)

  if hSnapshot == INVALID_HANDLE_VALUE:
    echo "[-] Couldn't take snapshot"
    echo $GetLastError()
    quit()

  result.dwSize = DWORD sizeof result

  safeCallBool("process32First", Process32First(hSnapshot, &result))

  # $$ doesn't delete \0
  while strip($$(result.szExeFile), chars = {'\0'}) != targetProcess:
    safeCallBool "process32Next", Process32Next(hSnapshot, &result)
  
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

  safeCall0 "openProcess", hProcess

  echo "[+] Process handle: ", hProcess

  let szModule = VirtualAllocEx(
    hProcess, 
    NULL, 
    (modulePathLen).DWORD, 
    MEM_COMMIT or MEM_RESERVE, 
    PAGE_READWRITE
  )

  safeCall0 "virtualAlloc", cast[DWORD](szModule)

  # echo "[+] Allocated memory"

  let bWritten = WriteProcessMemory(
    hProcess,
    szModule,
    unsafeAddr modulePath[0],
    (modulePathLen).SIZE_T,
    NULL
  )

  safeCall0 "WriteProcessMemory", bWritten

  # echo "[+] Wroten memory" 

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

  safeCall0 "CreateThread", int hThread

  echo "[+] Invoked thread"

  WaitForSingleObject(hThread, high(int).DWORD)

  # let threadExitCode: DWORD = 1
  # if GetExitCodeThread(hThread, unsafeAddr threadExitCode) == FALSE:
  #   let error = GetLastError()

  #   echo "[-] Can't get thread exit code"
  #   echo "[*] Error ", $error
  #   quit()
  # else:
  #   echo "[*] Thread exit code: ", $threadExitCode
  

  safeCallBool "VirtualFreeEx", VirtualFreeEx(hProcess, szModule, 0.SIZE_T, MEM_RELEASE)
  CloseHandle(hProcess)
  removeFile(tempName)

main()