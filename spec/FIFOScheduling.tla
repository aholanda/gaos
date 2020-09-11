--------------------------- MODULE FIFOScheduling ---------------------------
EXTENDS Naturals,ProcessInterface,Sequences
CONSTANT QLen \* Queue length
VARIABLE cpuState,  \* CPU state
         tskState,  \* task state
         tskRunning, \* tasks running
         tskQ      \* task queue         
S == INSTANCE ProcessScheduler
ASSUME (QLen \in Nat) /\ (QLen > 0)

Init == 
    /\ S!Init
    /\ tskInt \in InitTaskInt
    /\ tskRunning = [c \in CPU |-> NoTask]
    /\ tskQ = [c \in CPU |-> <<>>] \* queue is empty at the beginning

TypeInvariant ==
    /\ S!TypeInvariant
    /\ tskRunning \in [CPU -> Task \cup {NoTask}]
    /\ tskQ \in [CPU -> Seq(Task)]

Enqueue == /\ \E c \in CPU, t \in Task:
                 /\ t \notin Seq(tskQ[c][1])
                 /\ Len(tskQ[c]) < QLen
                 /\ tskQ' = [tskQ EXCEPT ![c] = Append(tskQ[c], t)]
                 /\ tskState' = [tskState EXCEPT ![t] = "ready"]
                 /\ UNCHANGED <<cpuState,tskInt,tskRunning>>               
Schedule(c) ==
  LET t == Head(tskQ[c])
  IN  /\  (Len(tskQ[c]) # 0) /\ (tskState[t] = "ready")
      /\ tskQ' = [tskQ EXCEPT ![c] = Tail(tskQ[c])]
      /\ IF cpuState[c] = "busy"
                        THEN cpuState = [cpuState EXCEPT ![c] = "preempt"]
                        ELSE UNCHANGED  cpuState
      /\ tskState' = [tskState EXCEPT ![t] = "prepared"]
      /\ tskRunning' = [tskRunning EXCEPT ![c] = t]
      /\ UNCHANGED tskInt

Preempt(c) ==
    LET t == tskRunning[c]
    IN /\ cpuState[c] = "preempt" /\ tskState[t] = "prepared"
       /\ Get(t, c, tskInt, tskInt')
       /\ cpuState' = [cpuState EXCEPT ![c] = "idle"]
       /\ Len(tskQ[c]) < QLen 
       /\ tskQ' = [tskQ EXCEPT ![c] = Append(tskQ[c], <<t>>)]
       /\ tskState' = [tskState EXCEPT ![t] = "ready"]
      
Do(c) ==
      LET t == tskRunning[c]
      IN /\ cpuState[c] = "preempt" /\  tskState[t] = "running"
         /\ Snd(t, c, tskInt, tskInt')         
         /\ cpuState' = [cpuState EXCEPT ![c] = "busy"] 
         
vars == <<cpuState, tskInt, tskState, tskRunning, tskQ>>

Next == 
    \E c \in CPU : 
        \/ Enqueue
        \/ Preempt(c) 
        \/ Schedule(c) 
        \/ Do(c)

Spec == Init /\ [][Next]_<<vars>>
=============================================================================
