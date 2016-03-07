" Vim syntax file
syn case ignore

" asm opcodes
syn keyword rgbInstruction adc add and bit call ccf cp cpl
syn keyword rgbInstruction daa dec di ei ex halt inc jp jr ld ldd ldi ldh
syn keyword rgbInstruction ldio nop or pop push res ret reti rl rla rlc rlca
syn keyword rgbInstruction rr rra rrc rrca rst sbc scf set sla sra srl stop
syn keyword rgbInstruction sub swap xor

" section types
syn keyword rgbType CODE DATA BSS HOME VRAM HRAM
syn keyword rgbType ALIGNED_CODE ALIGNED_DATA ALIGNED_HOME

" labels
syn match rgbLabel		"[a-z_][a-z0-9_]*:"

" Any other stuff
syn match rgbIdentifier		"[a-z_][a-z0-9_]*"

" RGBDS commands
syn keyword rgbPreProc	DB
syn keyword rgbPreProc	DW
syn keyword rgbPreProc	DS
syn keyword rgbPreProc	EQU
syn keyword rgbPreProc	EQUS
syn keyword rgbPreProc	IMPORT
syn keyword rgbPreProc	EXPORT
syn keyword rgbPreProc	GLOBAL
syn keyword rgbPreProc	XREF
syn keyword rgbPreProc	XDEF
syn keyword rgbPreProc	DIV
syn keyword rgbPreProc	MUL
syn keyword rgbPreProc	SIN
syn keyword rgbPreProc	COS
syn keyword rgbPreProc	TAN
syn keyword rgbPreProc	ASIN
syn keyword rgbPreProc	ACOS
syn keyword rgbPreProc	ATAN
syn keyword rgbPreProc	ATAN2
syn keyword rgbPreProc	FAIL
syn keyword rgbPreProc	WARN
syn keyword rgbPreCondit	IF
syn keyword rgbPreCondit	ELSE
syn keyword rgbPreCondit	ENDC
syn keyword rgbPreProc	INCBIN
syn keyword rgbPreProc	INCLUDE
syn keyword rgbMacro	MACRO
syn keyword rgbMacro	ENDM
syn keyword rgbPreProc	BANK
syn keyword rgbPreProc	DEF
syn keyword rgbPreProc	OPT
syn keyword rgbPreProc	POPO
syn keyword rgbPreProc	PUSHO
syn keyword rgbPreProc	POPS
syn keyword rgbPreProc	PUSHS
syn keyword rgbPreProc	PRINTT
syn keyword rgbPreProc	PRINTV
syn keyword rgbPreProc	PRINTF
syn keyword rgbPreProc	PURGE
syn keyword rgbPreProc	REPT
syn keyword rgbPreProc	ENDR
syn keyword rgbPreProc	RSSET
syn keyword rgbPreProc	RERESET
syn keyword rgbPreProc	RB
syn keyword rgbPreProc	RW
syn keyword rgbPreProc	SECTION
" prefer to have it highlighted as instruction
" syn keyword rgbPreProc	SET
syn keyword rgbPreProc	SHIFT

" strings
syn match rgbString		"\".*\""
" 'foo' is not a string

" Numbers
syn match rgbNumber		"[0-9]\+"
syn match rgbNumber		"\$[0-9a-fA-F]\+"
syn match rgbNumber		"%[0-1]\+"
syn match rgbNumber		"0[xXhH][0-9a-fA-F]\+"
syn match rgbNumber		"0[bB][0-1]*"
syn match rgbNumber		"0[oO\@qQ][0-7]\+"
syn match rgbNumber		"0[dD][0-9]\+"

" predefined symbols
syn match rgbPresym		"_PI"
syn match rgbPresym		"_RS"
syn match rgbPresym		"_NARG"
syn match rgbPresym		"__LINE__"
syn match rgbPresym		"__FILE__"
syn match rgbPresym		"__DATE__"
syn match rgbPresym		"__TIME__"

" comments
syn match rgbComment		";.*"

syn case match

" Define the default highlighting.
if version >= 508 || !exists("did_rgb_syntax_inits")
  if version < 508
    let did_rgb_syntax_inits = 1
    command -nargs=+ HiLink hi link <args>
  else
    command -nargs=+ HiLink hi def link <args>
  endif

  HiLink rgbSection		Special
  HiLink rgbLabel		Label
  HiLink rgbComment		Comment
  HiLink rgbInstruction		Statement
  HiLink rgbInclude		Include
  HiLink rgbPreCondit		PreCondit
  HiLink rgbMacro		Macro
  HiLink rgbNumber		Number
  HiLink rgbPreProc		PreProc
  HiLink rgbString		String
  HiLink rgbType		Type
  HiLink rgbIdentifier		Identifier
  HiLink rgbPresym		Constant

  delcommand HiLink
endif

let b:current_syntax = "rgb"
