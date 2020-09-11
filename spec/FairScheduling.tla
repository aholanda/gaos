--------------------------- MODULE FairScheduling ---------------------------
EXTENDS Naturals,ProcessInterface,Sequences
CONSTANT VRuntime,
         Weight
VARIABLE cpuState,  \* CPU state
         tskState,  \* task state
         tskWeight,  \* task weight
         tskRunning, \* tasks running
         tskQ      \* task queue         
S == INSTANCE ProcessScheduler

Init == 
    /\ S!Init
    /\ tskQ = [CPU |-> <<>>] \* queue is empty at the beginning

TypeInvariant ==
    /\ S!TypeInvariant
    /\ tskWeight \in [Task -> Weight]
    /\ tskRunning \in [CPU -> Task]
    /\ tskQ \in [CPU -> Seq(Task \X VRuntime)]

Preempt(c) ==
    LET t == tskRunning[c]
    IN /\ Get(t, c, tskInt, tskInt')  
       /\ cpuState' = [cpuState EXCEPT ![c] = "idle"] 
       /\ tskQ' = [tskQ EXCEPT ![c] = Append(tskQ[c], <<t,1>>)]
       /\ tskState' = [tskState EXCEPT ![t] = "ready"]

\* timer
\* weight

Test(tQ, c) == tQ.CPU = c
          
Schedule(c) ==
  LET cTsks == SelectSeq(tskQ, Test(tskQ, c)) \* select tasks from CPU c
  IN  /\  cTsks # 0
     /\ Preempt(c) 
  
=============================================================================
\* Modification History
\* Last modified Tue Dec 11 10:43:38 BRST 2018 by ajh
\* Created Mon Dec 10 15:59:50 BRST 2018 by ajh
