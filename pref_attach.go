// Generate directed graph using preferential attachment model
// described in the page 70 of the book "Complex Graphs and Networks"
// by Chung and Lu.

// Graph and vertex contain only the fields needed for the generation.

package main

import (
	"errors"
	"fmt"
	"math/rand"
	"os"

	
	"github.com/ajholanda/goadt"
)

const (
	INDEGREE = 0
	OUTDEGREE = 1
)

type Arc struct{
	tip *Vertex
	next *Arc
}

// Each vertex is used as a node in a doubly linked list sorted based
// on indegree or outdegree.
type Vertex struct{
	arcs *Arc
	degree [2]int // INDEGREE and OUTDEGREE values
}

type Graph struct{
	vertices []*Vertex // heads for lists sorted according to INDEGREE and OUTDEGREE
	n, m int // number of vertices and arcs
	totalDegree [2]int // total indegree and outdegree
	prioQueues [2]*adt.PriorityQueue // priority queues to store degree
}

func NewGraph(nvertices int) (*Graph) {
	var prioQueues [2]*adt.PriorityQueue 		

	for i := 0; i < 2; i++ {
		prioQueues[i] = adt.NewPriorityQueue(adt.MAX)
	}
	
	verts := make([]*Vertex, nvertices)	

	return &Graph{verts, 0, 0, [2]int{0, 0}, prioQueues}
}

func (G *Graph) NewVertex() (*Vertex){
	v := &Vertex{nil, [2]int{0,0}}
	G.n++

	return v
}

func (G *Graph) AddArc(u, v *Vertex) {	
	fmt.Println(u,v)

	for a := u.arcs; a != nil; a = a.next {
		// the arc already exists, return
		if a.tip == v {
			return
		}
	}
	fmt.Println("add arc", u, v)
	a := &Arc{v, u.arcs}
	u.arcs = a
	G.m++	
	//Stats and priority queues update
	u.degree[INDEGREE]++
	G.prioQueues[INDEGREE].Push(u.degree[INDEGREE], u, nil)
	
	v.degree[OUTDEGREE]++
	G.prioQueues[OUTDEGREE].Push(u.degree[OUTDEGREE], v, nil)
	
	G.totalDegree[INDEGREE]++	
	G.totalDegree[OUTDEGREE]++
}

func (G *Graph) requeue(typeDegree int) {
	for !G.prioQueues[typeDegree].IsEmpty() {// empty queue
		G.prioQueues[typeDegree].Pop()
	}

	for i := 0; i < G.n; i++ {
		v := G.vertices[i]

		G.prioQueues[typeDegree].Push((*v).degree[typeDegree], v, nil)
	}
}

func (G *Graph) RandomlyChooseVertexBy(typeDegree int) (*Vertex, error) {
	var t *Vertex
	p := rand.Float64() // // `0.0 <= f < 1.0`.
	var oldV *Vertex
	
	cumProb := 0.0
	oldV = nil
	N := 0
	for !G.prioQueues[typeDegree].IsEmpty() {
		h := G.prioQueues[typeDegree].Pop()
		v := h.Key().(*Vertex)
		
		deg := (*v).degree[typeDegree]

		fmt.Println(G, t, "\tN=", N, " deg=", deg)		

		if N == 0 && deg == 0 { // disconnected graph
			return v, nil;
		}
		
		cumProb += float64(deg) / float64(G.totalDegree[typeDegree])

		if cumProb > p { // the prob range was passed
			return oldV, nil
		}
		oldV = t
		N++
	}

	go G.requeue(typeDegree)
	
	return nil, errors.New("vertex can not be null")
}

// Add a new vertex v, and add a directed edge (u,v) from v by
// randomly and independently choosing u in proportion to the indegree
// of u in the current graph G.
func (G *Graph) SourceVertexStep() {
	v := G.NewVertex()

	if G.n < 2 { // not enough vertices to make arcs
		return
	}
	
	u, err := G.RandomlyChooseVertexBy(INDEGREE)

	if err != nil {
		fmt.Println(err)
		os.Exit(-1)
	}
	G.AddArc(v, u)
}


// Add a new vertex v, and add a directed edge (u,v) to v by
// randomly and independently choosing u in proportion to the outdegree
// of u in the current graph G.
func (G *Graph) SinkVertexStep() {
	v := G.NewVertex()

	if G.n < 2 { // not enough vertices to make arcs
		return
	}
	
	u, err := G.RandomlyChooseVertexBy(OUTDEGREE)

	if err != nil {
		fmt.Println(err)
		os.Exit(-1)
	}
	
	G.AddArc(u, v)
}


func main() {
	G := NewGraph(3)

	// Source-vertex-step
	G.SourceVertexStep()

	// Sink-vertex-step
	G.SinkVertexStep()

}
