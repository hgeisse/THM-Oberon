/*
 * mmu.h -- MMU simulation
 */


#ifndef _MMU_H_
#define _MMU_H_


#define TLB_SHFT	5		/* log2 of number of TLB entries */
#define TLB_SIZE	(1 << TLB_SHFT)	/* total number of TLB entries */
#define TLB_MASK	(TLB_SIZE - 1)	/* mask for number of TLB entries */
#define TLB_FIXED	4		/* number of fixed TLB entries */

#define TLB_WRITE	(1 << 1)	/* write bit in EntryLo */
#define TLB_VALID	(1 << 0)	/* valid bit in EntryLo */

#define MMU_ACCS_MASK	0x07		/* bits used in BadAccs */
#define MMU_ACCS_READ	0x00		/* access type = read */
#define MMU_ACCS_WRITE	0x04		/* access type = write */
#define MMU_ACCS_BYTE	0x00		/* access width = byte */
#define MMU_ACCS_HALF	0x01		/* access width = half */
#define MMU_ACCS_WORD	0x02		/* access width = word */


typedef struct {
  Word page;		/* 20 high-order bits of virtual address */
  Word frame;		/* 18 high-order bits of physical address */
  Bool write;		/* must be true to allow writing to the page */
  Bool valid;		/* must be true for the entry to be valid */
} TLB_Entry;


Word mmuFetchInstr(Word vAddr, Bool userMode);
Word mmuReadWord(Word vAddr, Bool userMode);
Half mmuReadHalf(Word vAddr, Bool userMode);
Byte mmuReadByte(Word vAddr, Bool userMode);
void mmuWriteWord(Word vAddr, Word data, Bool userMode);
void mmuWriteHalf(Word vAddr, Half data, Bool userMode);
void mmuWriteByte(Word vAddr, Byte data, Bool userMode);

Word mmuGetIndex(void);
void mmuSetIndex(Word value);
Word mmuGetEntryHi(void);
void mmuSetEntryHi(Word value);
Word mmuGetEntryLo(void);
void mmuSetEntryLo(Word value);
Word mmuGetBadAddr(void);
void mmuSetBadAddr(Word value);
Word mmuGetBadAccs(void);
void mmuSetBadAccs(Word value);

void mmuTbs(void);
void mmuTbwr(void);
void mmuTbri(void);
void mmuTbwi(void);

TLB_Entry mmuGetTLB(int index);
void mmuSetTLB(int index, TLB_Entry tlbEntry);

void mmuReset(void);
void mmuInit(void);
void mmuExit(void);


#endif /* _MMU_H_ */
