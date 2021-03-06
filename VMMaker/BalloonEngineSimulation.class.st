"
Support for the VM simulator Balloon graphics calls
"
Class {
	#name : #BalloonEngineSimulation,
	#superclass : #BalloonEnginePlugin,
	#instVars : [
		'bbObj',
		'savedBBObj',
		'workBufferArray'
	],
	#category : 'VMMaker-InterpreterSimulation'
}

{ #category : #simulation }
BalloonEngineSimulation class >> simulatePrimitive: aString receiver: rcvr args: args [

	| proxy bb |
	proxy := InterpreterProxy new.
	proxy synthesizeStackFor: rcvr with: args.
	bb := self simulatorClass new.
	bb setInterpreter: proxy.
	bb initialiseModule.
	"rendering state is loaded in the primitive implementations"
	[bb perform: aString asSymbol] on: Exception do: [:ex |
		proxy success: false].
	^ proxy stackValue: 0

]

{ #category : #simulation }
BalloonEngineSimulation >> assert: bool [
	bool ifFalse:[^self error:'Assertion failed'].
]

{ #category : #simulation }
BalloonEngineSimulation >> circleCosTable [
	^CArrayAccessor on:
#(1.0 0.98078528040323 0.923879532511287 0.831469612302545 0.7071067811865475 0.555570233019602 0.38268343236509 0.1950903220161286 0.0 -0.1950903220161283 -0.3826834323650896 -0.555570233019602 -0.707106781186547 -0.831469612302545 -0.9238795325112865 -0.98078528040323 -1.0 -0.98078528040323 -0.923879532511287 -0.831469612302545 -0.707106781186548 -0.555570233019602 -0.3826834323650903 -0.1950903220161287 0.0 0.1950903220161282 0.38268343236509 0.555570233019602 0.707106781186547 0.831469612302545 0.9238795325112865 0.98078528040323 1.0 )
]

{ #category : #simulation }
BalloonEngineSimulation >> circleSinTable [
	^CArrayAccessor on:
#(0.0 0.1950903220161282 0.3826834323650897 0.555570233019602 0.707106781186547 0.831469612302545 0.923879532511287 0.98078528040323 1.0 0.98078528040323 0.923879532511287 0.831469612302545 0.7071067811865475 0.555570233019602 0.38268343236509 0.1950903220161286 0.0 -0.1950903220161283 -0.3826834323650896 -0.555570233019602 -0.707106781186547 -0.831469612302545 -0.9238795325112865 -0.98078528040323 -1.0 -0.98078528040323 -0.923879532511287 -0.831469612302545 -0.707106781186548 -0.555570233019602 -0.3826834323650903 -0.1950903220161287 0.0 )
]

{ #category : #simulation }
BalloonEngineSimulation >> colorTransform [
	^super colorTransform asPluggableAccessor:
		(Array 
			with:[:obj :index| obj floatAt: index]
			with:[:obj :index :value| obj floatAt: index put: value])
]

{ #category : #simulation }
BalloonEngineSimulation >> copyBitsFrom: x0 to: x1 at: y [
	"Simulate the copyBits primitive"

	| bb |
	bbObj isInteger ifTrue:
		["Create a proxy object to handle BitBlt calls"
		bb := savedBBObj
				ifNil: [BitBltSimulator new
						initialiseModule;
						setInterpreter: interpreterProxy;
						yourself]
				ifNotNil: [savedBBObj].
		(bb loadBitBltFrom: bbObj)
			ifTrue: [bbObj := bb]
			ifFalse: [^ self]].
	bbObj copyBitsFrom: x0 to: x1 at: y.
"
	interpreterProxy showDisplayBits: bbObj destForm
		Left: bb affectedLeft Top: bb affectedTop
		Right: bb affectedRight Bottom: bb affectedBottom.
"
]

{ #category : #'debug support' }
BalloonEngineSimulation >> debugDrawBezier: line [
	| canvas p1 p2 p3 |
	self assert:(self isBezier: line).
	p1 := (self edgeXValueOf: line) @ (self edgeYValueOf: line) // self aaLevelGet.
	p2 := (self bezierViaXOf: line) @ (self bezierViaYOf: line) // self aaLevelGet.
	p3 := (self bezierEndXOf: line) @ (self bezierEndYOf: line) // self aaLevelGet.
	canvas := Display getCanvas.
	canvas
		line: p1 to: p2 width: 2 color: Color blue;
		line: p2 to: p3 width: 2 color: Color blue.
]

{ #category : #'debug support' }
BalloonEngineSimulation >> debugDrawEdge: edge [
	self assert: (self isEdge: edge).
	(self isLine: edge) ifTrue:[^self debugDrawLine: edge].
	(self isBezier: edge) ifTrue:[^self debugDrawBezier: edge].
	self halt.
]

{ #category : #'debug support' }
BalloonEngineSimulation >> debugDrawHLine: yValue [
	| canvas |
	canvas := Display getCanvas.
	canvas
		line: 0 @ (yValue // self aaLevelGet)
		to: Display extent x @ (yValue // self aaLevelGet)
		width: 2
		color: Color green.
]

{ #category : #'debug support' }
BalloonEngineSimulation >> debugDrawLine: line [
	| canvas |
	self assert: (self isLine: line).
	canvas := Display getCanvas.
	canvas
		line: (self edgeXValueOf: line) @ (self edgeYValueOf: line) // self aaLevelGet
		to: (self lineEndXOf: line) @ (self lineEndYOf: line) // self aaLevelGet
		width: 2
		color: Color red.
]

{ #category : #'debug support' }
BalloonEngineSimulation >> debugDrawLineFrom: pt1 to: pt2 [
	| canvas |
	canvas := Display getCanvas.
	canvas
		line: (pt1 at: 0) @ (pt1 at: 1) // self aaLevelGet
		to: (pt2 at: 0) @ (pt2 at: 1) // self aaLevelGet
		width: 1
		color: Color red.
]

{ #category : #'debug support' }
BalloonEngineSimulation >> debugDrawPt: pt [
	| canvas |
	canvas := Display getCanvas.
	canvas
		fillRectangle:((pt-2) corner: pt+2) color: Color red
]

{ #category : #'debug support' }
BalloonEngineSimulation >> debugDrawPtLineFrom: pt1 to: pt2 [
	| canvas |
	canvas := Display getCanvas.
	canvas
		line: pt1
		to: pt2
		width: 1
		color: Color red.
]

{ #category : #'debug support' }
BalloonEngineSimulation >> debugPrintObjects [
	| object end |
	<inline: false>
	object := 0.
	end := objUsed.
	[object < end] whileTrue:[
		Transcript cr; 
			nextPut:$#; print: object; space;
			print: (self objectHeaderOf: object); space.
		(self isEdge: object) 
			ifTrue:[Transcript nextPutAll:'(edge) '].
		(self isFill:object)
			ifTrue:[Transcript nextPutAll:'(fill) '].
		Transcript print: (self objectLengthOf: object); space.
		Transcript endEntry.
		object := object + (self objectLengthOf: object).
	].
]

{ #category : #'debug support' }
BalloonEngineSimulation >> debugPrintPoints: n [
	Transcript cr.
	n > 0 ifTrue:[
		Transcript print: (self point1Get at: 0) @ (self point1Get at: 1); space.
	].
	n > 1 ifTrue:[
		Transcript print: (self point2Get at: 0) @ (self point2Get at: 1); space.
	].
	n > 2 ifTrue:[
		Transcript print: (self point3Get at: 0) @ (self point3Get at: 1); space.
	].
	n > 3 ifTrue:[
		Transcript print: (self point4Get at: 0) @ (self point4Get at: 1); space.
	].
	Transcript endEntry.
]

{ #category : #simulation }
BalloonEngineSimulation >> dispatchOn: anInteger in: selectorArray [
	"Simulate a case statement via selector table lookup.
	The given integer must be between 0 and selectorArray size-1, inclusive.
	For speed, no range test is done, since it is done by the at: operation."
	self perform: (selectorArray at: (anInteger + 1)).
]

{ #category : #simulation }
BalloonEngineSimulation >> edgeTransform [
	^super edgeTransform asPluggableAccessor:
		(Array 
			with:[:obj :index| obj floatAt: index]
			with:[:obj :index :value| obj floatAt: index put: value])
]

{ #category : #'simulation support' }
BalloonEngineSimulation >> ensureUpToDateOverrideFor: aSelector [
	"Ensure that an override that uses 32-bit integer arithmetic exists for aSelector"
	| source |
	source := self transformedSourceFor: self class superclass >> aSelector.
	(self class sourceCodeAt: aSelector ifAbsent: ['']) ~= source ifTrue:
		[self class compile: source classified: 'generated overrides']
]

{ #category : #'simulation support' }
BalloonEngineSimulation >> ensureUpToDateOverrides [
	"Ensure that all methods that require int and unsigned int arithmetic are overridden."
	self selectorsForIntMethods do:
		[:selector| self ensureUpToDateOverrideFor: selector]
]

{ #category : #initialize }
BalloonEngineSimulation >> initialiseModule [
	super initialiseModule.
	^ true
]

{ #category : #initialize }
BalloonEngineSimulation >> initialize [
	doProfileStats := false.
	bbPluginName := 'BitBltPlugin'.
	self ensureUpToDateOverrides
]

{ #category : #simulation }
BalloonEngineSimulation >> ioMicroMSecs [
	^Time millisecondClockValue
]

{ #category : #simulation }
BalloonEngineSimulation >> loadBitBltFrom: oop [
	(bbObj isInteger or: [bbObj isNil]) ifFalse:
		[savedBBObj := bbObj].
	bbObj := oop.
	^true
]

{ #category : #simulation }
BalloonEngineSimulation >> loadPointIntAt: index from: intArray [
	"Load the int value from the given index in intArray"
	^(index bitAnd: 1) = 0
		ifTrue:[(intArray getObject at: (index // 2) + 1) x]
		ifFalse:[(intArray getObject at: (index // 2) + 1) y]
]

{ #category : #simulation }
BalloonEngineSimulation >> loadPointShortAt: index from: intArray [ 
	"Load the short value from the given index in intArray"
	| long |
	long := intArray at: index // 2.
	long isPoint
		ifTrue: [^ (index bitAnd: 1)
					= 0
				ifTrue: [long x]
				ifFalse: [long y]].
	^ ((index bitAnd: 1)
			= 0
		ifTrue: [interpreterProxy halfWordHighInLong32: long]
		ifFalse: [interpreterProxy halfWordLowInLong32: long]) signedIntFromShort

]

{ #category : #simulation }
BalloonEngineSimulation >> loadWordTransformFrom: transformOop into: destPtr length: n [ 
	"Load a float array transformation from the given oop"
	| srcPtr |
	srcPtr := interpreterProxy firstIndexableField: transformOop.
	"Use BalloonArray's float conversion shell.  It stores both the float bits into
	 the heap object, and the float object into the simArray.  This is needed for
	 correct simulation, otherwise there will be errors in BalloonArray>>floatAt:"
	0 to: n - 1 do: [:i| destPtr at: i put: (srcPtr floatAt: i)]
]

{ #category : #simulation }
BalloonEngineSimulation >> makeUnsignedFrom: integer [
	integer < 0 
		ifTrue:[^(0 - integer - 1) bitInvert32]
		ifFalse:[^integer]
]

{ #category : #'accessing objects' }
BalloonEngineSimulation >> obj: object at: index [
	"Override to correctly map objBuffer access, which has type int *"
	^(objBuffer at: object + index) signedIntFromLong
]

{ #category : #'accessing objects' }
BalloonEngineSimulation >> obj: object at: index put: value [
	"Override to correctly map objBuffer access, which has type int *"
	objBuffer at: object + index put: value signedIntToLong
]

{ #category : #initialize }
BalloonEngineSimulation >> primitiveInitializeBuffer [

	"Fix an uninitialized variable (should probably go into the real engine too)"
	super primitiveInitializeBuffer.
	self spanEndAAPut: 0.
]

{ #category : #initialize }
BalloonEngineSimulation >> primitiveSetBitBltPlugin [
	"Primitive. Set the BitBlt plugin to use."
	| pluginName |
	pluginName := interpreterProxy stackValue: 0.
	"Must be string to work"
	(interpreterProxy isBytes: pluginName) 
		ifFalse:[^interpreterProxy primitiveFail].
	(interpreterProxy stringOf: pluginName) = bbPluginName
		ifTrue: [interpreterProxy pop: 1. "Return receiver"]
		ifFalse: [^interpreterProxy primitiveFail]
]

{ #category : #'debug support' }
BalloonEngineSimulation >> printAET [

	| edge |
	Transcript cr; show:'************* ActiveEdgeTable **************'.
	0 to: self aetUsedGet - 1 do:[:i|
		edge := aetBuffer at: i.
		Transcript cr;
			print: i; space;
			nextPutAll:'edge #';print: edge; space;
			nextPutAll:'x: '; print: (self edgeXValueOf: edge); space;
			nextPutAll:'y: '; print: (self edgeYValueOf: edge); space;
			nextPutAll:'z: '; print: (self edgeZValueOf: edge); space;
			nextPutAll:'fill0: '; print: (self edgeLeftFillOf: edge); space;
			nextPutAll:'fill1: '; print: (self edgeRightFillOf: edge); space;
			nextPutAll:'lines: '; print: (self edgeNumLinesOf: edge); space.
		(self areEdgeFillsValid: edge) ifFalse:[Transcript nextPutAll:' disabled'].
		Transcript endEntry.
	].
]

{ #category : #'debug support' }
BalloonEngineSimulation >> printGET [

	| edge |
	Transcript cr; show:'************* GlobalEdgeTable **************'.
	0 to: self getUsedGet - 1 do:[:i|
		edge := getBuffer at: i.
		Transcript cr;
			print: i; space;
			nextPutAll:'edge #';print: edge; space;
			nextPutAll:'x: '; print: (self edgeXValueOf: edge); space;
			nextPutAll:'y: '; print: (self edgeYValueOf: edge); space;
			nextPutAll:'z: '; print: (self edgeZValueOf: edge); space;
			nextPutAll:'fill0: '; print: (self edgeLeftFillOf: edge); space;
			nextPutAll:'fill1: '; print: (self edgeRightFillOf: edge); space;
			nextPutAll:'lines: '; print: (self edgeNumLinesOf: edge); space.
		(self areEdgeFillsValid: edge) ifFalse:[Transcript nextPutAll:' disabled'].
		Transcript endEntry.
	].
]

{ #category : #'debug support' }
BalloonEngineSimulation >> quickPrint: curve [
	Transcript nextPut:$(;
		print: curve start;
		space;
		print: curve via;
		space;
		print: curve end;
		nextPut:$).
]

{ #category : #'debug support' }
BalloonEngineSimulation >> quickPrintBezier: bezier [
	Transcript cr.
	Transcript nextPut:$(;
		print: (self edgeXValueOf: bezier)@(self edgeYValueOf: bezier);
		space;
		print: (self bezierViaXOf: bezier)@(self bezierViaYOf: bezier);
		space;
		print: (self bezierEndXOf: bezier)@(self bezierEndYOf: bezier);
		nextPut:$).
	Transcript endEntry.
]

{ #category : #'debug support' }
BalloonEngineSimulation >> quickPrintBezier: index first: aBool [
	aBool ifTrue:[Transcript cr].
	Transcript nextPut:$(;
		print: (self bzStartX: index)@(self bzStartY: index);
		space;
		print: (self bzViaX: index)@(self bzViaY: index);
		space;
		print: (self bzEndX: index)@(self bzEndY: index);
		nextPut:$).
	Transcript endEntry.
]

{ #category : #simulation }
BalloonEngineSimulation >> rShiftTable [
	^CArrayAccessor on: #(0 5 4 0 3 0 0 0 2 0 0 0 0 0 0 0 1).
]

{ #category : #'simulation support' }
BalloonEngineSimulation >> selectorsForIntMethods [
	"Ensure that all methods that require int and unsigned int arithmetic are overridden."
	| selectors cg |
	selectors := OrderedCollection new.
	cg := CCodeGenerator new.
	^(BalloonEnginePlugin organization listAtCategoryNamed: 'beziers-simple') select:
		[:selector|
		(BalloonEnginePlugin >> selector) pragmas anySatisfy:
			[:p| | type |
			 p keyword == #var:type: ifTrue:
				[type := p arguments last].
			 p keyword == #var:declareC: ifTrue:
				[type := cg
							extractTypeFor: p arguments first
							fromDeclaration: p arguments last].
			 type notNil
			 and: [type last = $* ifTrue:
					[type := cg baseTypeForPointerType: type].
				#(int #'unsigned int') includes: (cg baseTypeForType: type)]]]
]

{ #category : #simulation }
BalloonEngineSimulation >> shortRunLengthAt: index from: runArray [
	"Load the short value from the given index in intArray"

	^ interpreterProxy halfWordHighInLong32: (runArray at: index)
]

{ #category : #simulation }
BalloonEngineSimulation >> shortRunValueAt: index from: runArray [
	"Load the short value from the given index in intArray"

	^ (interpreterProxy halfWordLowInLong32: (runArray at: index)) signedIntFromShort 
]

{ #category : #simulation }
BalloonEngineSimulation >> showDisplayBits [
	"Do nothing."
]

{ #category : #simulation }
BalloonEngineSimulation >> smallSqrtTable [
	"Return a lookup table for rounded integer square root values from 0 to 31"
	^CArrayAccessor on:#(0 1 1 2 2 2 2 3 3 3 3 3 3 4 4 4 4 4 4 4 4 5 5 5 5 5 5 5 5 5 5 6 )
]

{ #category : #'generated overrides' }
BalloonEngineSimulation >> stepToFirstBezierIn: bezier at: yValue [
	"Initialize the bezier at yValue.
	TODO: Check if reducing maxSteps from 2*deltaY to deltaY 
		brings a *significant* performance improvement.
		In theory this should make for double step performance
		but will cost in quality. Might be that the AA stuff will
		compensate for this - but I'm not really sure."

	<inline: false>
	<var: #updateData type: 'int *'>
	| updateData deltaY maxSteps scaledStepSize squaredStepSize startX startY viaX viaY endX endY fwX1 fwX2 fwY1 fwY2 fwDx fwDDx fwDy fwDDy |
	((self isWide: bezier) not and: [ yValue >= (self bezierEndYOf: bezier) ])
		ifTrue: [ ^ self edgeNumLinesOf: bezier put: 0 ].	"Do a quick check if there is anything at all to do"	"Now really initialize bezier"
	startX := self edgeXValueOf: bezier.
	startY := self edgeYValueOf: bezier.
	viaX := self bezierViaXOf: bezier.
	viaY := self bezierViaYOf: bezier.
	endX := self bezierEndXOf: bezier.
	endY := self bezierEndYOf: bezier.
	deltaY := endY - startY.	"Initialize integer forward differencing"
	fwX1 := (viaX - startX) * 2.
	fwX2 := startX + endX - (viaX * 2).
	fwY1 := (viaY - startY) * 2.
	fwY2 := startY + endY - (viaY * 2).
	maxSteps := deltaY * 2.
	maxSteps < 2
		ifTrue: [ maxSteps := 2 ].
	scaledStepSize := 16r1000000 // maxSteps.
	squaredStepSize := self absoluteSquared8Dot24: scaledStepSize.
	fwDx := fwX1 * scaledStepSize.
	fwDDx := fwX2 * squaredStepSize * 2.
	fwDx := fwDx + (fwDDx // 2).
	fwDy := fwY1 * scaledStepSize.
	fwDDy := fwY2 * squaredStepSize * 2.
	fwDy := fwDy + (fwDDy // 2).	"Store the values"
	self edgeNumLinesOf: bezier put: deltaY.
	updateData := self bezierUpdateDataOf: bezier.
	updateData at: GBUpdateX put: (startX * 256) asC_int.
	updateData at: GBUpdateY put: (startY * 256) asC_int.
	updateData at: GBUpdateDX put: fwDx asC_int.
	updateData at: GBUpdateDY put: fwDy asC_int.
	updateData at: GBUpdateDDX put: fwDDx asC_int.
	updateData at: GBUpdateDDY put: fwDDy asC_int.	"And step to the first scan line"
	(startY := self edgeYValueOf: bezier) = yValue
		ifFalse: [ 
			self stepToNextBezierIn: bezier at: yValue.	"Adjust number of lines remaining"
			self edgeNumLinesOf: bezier put: deltaY - (yValue - startY) ]
]

{ #category : #'generated overrides' }
BalloonEngineSimulation >> stepToNextBezierForward: updateData at: yValue [
	"Incrementally step to the next scan line in the given bezier update data.
	Note: This method has been written so that inlining works, e.g.,
		not declaring updateData as 'int*' but casting it on every use."

	<var: #updateData type: 'int *'>
	<inline: true>
	| minY lastX lastY fwDx fwDy |
	lastX := updateData at: GBUpdateX.
	lastY := updateData at: GBUpdateY.
	fwDx := updateData at: GBUpdateDX.
	fwDy := updateData at: GBUpdateDY.
	minY := yValue * 256.	"Step as long as we haven't yet reached minY and also
	as long as fwDy is greater than zero thus stepping down.
	Note: The test for fwDy should not be necessary in theory
		but is a good insurance in practice."
	[ minY > lastY and: [ fwDy >= 0 ] ]
		whileTrue: [ 
			lastX := lastX + (fwDx + 16r8000 signedBitShift: -16).
			lastY := lastY + (fwDy + 16r8000 signedBitShift: -16).
			fwDx := fwDx + (updateData at: GBUpdateDDX).
			fwDy := fwDy + (updateData at: GBUpdateDDY) ].
	updateData at: GBUpdateX put: lastX asC_int.
	updateData at: GBUpdateY put: lastY asC_int.
	updateData at: GBUpdateDX put: fwDx asC_int.
	updateData at: GBUpdateDY put: fwDy asC_int.
	^ lastX signedBitShift: -8
]

{ #category : #simulation }
BalloonEngineSimulation >> stopBecauseOf: stopReason [
	"Don't stop because of need to flush."
	stopReason = GErrorNeedFlush ifFalse:[
		^super stopBecauseOf: stopReason.
	].
]

{ #category : #'simulation support' }
BalloonEngineSimulation >> transformedSourceFor: m [
	"Transform all references to #int variables in the source code of m into var asC_int
	 and all references to #'unsigned int' variables into var asC_unsigned_int"
	| tm rules cgen |
	tm := m asTranslationMethodOfClass: TMethod.
	tm recordDeclarationsIn: (cgen := CCodeGenerator new).
	rules := RBParseTreeRewriter new.
	#(#'int *' #'unsigned int *')
		with: #(asC_int asC_unsigned_int)
		do: [:type :coercionMessage|
			(tm declarations keys select: [:v| (tm typeFor: v in: cgen) = type]) do:
				[:var| "make this use ``@expr and editSource breaks"
				rules replace: var, ' at: `@index put: `@expr' with: var, ' at: `@index put: `@expr ', coercionMessage]].
	#(#'int' #'unsigned int')
		with: #(asC_int asC_unsigned_int)
		do: [:type :coercionMessage|
			(tm declarations keys select: [:v| (tm typeFor: v in: cgen) = type]) do:
				[:var|
				rules
					replace: var, ' := `@args' with: var, ' := `@args ', coercionMessage;
					replace: var with: var, ' ', coercionMessage]].
	(rules executeTree: (m methodClass parseTreeFor: m selector)) ifTrue:
		[^rules tree newSource].
	self error: 'parse tree rewrite failed'
]

{ #category : #simulation }
BalloonEngineSimulation >> workBufferPut: wbOop [
	interpreterProxy isInterpreterProxy 
		ifTrue:[^super workBufferPut: wbOop].
	workBuffer := ((interpreterProxy firstIndexableField: wbOop) as: BalloonArray) asCArrayAccessor.
	workBufferArray ifNil:
		[workBufferArray := Array new: (interpreterProxy slotSizeOf: wbOop) withAll: 0].
	workBuffer getObject setSimArray: workBufferArray
]
