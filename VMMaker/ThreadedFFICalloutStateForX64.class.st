"
A ThreadedFFICalloutStateForX64 is a holder for the callout state maintained while marshalling an FFI call on an X64 (x86-64) system.
"
Class {
	#name : #ThreadedFFICalloutStateForX64,
	#superclass : #ThreadedFFICalloutState,
	#instVars : [
		'integerRegisterIndex',
		'floatRegisterIndex',
		'integerRegisters',
		'floatRegisters'
	],
	#category : 'VMMaker-Plugins-FFI'
}

{ #category : #translation }
ThreadedFFICalloutStateForX64 class >> instVarNamesAndTypesForTranslationDo: aBinaryBlock [
	"enumerate aBinaryBlock with the names and C type strings for the inst vars to include in a ThreadedFFICalloutState struct."
	"self subclasses collect: [:ea| ea -> ea typdef]"
	ThreadedFFICalloutState instVarNamesAndTypesForTranslationDo: aBinaryBlock.
	self instVarNames, ThreadedFFICalloutStateForX64 instVarNames do:
		[:ivn|
		aBinaryBlock
			value: ivn
			value: (ivn caseOf: {
						['integerRegisters']	-> [{#sqInt. '[NumIntRegArgs]'}].
						['floatRegisters']	-> [{#double. '[NumFloatRegArgs]'}] }
					otherwise:
						[#char])]
]

{ #category : #translation }
ThreadedFFICalloutStateForX64 class >> pluginClass [
	^self subclassResponsibility
]

{ #category : #accessing }
ThreadedFFICalloutStateForX64 >> floatRegisterIndex [

	^ floatRegisterIndex
]

{ #category : #accessing }
ThreadedFFICalloutStateForX64 >> floatRegisters [
	"Answer the value of floatRegisters"

	^ floatRegisters
]

{ #category : #accessing }
ThreadedFFICalloutStateForX64 >> incrementFloatRegisterIndex [
	^floatRegisterIndex := floatRegisterIndex + 1
]

{ #category : #accessing }
ThreadedFFICalloutStateForX64 >> incrementIntegerRegisterIndex [
	^integerRegisterIndex := integerRegisterIndex + 1
]

{ #category : #'initialize-release' }
ThreadedFFICalloutStateForX64 >> initialize [
	super initialize.
	integerRegisterIndex := floatRegisterIndex := 0.
	integerRegisters := CArrayAccessor on: (Array new: self class pluginClass numRegArgs).
	floatRegisters := CArrayAccessor on: (Array new: self class pluginClass numFloatRegArgs)
]

{ #category : #accessing }
ThreadedFFICalloutStateForX64 >> integerRegisterIndex [

	^ integerRegisterIndex
]

{ #category : #accessing }
ThreadedFFICalloutStateForX64 >> integerRegisters [
	"Answer the value of integerRegisters"

	^ integerRegisters
]
