// sig_config.h — ARM64 byte signatures for Lua functions in libGame.so
// Source: probe_lua.py analysis of libGame.so (com.netease.yysls v3.8)
//
// Method: BL call-graph tracing from exported luaopen_* symbols + fan-in
// analysis across the entire 119MB .text section. Lua error strings are
// obfuscated so string xrefs don't work — all identification is via code
// structure.

#pragma once

#include <stdint.h>
#include <stddef.h>

struct SigEntry {
    const char* name;
    const uint8_t* pattern;
    const uint8_t* mask;   // 0xFF = must match, 0x00 = wildcard
    size_t length;
};

// =====================================================================
// lua_load — VA=0x31B2DE8
//   int lua_load(L, reader, data, chunkname, mode)
//   Calls luaD_protectedparser (0x31B7010) at +0x14
//   STP x29,x30 prologue, saves x21/x20/x19, LDR x8,[x0,#0x58]
// =====================================================================
static const uint8_t SIG_LUA_LOAD_1[] = {
    0xFD, 0x7B, 0xBD, 0xA9,  // STP x29, x30, [sp, #-0x30]!
    0xF5, 0x0B, 0x00, 0xF9,  // STR x21, [sp, #0x10]
    0xF4, 0x4F, 0x02, 0xA9,  // STP x20, x19, [sp, #0x20]
    0xFD, 0x03, 0x00, 0x91,  // MOV x29, sp
    0x08, 0x2C, 0x40, 0xF9,  // LDR x8, [x0, #0x58]
    0xF3, 0x03, 0x00, 0xAA,  // MOV x19, x0
    0xE2, 0x03, 0x01, 0x2A,  // MOV w2, w1
    0x28, 0x03, 0x00, 0xB5,  // CBNZ x8, ...
};
static const uint8_t SIG_LUA_LOAD_1_MASK[] = {
    0xFF, 0xFF, 0xFF, 0xFF,
    0xFF, 0xFF, 0xFF, 0xFF,
    0xFF, 0xFF, 0xFF, 0xFF,
    0xFF, 0xFF, 0xFF, 0xFF,
    0xFF, 0xFF, 0xFF, 0xFF,
    0xFF, 0xFF, 0xFF, 0xFF,
    0xFF, 0xFF, 0xFF, 0xFF,
    0xFF, 0x00, 0x00, 0x00,  // CBNZ offset varies
};

// =====================================================================
// luaD_pcall — VA=0x319E750, fan-in=3051
//   int luaD_pcall(L, Pfunc func, void* ud, ptrdiff_t old_top, ptrdiff_t ef)
//   Calls luaD_rawrunprotected at +0x2F8
//   SUB sp,sp,#0x40 prologue + FP register save
//   ** This is the RECOMMENDED hook target **
// =====================================================================
static const uint8_t SIG_LUAD_PCALL[] = {
    0xFF, 0x03, 0x01, 0xD1,  // SUB sp, sp, #0x40
    0xE8, 0x0B, 0x00, 0xFD,  // STR d8, [sp, #0x10]
    0xFD, 0xFB, 0x01, 0xA9,  // STP x29, x30, [sp, #0x18]
    0xF5, 0x17, 0x00, 0xF9,  // STR x21, [sp, #0x28]
    0xF4, 0x4F, 0x03, 0xA9,  // STP x20, x19, [sp, #0x30]
    0xFD, 0x63, 0x00, 0x91,  // ADD x29, sp, #0x18
};
static const uint8_t SIG_LUAD_PCALL_MASK[] = {
    0xFF, 0xFF, 0xFF, 0xFF,
    0xFF, 0xFF, 0xFF, 0xFF,
    0xFF, 0xFF, 0xFF, 0xFF,
    0xFF, 0xFF, 0xFF, 0xFF,
    0xFF, 0xFF, 0xFF, 0xFF,
    0xFF, 0xFF, 0xFF, 0xFF,
};

// =====================================================================
// luaD_rawrunprotected — VA=0x319DDD8, fan-in=32007
//   int luaD_rawrunprotected(L, Pfunc f, void* ud)
//   0x1D0 frame for setjmp() buffer — very distinctive signature
//   ** DO NOT hook this — too hot (32K callers) **
// =====================================================================
static const uint8_t SIG_LUAD_RAWRUN[] = {
    0xFD, 0x7B, 0xBC, 0xA9,  // STP x29, x30, [sp, #-0x40]!
    0xFC, 0x0B, 0x00, 0xF9,  // STR x28, [sp, #0x10]
    0xF6, 0x57, 0x02, 0xA9,  // STP x22, x21, [sp, #0x20]
    0xF4, 0x4F, 0x03, 0xA9,  // STP x20, x19, [sp, #0x30]
    0xFD, 0x03, 0x00, 0x91,  // MOV x29, sp
    0xFF, 0x43, 0x07, 0xD1,  // SUB sp, sp, #0x1D0
};
static const uint8_t SIG_LUAD_RAWRUN_MASK[] = {
    0xFF, 0xFF, 0xFF, 0xFF,
    0xFF, 0xFF, 0xFF, 0xFF,
    0xFF, 0xFF, 0xFF, 0xFF,
    0xFF, 0xFF, 0xFF, 0xFF,
    0xFF, 0xFF, 0xFF, 0xFF,
    0xFF, 0xFF, 0xFF, 0xFF,
};

