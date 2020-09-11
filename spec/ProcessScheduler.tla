-------------------------- MODULE ProcessScheduler --------------------------
EXTENDS Naturals, ProcessInterface
VARIABLES cpuState,  \* Store the state of CPUs
          tskState   \* Store the state of tasks
                    
Init ==
    /\ cpuState = [c \in CPU |-> "idle"]
    /\ tskState = [t \in Task |-> "ready"]

TypeInvariant == 
    /\ cpuState \in [CPU -> {"idle", "busy"}]
    /\ tskState \in [Task -> {"blocked", "locked", "ready", 
                              "prepared", "running"}]
    
Schedule(t, c) ==  \* Send process p to be executed in CPU c 
    /\ cpuState[c] = "idle"
    /\ tskState[t] = "ready"
    /\ Snd(t, c, tskInt, tskInt')
    /\ cpuState' = [cpuState EXCEPT ![c] = "busy"]
    /\ tskState' = [tskState EXCEPT ![t] = "running"]

Preempt(t, c) ==  \* Get process p from CPU c
    /\ cpuState[c] = "busy"
    /\ tskState[t] = "running"
    /\ Get(t, c, tskInt, tskInt')
    /\ cpuState' = [cpuState EXCEPT ![c] = "idle"]
    /\ tskState' = [tskState EXCEPT ![t] = "ready"]
    
Next == \E t \in Task, c \in CPU : Schedule(t,c) \/ Preempt(t,c)

Spec == Init /\ [][Next]_<<cpuState,tskState>>        
=============================================================================
\* Modification History
\* Last modified Thu Dec 13 14:48:03 BRST 2018 by ajh
\* Created Thu Dec 06 15:58:33 BRST 2018 by ajh
