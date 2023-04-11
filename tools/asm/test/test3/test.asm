//
// test.asm -- test fixup methods
//

	// fixup method IMMEDIATE
	ADD	R1,R2,U1
	SUB	R3,R4,U2
	MOV	R5,U1
	MOV	R6,U2
	MOVH	R7,U1
	MOVH	R8,U2
	.SET	U1,0x0000DEAD
	.SET	U2,0xFFFFBEEF

	// fixup method TARGET
	B	V
V:

	// fixup method OFFSET
	STW	R1,R2,W
	.SET	W,-234

	// fixup method WORD
	.WORD	X, X, X
	.SET	X,0x12345678

	// fixup method BYTE
	.BYTE	Y, Y, Y
	.SET	Y,0x12345678
