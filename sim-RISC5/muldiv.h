/*
 * muldiv.h -- integer multiply and divide, signed and unsigned
 */


#ifndef _MULDIV_H_
#define _MULDIV_H_


void intMul(Word op1, Word op2, Bool u, Word *loResPtr, Word *hiResPtr);
void intDiv(Word op1, Word op2, Bool u, Word *quoPtr, Word *remPtr);


#endif /* _MULDIV_H_ */
