/*
 * graph.h -- graphics controller simulation
 */


#ifndef _GRAPH_H_
#define _GRAPH_H_


Word graphRead(Word addr);
void graphWrite(Word addr, Word data);

void graphInit(void);
void graphExit(void);


#endif /* _GRAPH_H_ */
