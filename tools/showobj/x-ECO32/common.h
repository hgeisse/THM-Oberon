/*
 * common.h -- common definitions
 */


#ifndef _COMMON_H_
#define _COMMON_H_


typedef unsigned char Byte;		/* 8 bit quantities */
typedef unsigned short Half;		/* 16 bit quantities */
typedef unsigned int Word;		/* 32 bit quantities */


typedef enum { false, true } Bool;	/* truth values */


typedef struct fixup {
  Word addr;			/* address where fixup takes place */
  int high;			/* high bits of fixup info */
  int mno;			/* module which is referenced */
  int val1;			/* first value (different meanings) */
  int val2;			/* second value (different meanings) */
  struct fixup *next;		/* next fixup record in list */
} Fixup;


void error(char *fmt, ...);


#endif /* _COMMON_H_ */
