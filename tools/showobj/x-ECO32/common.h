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
  int mno;			/* module which is referenced */
  int val;			/* value (different meanings) */
  struct fixup *next;		/* next fixup record in list */
} Fixup;


void error(char *fmt, ...);


#endif /* _COMMON_H_ */
