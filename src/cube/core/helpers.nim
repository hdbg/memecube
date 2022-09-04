import winim

proc verify(x: ThreadEntry32): bool = 
  (x.th32ThreadID != GetCurrentThreadId()) and (x.th32OwnerProcessID == GetCurrentProcessId())

proc freezeThread(threadID: int32) = 
  let thHandle = OpenThread(THREAD_SUSPEND_RESUME, false, threadID)

  assert SuspendThread(thHandle) != -1

  discard thHandle.CloseHandle

proc freezeProgram* = 
  let hSnapshot = CreateToolhelp32Snapshot(TH32CS_SNAPTHREAD, 0)

  echo "LAst err: ", GetLastError()

  var currThread: ThreadEntry32
  zeroMem addr(currThread), sizeof(ThreadEntry32)
  currThread.dwSize = sizeof(ThreadEntry32).int32

  discard Thread32First(hSnapshot, addr currThread)

  echo "CUID: ", currThread.th32ThreadID

  if currThread.verify:
    freezeThread currThread.th32ThreadID

  while Thread32Next(hSnapshot, addr currThread) != FALSE:
    if currThread.th32ThreadID != GetCurrentThreadId():
      freezeThread currThread.th32ThreadID



proc unfreezeThread(threadID: int32) = 
  let thHandle = OpenThread(THREAD_SUSPEND_RESUME, false, threadID)

  assert ResumeThread(thHandle) != -1

  discard thHandle.CloseHandle

proc unfreezeProgram* = 
  let hSnapshot = CreateToolhelp32Snapshot(TH32CS_SNAPTHREAD, 0)

  var currThread: ThreadEntry32
  zeroMem addr(currThread), sizeof(ThreadEntry32)
  currThread.dwSize = sizeof(ThreadEntry32).int32

  discard Thread32First(hSnapshot, addr currThread)

  if currThread.verify:
    unfreezeThread currThread.th32ThreadID

  while Thread32Next(hSnapshot, addr currThread) != FALSE:
    if currThread.th32ThreadID != GetCurrentThreadId():
      unfreezeThread currThread.th32ThreadID

# ================

template tempWrite*(address: pointer, length: int, body: untyped) =
  var oldProtect: DWORD
  VirtualProtect(cast[LPVOID](address), length.SIZE_T, PAGE_EXECUTE_READWRITE, unsafeAddr oldProtect)
  body
  VirtualProtect(cast[LPVOID](address), length.SIZE_T, oldProtect, unsafeAddr oldProtect)