Extension { #name : #VariableNode }

{ #category : #'*VMMaker-C translation' }
VariableNode >> asTranslatorNodeIn: aTMethod [
	"Answer a TParseNode subclass equivalent of me"
	name = 'true' ifTrue: [^ TConstantNode new setValue: true].
	name = 'false' ifTrue: [^ TConstantNode new setValue: false].
	^TVariableNode new setName: name
]
