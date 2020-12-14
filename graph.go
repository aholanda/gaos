package graphs

// Go keeps compatibility of 64-bit types when
// compiled in 32-bit architecture.
// https://groups.google.com/g/golang-nuts/c/mtnn-01Dh_I

var defaultGraphName = "graph"

type Vertex struct {
	Name string // string to identify the vertex
	Arcs *Arc   // Head of adjacency list of arcs
}

type Arc struct {
	Tip  *Vertex // Vertex pointed by this Arc
	Next *Arc    // Next arc in the adjacency list
	Len  int     // Arc length
}

func (d *Digraph) NewArc(v *Vertex, length int) *Arc {
	return &Arc{v, nil, length}
}

func (a *Arc) Length() int {
	return a.Len
}

type Digraph struct {
	Name         string             // name of the graph
	Vertices     []Vertex           // array of vertices
	N            int                // number of vertices
	M            int                // number of arcs
	NameToVertex map[string]*Vertex // names for vertices (optional)
}

func NewDigraph(nvertices int) *Digraph {
	return &Digraph{
		Name:         defaultGraphName,
		Vertices:     make([]Vertex, nvertices),
		N:            0,
		M:            0,
		NameToVertex: make(map[string]*Vertex, 0),
	}
}

func (d *Digraph) NewVertex(name string) *Vertex {
	if v, ok := d.NameToVertex[name]; ok {
		return v
	}

	v := &d.Vertices[d.N]
	d.N++
	v.Name = name
	v.Arcs = nil
	d.NameToVertex[name] = v

	return v
}

func (d *Digraph) Order() int {
	return d.N
}

func (d *Digraph) Size() int {
	return d.M
}

func (d *Digraph) AddArc(from, to string, length int) {
	var a, b *Arc
	var v, w *Vertex

	v = d.NewVertex(from)
	w = d.NewVertex(to)
	a = d.NewArc(w, length)

	b = v.Arcs
	v.Arcs = a
	a.Next = b
	a.Tip = w

	d.M++
}

func Reverse(d *Digraph) *Digraph {
	rev := NewDigraph(d.N)
	rev.Name = d.Name + "Reversed"
	for _, v := range d.Vertices {
		for a := v.Arcs; a != nil; a = a.Next {
			w := a.Tip
			rev.AddArc(w.Name, v.Name, a.Len)
		}
	}
	return rev
}

type Graph struct {
	*Digraph
}

func NewGraph(nvertices int) *Graph {
	return &Graph{NewDigraph(nvertices)}
}

func (g *Graph) AddEdge(from, to string, len int) {
	g.AddArc(from, to, len)
	if from != to { // avoid duplication on self-loops
		g.AddArc(to, from, len)
		// discount double direction to emulate an edge
		g.M--
	}
}
