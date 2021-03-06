Class {
	#name : #NewCoObjectMemorySimulatorMSB,
	#superclass : #NewCoObjectMemorySimulator,
	#category : 'VMMaker-JITSimulation'
}

{ #category : #'memory access' }
NewCoObjectMemorySimulatorMSB >> byteAt: byteAddress [
	| lowBits bpwMinus1 |
	bpwMinus1 := self wordSize-1.
	lowBits := byteAddress bitAnd: bpwMinus1.
	^ ((self longAt: byteAddress - lowBits)
		bitShift: (lowBits - bpwMinus1) * 8)
		bitAnd: 16rFF
]

{ #category : #'memory access' }
NewCoObjectMemorySimulatorMSB >> byteAt: byteAddress put: byte [
	| longWord shift lowBits bpwMinus1 longAddress |
	bpwMinus1 := self wordSize-1.
	lowBits := byteAddress bitAnd: bpwMinus1.
	longAddress := byteAddress - lowBits.
	longWord := self longAt: longAddress.
	shift := (bpwMinus1 - lowBits) * 8.
	longWord := longWord
				- (longWord bitAnd: (16rFF bitShift: shift))
				+ (byte bitShift: shift).
	self assert: longAddress < freeStart.
	self longAt: longAddress put: longWord.
	^byte
]

{ #category : #'memory access' }
NewCoObjectMemorySimulatorMSB >> byteSwapped32IfBigEndian: w [
	"Accelerate, we now we are big endian"
	^w byteSwap32
]

{ #category : #'memory access' }
NewCoObjectMemorySimulatorMSB >> byteSwapped64IfBigEndian: w [
	"Accelerate, we now we are big endian"
	^w byteSwap64
]

{ #category : #'float primitives' }
NewCoObjectMemorySimulatorMSB >> fetchFloatAt: floatBitsAddress into: aFloat [
	aFloat at: 1 put: (self long32At: floatBitsAddress).
	aFloat at: 2 put: (self long32At: floatBitsAddress+4)
]

{ #category : #'memory access' }
NewCoObjectMemorySimulatorMSB >> halfWordHighInLong32: long32 [
	"Used by Balloon"

	^ long32 bitShift: -16
]

{ #category : #'memory access' }
NewCoObjectMemorySimulatorMSB >> halfWordLowInLong32: long32 [
	"Used by Balloon"

	^ long32 bitAnd: 16rFFFF
]

{ #category : #'image save/restore' }
NewCoObjectMemorySimulatorMSB >> nextLongFrom: aStream [
	"Read a 32- or 64-bit quantity from the given (binary) stream."

	^ aStream nextNumber: self wordSize
]

{ #category : #'image save/restore' }
NewCoObjectMemorySimulatorMSB >> nextShortFrom: aStream [
	"Read a 16-bit quantity from the given (binary) stream."
	^aStream nextNumber: 2
]

{ #category : #'image save/restore' }
NewCoObjectMemorySimulatorMSB >> nextWord32From: aStream [
	"Read a 32-bit quantity from the given (binary) stream."

	^aStream nextNumber: 4
]

{ #category : #'memory access' }
NewCoObjectMemorySimulatorMSB >> shortAt: byteAddress [
    "Return the half-word at byteAddress which must be even."
	| lowBits bpwMinus2 |
	bpwMinus2 := self wordSize-2.
	lowBits := byteAddress bitAnd: bpwMinus2.
	^ ((self longAt: byteAddress - lowBits)
		bitShift: (lowBits - bpwMinus2) * 8)
		bitAnd: 16rFFFF

]

{ #category : #'memory access' }
NewCoObjectMemorySimulatorMSB >> shortAt: byteAddress put: a16BitValue [
    "Return the half-word at byteAddress which must be even."
	| longWord shift lowBits bpwMinus2 longAddress |
	bpwMinus2 := self wordSize-2.
	lowBits := byteAddress bitAnd: bpwMinus2.
	longAddress := byteAddress - lowBits.
	longWord := self longAt: longAddress.
	shift := (bpwMinus2 - lowBits) * 8.
	longWord := longWord
				- (longWord bitAnd: (16rFFFF bitShift: shift))
				+ (a16BitValue bitShift: shift).
	self longAt: longAddress put: longWord

]

{ #category : #'float primitives' }
NewCoObjectMemorySimulatorMSB >> storeFloatAt: floatBitsAddress from: aFloat [

	self long32At: floatBitsAddress put: (aFloat at: 1).
	self long32At: floatBitsAddress+4 put: (aFloat at: 2)
]

{ #category : #'memory access' }
NewCoObjectMemorySimulatorMSB >> vmEndianness [
	"return 0 for little endian, 1 for big endian"
	^1
]
