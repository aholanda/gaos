(* 
    Extracted from "Specifying Systems" book by Leslie Lamport.
    http://lamport.azurewebsites.net/tla/book.html?back-link=learning.html#book
*)
------------------------------- MODULE Graphs ------------------------------- 
LOCAL INSTANCE Naturals
LOCAL INSTANCE Sequences

IsDirectedGraph(G) ==
   /\ G.node \in [v : BOOLEAN]   
   /\ G = [node |-> G.node, edge |-> G.edge]
   /\ G.edge \subseteq (G.node \X G.node)

DirectedSubgraph(G) ==    
  {H \in [node : SUBSET G.node, edge : SUBSET (G.node \X G.node)] :
     IsDirectedGraph(H) /\ H.edge \subseteq G.edge}
-----------------------------------------------------------------------------
IsUndirectedGraph(G) ==
   /\ IsDirectedGraph(G)
   /\ \A e \in G.edge : <<e[2], e[1]>> \in G.edge

UndirectedSubgraph(G) == {H \in DirectedSubgraph(G) : IsUndirectedGraph(H)}
-----------------------------------------------------------------------------
Path(G) == {p \in Seq(G.node) :
             /\ p # << >>
             /\ \A i \in 1..(Len(p)-1) : <<p[i], p[i+1]>> \in G.edge}

AreConnectedIn(m, n, G) == 
  \E p \in Path(G) : (p[1] = m) /\ (p[Len(p)] = n)

IsStronglyConnected(G) == 
  \A m, n \in G.node : AreConnectedIn(m, n, G) 
-----------------------------------------------------------------------------
IsTreeWithRoot(G, r) ==
  /\ IsDirectedGraph(G)
  /\ \A e \in G.edge : /\ e[1] # r
                       /\ \A f \in G.edge : (e[1] = f[1]) => (e = f)
  /\ \A n \in G.node : AreConnectedIn(n, r, G)

-----------------------------------------------------------------------------
(******************** SEARCHES ********************)
(** DEPTH FIRST SEARCH **)
RECURSIVE Explore(_, _)
Explore(G, n) ==
  /\ n.v = TRUE
  /\ \E m \in G.node : /\ <<m, n>> \in G.edge
  	 	  	  		   /\ m.v = FALSE 
					   /\ Explore(G, m)
DepthFirstSearch(G) == \* dfs
  /\ \A n \in G.node : /\ n.v = FALSE 
 	   	  	  		   /\ Explore(G, n)
=============================================================================