// =====================================================================
// luaD_call — VA=0x3195D4C
//   void luaD_call(L, StkId func, int nresults)
//   Lower-level call dispatch (no error recovery)
// =====================================================================
static const uint8_t SIG_LUAD_CALL[] = {
    0xFD, 0x7B, 0xBD, 0xA9,  // STP x29, x30, [sp, #-0x30]!
    0xF5, 0x0B, 0x00, 0xF9,  // STR x21, [sp, #0x10]
    0xF4, 0x4F, 0x02, 0xA9,  // STP x20, x19, [sp, #0x20]
    0xFD, 0x03, 0x00, 0x91,  // MOV x29, sp
    0x0A, 0x14, 0x40, 0xF9,  // LDR x10, [x0, #0x28]
    0xE8, 0x03, 0x01, 0x2A,  // MOV w8, w1
    0xF3, 0x03, 0x00, 0xAA,  // MOV x19, x0
};
static const uint8_t SIG_LUAD_CALL_MASK[] = {
    0xFF, 0xFF, 0xFF, 0xFF,
    0xFF, 0xFF, 0xFF, 0xFF,
    0xFF, 0xFF, 0xFF, 0xFF,
    0xFF, 0xFF, 0xFF, 0xFF,
    0xFF, 0xFF, 0xFF, 0xFF,
    0xFF, 0xFF, 0xFF, 0xFF,
    0xFF, 0xFF, 0xFF, 0xFF,
};

// =====================================================================
// lua_createtable — VA=0x3198664, fan-in=273
//   void lua_createtable(L, int narr, int nrec)
//   Called by all luaopen_* with narr=0, nrec=0 (i.e. lua_newtable)
//   Previously misidentified as "lua_pcall_v1"
// =====================================================================
static const uint8_t SIG_LUA_CREATETABLE[] = {
    0xFD, 0x7B, 0xBD, 0xA9,  // STP x29, x30, [sp, #-0x30]!
    0xF5, 0x0B, 0x00, 0xF9,  // STR x21, [sp, #0x10]
    0xF4, 0x4F, 0x02, 0xA9,  // STP x20, x19, [sp, #0x20]
    0xFD, 0x03, 0x00, 0x91,  // MOV x29, sp
    0xF4, 0x03, 0x02, 0x2A,  // MOV w20, w2
    0xF5, 0x03, 0x01, 0x2A,  // MOV w21, w1
    0xF3, 0x03, 0x00, 0xAA,  // MOV x19, x0
};
static const uint8_t SIG_LUA_CREATETABLE_MASK[] = {
    0xFF, 0xFF, 0xFF, 0xFF,
    0xFF, 0xFF, 0xFF, 0xFF,
    0xFF, 0xFF, 0xFF, 0xFF,
    0xFF, 0xFF, 0xFF, 0xFF,
    0xFF, 0xFF, 0xFF, 0xFF,
    0xFF, 0xFF, 0xFF, 0xFF,
    0xFF, 0xFF, 0xFF, 0xFF,
};

// =====================================================================
// Signature arrays for scanner
// =====================================================================

static const SigEntry LUA_LOAD_SIGS[] = {
    { "lua_load_v1", SIG_LUA_LOAD_1, SIG_LUA_LOAD_1_MASK, sizeof(SIG_LUA_LOAD_1) },
};

// Primary hook target: luaD_pcall
// This replaces the old lua_pcall_v1/v2/v3 (which were misidentified)
static const SigEntry LUA_PCALL_SIGS[] = {
    { "luaD_pcall",          SIG_LUAD_PCALL,     SIG_LUAD_PCALL_MASK,     sizeof(SIG_LUAD_PCALL) },
    { "luaD_rawrunprotected",SIG_LUAD_RAWRUN,     SIG_LUAD_RAWRUN_MASK,    sizeof(SIG_LUAD_RAWRUN) },
    { "luaD_call",           SIG_LUAD_CALL,       SIG_LUAD_CALL_MASK,      sizeof(SIG_LUAD_CALL) },
};

// Supplementary signatures (for identification, not primary hooking)
static const SigEntry LUA_API_SIGS[] = {
    { "lua_createtable",     SIG_LUA_CREATETABLE, SIG_LUA_CREATETABLE_MASK, sizeof(SIG_LUA_CREATETABLE) },
};

#define LUA_LOAD_SIG_COUNT  (sizeof(LUA_LOAD_SIGS) / sizeof(LUA_LOAD_SIGS[0]))
#define LUA_PCALL_SIG_COUNT (sizeof(LUA_PCALL_SIGS) / sizeof(LUA_PCALL_SIGS[0]))
#define LUA_API_SIG_COUNT   (sizeof(LUA_API_SIGS)  / sizeof(LUA_API_SIGS[0]))
