Scriptname SampleScript extends ObjectReference

Function DoNothing()
EndFunction

Function EmptyLoopTest()
    While (True)
    EndWhile
EndFunction

Function UnusedVariableTest()
    int unusedVariable
EndFunction

Function GlobalVariableTest()
    GlobalVariable someGlobalVar
EndFunction

Function DebugTraceTest()
    Debug.Trace("This is a debug trace")
EndFunction

Function UnreachableCodeTest()
    Return
    Debug.Trace("This code is unreachable")
EndFunction

Function HighNestingTest()
    If (True)
        If (True)
            If (True)
                If (True)
                    If (True)
                    EndIf
                EndIf
            EndIf
        EndIf
    EndIf
EndFunction
