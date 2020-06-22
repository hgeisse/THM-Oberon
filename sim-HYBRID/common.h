/*
 * common.h -- common definitions and functions
 */


#ifndef _COMMON_H_
#define _COMMON_H_


#define SERDEV_FILE	"serial.dev"		/* serial dev file */


typedef enum { false = 0, true = 1 } Bool;

typedef unsigned int Word;
typedef unsigned char Byte;


void error(char *fmt, ...);


#endif /* _COMMON_H_ */
