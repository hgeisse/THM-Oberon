/*
 * disasm.h -- disassembler
 */


#ifndef _DISASM_H_
#define _DISASM_H_


char *disasm(Word instr, Word locus);
char *disasmFixProg(Word instr, Word locus, Fixup *fixProg);
char *disasmFixData1(Word instr, Word locus, Fixup *fixData);
char *disasmFixData2(Word instr, Word locus, Fixup *fixData);


#endif /* _DISASM_H_ */
