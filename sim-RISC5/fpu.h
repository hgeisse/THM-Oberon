/*
 * fpu.h -- floating-point unit
 */


#ifndef _FPU_H_
#define _FPU_H_


Word fpAdd(Word x, Word y, Bool sub);
Word fpMul(Word x, Word y);
Word fpDiv(Word x, Word y);

Word fpFlt(Word x);
Word fpFlr(Word x);


#endif /* _FPU_H_ */
