# Windows vs Android Lua Signature Comparison

**Date:** 2026-04-01  
**Source:** Independent scan of `libGame.so` extracted from [WWM_APK/split_config.arm64_v8a.apk](file:///Users/nguyenvinh/Desktop/Coding/WWM-trainer/WWM_APK/split_config.arm64_v8a.apk)  
**Binary:** 134.2 MB, AArch64 ELF (`e_machine=0xB7`)

---

## 1. Can Windows x86-64 Signatures Be Reused?

> [!CAUTION]
> **NO.** The Windows signatures are x86-64 machine code and cannot match ARM64 binaries. This is a fundamental architecture incompatibility — not a matter of tuning.

| Windows Signature | Bytes | Result |
|---|---|---|
| `lua_load` sig1 (`48 89 5C 24 08...`) | 26 | ❌ No match |
| `lua_load` sig2 (`48 89 5C 24 10...`) | 26 | ❌ No match |
| `lua_pcall` sig3 (`48 89 74 24 18...`) | 29 | ❌ No match |

**Why:** x86-64 uses `MOV [rsp+8], rbx` / `SUB rsp, 0x50` prologues. ARM64 uses `STP x29, x30, [sp, #-N]!` prologues. Completely different instruction encoding.

---

## 2. What IS Shared Between Windows and Android

Despite different machine code, the **hooking strategy pattern** is identical:

| Concept | Windows ([inject.cpp](file:///Users/nguyenvinh/Desktop/Coding/WWM-trainer/Scripts/inject/inject.cpp)) | Android ([inject_android.cpp](file:///Users/nguyenvinh/Desktop/Coding/WWM-trainer/Scripts/inject/android/native/inject_android.cpp)) |
|---|---|---|
| **Hook target** | `lua_pcallk` (x64) | `luaD_pcall` (ARM64) |
| **Load function** | `lua_load` (direct) | `luaD_protectedparser` (bypass wrapper) |
| **Execution** | `lua_pcall` (via hook trampoline) | `luaD_call` (unprotected, bypass TLS) |
| **Pattern scan** | PE `.text` section | ELF `.text` (LOAD PF_X segment) |
| **Hook library** | MinHook | Dobby |
| **Command channel** | Named pipe | TCP socket |
| **Reader callback** | [MyLuaReader](file:///Users/nguyenvinh/Desktop/Coding/WWM-trainer/Scripts/inject/inject.cpp#156-161) (same logic) | [MyLuaReader](file:///Users/nguyenvinh/Desktop/Coding/WWM-trainer/Scripts/inject/inject.cpp#156-161) (same logic) |
| **ReaderData struct** | `{const char* s; size_t size}` | Same |

> [!IMPORTANT]
> The **flow** is portable. The **byte patterns** are not. Each platform needs its own signature set.

---

## 3. ARM64 Signature Scan Results (Independent Verification)

Scanned the full 119 MB executable LOAD segment of `libGame.so`.

### 3.1 Unique Matches (✅ Reliable)

| Signature | Bytes | Matches | Address | Verdict |
|---|---|---|---|---|
| `lua_load` (load_wrapper) | 32 | **1** | `0x31B2DE8` | ✅ Unique — confirmed same as existing code |

> [!NOTE]
> The `lua_load` signature includes the game-specific `LDR x8, [x0, #0x58]` (custom mutex at `L+0x58`) which makes it highly unique. This is reliable.

### 3.2 Low Ambiguity (⚠️ Minor duplicates)

| Signature | Bytes | Matches | Primary | Other |
|---|---|---|---|---|
| `luaD_call` | 28 | **2** | `0x3195D4C` ✅ | `0x3196D04` (similar function, likely `luaD_callnoyield`) |
| `luaD_rawrunprotected` | 24 | **4** | `0x319DDD8` ✅ | 3 others at `0x4C52828`, `0x5B0D02C`, `0x6BCA010` |
| `lua_createtable` | 28 | **4** | `0x3198664` ✅ | 3 others at `0x34D07EC`, `0x4DE5E14`, `0x4E1A0F4` |

The primary addresses all match the existing [inject_android.cpp](file:///Users/nguyenvinh/Desktop/Coding/WWM-trainer/Scripts/inject/android/native/inject_android.cpp) code. The duplicates are structurally similar but diverge after the prologue (different BL targets, different register usage).

### 3.3 High Ambiguity (❌ Too Generic)

| Signature | Bytes | Matches | Verdict |
|---|---|---|---|
| `luaD_pcall` | 24 | **73** | ❌ **Signature is too short/generic** |

> [!WARNING]
> The `luaD_pcall` signature (`SUB sp,#0x40` + `STR d8` + `STP x29,x30` + `STR x21` + `STP x20,x19` + `ADD x29,sp,#0x18`) matches **73 functions** across the binary. This prologue pattern is common for any function with a 0x40-byte frame saving FP registers + one SIMD register.
>
> The correct `luaD_pcall` is at `0x319E750` (first match), but the signature **cannot reliably find it** on a different build version. It needs to be extended.

---

## 4. String Obfuscation Confirmed

| String | Found? |
|---|---|
| `\x1bLua` (bytecode header) | ❌ NOT FOUND |
| `Lua 5.4` / `Lua 5.3` | ❌ NOT FOUND |
| `attempt to call a` | ❌ NOT FOUND |
| `stack overflow` | ❌ NOT FOUND |
| `error in error handling` | ❌ NOT FOUND |
| `coroutine` / `tostring` / `setmetatable` | ❌ NOT FOUND |
| `__index` / `__newindex` / `__gc` | ❌ NOT FOUND |
| `not enough memory` | ❌ NOT FOUND |
| `luaopen_*` (in dynstr) | ✅ 5 occurrences |
| `pcall` (in dynstr) | ✅ 1 occurrence |
| `require` (in dynstr) | ✅ 2 occurrences |

**All Lua runtime strings are encrypted.** Only exported symbol names survive (in `.dynstr`). This confirms the previous report — string xrefs cannot be used for function identification.

---

## 5. Exported Lua Symbols

Only 5 `luaopen_*` functions are exported (all others stripped):

| Symbol | Address |
|---|---|
| `luaopen_memory_leak_checker` | `0x324AB0C` |
| `luaopen_mime_core` | `0x323D5D0` |
| `luaopen_socket_core` | `0x323D354` |
| `luaopen_socket_serial` | `0x3240E64` |
| `luaopen_socket_unix` | `0x3243044` |

No `lua_load`, `lua_pcall`, `luaD_pcall`, etc. in the symbol table — fully stripped.

---

## 6. Additional Discovery: Mutex Field `L+0x58`

Scanned for `LDR x8, [x0, #0x58]` instruction (`0xF9402C08`):

- **226 matches** across the binary
- **At `0x31B2DF8`** — this is `lua_load` prologue + 0x10 (confirmed, inside our matched function)
- The custom mutex at `L+0x58` is accessed by many game functions, not just Lua wrappers

---

## 7. Recommendations

### For Cross-Version Reliability

1. **`luaD_pcall` signature MUST be extended** — 24 bytes → need at least 32-40 bytes to reduce from 73 matches. Add the `MRS x21, TPIDR_EL0` instruction at +0x18 and the subsequent `LDR x8, [x21, #0x28]` as they're distinctive for this function's TLS access pattern.

2. **`luaD_call` is good** — 2 matches is manageable. The second match (`0x3196D04`) is likely `luaD_callnoyield` and can be disambiguated by checking subsequent instructions.

3. **`lua_load` is excellent** — unique match due to game-specific mutex field. However, this specificity means if the game changes the mutex offset, the sig breaks.

### For Porting the Windows Approach

| What | Portable? | Notes |
|---|---|---|
| Hook-on-pcall strategy | ✅ | Same concept, different target (`luaD_pcall` vs `lua_pcallk`) |
| [MyLuaReader](file:///Users/nguyenvinh/Desktop/Coding/WWM-trainer/Scripts/inject/inject.cpp#156-161) callback | ✅ | Identical struct layout |
| Pattern scanning | ✅ | Same algorithm, different signatures |
| `lua_load()` direct call | ❌ | Android has wrapper with mutex deadlock — must use `luaD_protectedparser` |
| `lua_pcall()` for execution | ❌ | Android has TLS locking — must use `luaD_call` |
| Named pipe IPC | ❌ | Android uses TCP socket instead |
| DLL injection | ❌ | Android uses smali patching + `System.loadLibrary` |
| String obfuscation bypass | N/A | Windows doesn't need it; Android strings are encrypted |

---

## 8. Summary

```
Windows inject.cpp signatures → Android APK:  ❌ CANNOT be reused (x86 vs ARM64)
Android sig_config.h vs APK binary:
  lua_load (wrapper):       ✅ CONFIRMED — 1 unique match at 0x31B2DE8
  luaD_pcall:               ⚠️ TOO GENERIC — 73 matches (needs longer sig)
  luaD_rawrunprotected:     ✅ CONFIRMED — 4 matches, primary at 0x319DDD8
  luaD_call:                ✅ CONFIRMED — 2 matches, primary at 0x3195D4C
  lua_createtable:          ✅ CONFIRMED — 4 matches, primary at 0x3198664
```

The **hooking pattern/strategy is portable**, but each platform requires:
1. Platform-specific byte signatures (x86-64 vs ARM64)
2. Platform-specific workarounds (Android: mutex bypass, TLS bypass, JNI exception guard)
3. Platform-specific IPC (pipe vs TCP)
4. Platform-specific injection mechanism (DLL inject vs APK patching)
