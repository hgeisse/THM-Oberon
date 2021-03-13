/*
 * fpu.h -- floating-point unit
 */


#ifndef _FPU_H_
#define _FPU_H_


#define _FP_V_FLAG	0x10		/* invalid */
#define _FP_I_FLAG	0x08		/* infinite */
#define _FP_O_FLAG	0x04		/* overflow */
#define _FP_U_FLAG	0x02		/* underflow */
#define _FP_X_FLAG	0x01		/* inexact */


Word fpAdd(Word x, Word y, Bool sub);
Word fpMul(Word x, Word y);
Word fpDiv(Word x, Word y);

Word fpFlt(Word x);
Word fpFlr(Word x);

Word fpGetFlags(void);
void fpClrFlags(void);


#endif /* _FPU_H_ */
