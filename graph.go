package graphs

import (
	"errors"
	"strconv"
)

type VertexId int

type Digraph struct {
	ID           string              // name of the graph
	Adjs         [][]VertexId        // array of adjacencies
	N            int                 // number of vertices
	M            int                 // number of arcs
	Keys         []string            // store vertices' names
	NameToVertex map[string]VertexId // names for vertices (optional)
}

func NewDigraph(nvertices int) *Digraph {
	d := &Digraph{
		ID:           "digraph",
		Adjs:         make([][]VertexId, nvertices),
		N:            nvertices,
		M:            0, // number of arcs
		Keys:         make([]string, nvertices),
		NameToVertex: make(map[string]VertexId, nvertices),
	}
	for i := range d.Adjs {
		d.Adjs[i] = make([]VertexId, 0)
	}
	return d
}

func (d *Digraph) NameVertex(v VertexId, name string) {
	if d.hasVertex(v) {
		if _, ok := d.NameToVertex[name]; !ok {
			d.NameToVertex[name] = v
			d.Keys[v] = name
		}
	}
}

func (d *Digraph) VertexName(v VertexId) string {
	if d.hasVertex(v) {
		return d.Keys[v]
	}
	return ""
}

// Order of the graph
func (d *Digraph) V() int {
	return d.N
}

// Size of the graph in arcs
func (d *Digraph) A() int {
	return d.M
}

// Size of the graph in arcs
func (d *Digraph) Size() int {
	return d.M
}

func (d *Digraph) AddArc(v, w VertexId) error {
	if d.hasVertex(v) == false {
		from := strconv.Itoa(int(v))
		return errors.New("vertex index " + from + " is out of bounds")
	}

	if d.hasVertex(w) == false {
		to := strconv.Itoa(int(w))
		return errors.New("vertex index " + to + " is out of bounds")
	}

	d.Adjs[v] = append(d.Adjs[v], w)

	d.M++

	return nil
}

func (d *Digraph) hasVertex(v VertexId) bool {
	if int(v) < d.N {
		return true
	}
	return false
}

func Reverse(d *Digraph) *Digraph {
	rev := NewDigraph(d.N)
	rev.ID = d.ID + "Reversed"
	for v := range d.Adjs {
		for _, w := range d.Adjs[v] {
			rev.AddArc(w, VertexId(v))
		}
	}
	return rev
}

type Graph struct {
	*Digraph
	MM int
}

func NewGraph(nvertices int) *Graph {
	return &Graph{NewDigraph(nvertices), 0}
}

func (g *Graph) AddEdge(v, w VertexId) {
	g.AddArc(v, w)
	if v != w {
		g.AddArc(w, v)
	}
	g.MM++
}

// Size of the graph in edges
func (g *Graph) E() int {
	return g.MM
}

func (g *Graph) Size() int {
	return g.MM
}
