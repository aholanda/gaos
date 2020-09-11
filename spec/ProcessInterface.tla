-------------------------- MODULE ProcessInterface --------------------------
VARIABLE tskInt \* Task interface variable
CONSTANTS Snd(_,_,_,_),   (* A step Snd(t, c, tskInt, tskInt') step
                             represents task t being sent to be 
                             executed in the CPU c *)
          Get(_,_,_,_),   (* A step Get(t, c, tskInt, tskInt') step
                             represents task t being preempted from 
                             CPU c *)
          (* The set of possible initial values of procInt *)
          InitTaskInt,
          (* The set of task identifiers. Task can be a process or thread. *)
          Task,
          (* The set of CPU identifiers *)
          CPU 

\* To run TLC, this comments must be kept
\* ASSUME \A t, c, piOld, piNew : /\ Snd(t, c, piOld, piNew) \in BOOLEAN
\*                               /\ Get(t, c, piOld, piNew) \in BOOLEAN  
 
NoTask == CHOOSE t : t \notin Task                            
=============================================================================
\* Modification History
\* Last modified Thu Dec 13 14:53:38 BRST 2018 by ajh
\* Created Thu Dec 06 16:45:43 BRST 2018 by ajh
