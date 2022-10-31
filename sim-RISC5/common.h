/*
 * common.h -- common definitions and functions
 */


#ifndef _COMMON_H_
#define _COMMON_H_


typedef enum { false = 0, true = 1 } Bool;

typedef unsigned int Word;
typedef unsigned short Half;
typedef unsigned char Byte;


void error(char *fmt, ...);
void warning(char *fmt, ...);


#endif /* _COMMON_H_ */
