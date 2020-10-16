package graphs

// Go keeps compatibility of 64-bit types when
// compiled in 32-bit architecture.
// https://groups.google.com/g/golang-nuts/c/mtnn-01Dh_I

// TODO: check the number of bytes occupied by int in golang
type ArcIndex = int
type VertexIndex = int

type Vertex struct {
	name string
	adj  []ArcIndex // Adjacency list of arcs indices
}

func (v *Vertex) Adj() []ArcIndex {
	return v.adj
}

func (v *Vertex) AddArc(ai ArcIndex) {
	v.adj = append(v.adj, ai)
}

type Arc struct {
	tip VertexIndex // Vertex index
	len uint32      // arc length
}

func (d *Digraph) NewArc(vi VertexIndex, len uint32) ArcIndex {
	d.arcs = append(d.arcs, Arc{vi, len})
	ai := d.m
	d.m++

	return ai
}

func (a *Arc) Tip() VertexIndex {
	return a.tip
}

func (a *Arc) Length() uint32 {
	return a.len
}

type Digraph struct {
	name              string                 // name of the graph
	vertices          []Vertex               // array of vertices
	arcs              []Arc                  // array of arcs
	n                 VertexIndex            // number of vertices
	m                 ArcIndex               // number of arcs
	nameToVertexIndex map[string]VertexIndex // names for vertices (optional)
}

func NewDigraph(name string) *Digraph {
	return &Digraph{
		name,
		make([]Vertex, 0),
		make([]Arc, 0),
		0,
		0,
		make(map[string]VertexIndex, 0),
	}
}

func (d *Digraph) Arc(ai ArcIndex) *Arc {
	return &d.arcs[ai]
}

func (d *Digraph) Vertex(vi VertexIndex) *Vertex {
	return &d.vertices[vi]
}

func (d *Digraph) Order() VertexIndex {
	return d.n
}

func (d *Digraph) Size() ArcIndex {
	return d.m
}

func (d *Digraph) VertexIndex(name string) VertexIndex {
	vi, ok := d.nameToVertexIndex[name]
	if !ok {
		v := Vertex{name, nil}
		d.vertices = append(d.vertices, v)
		vi = d.n
		d.n++
	}
	return vi
}

func (d *Digraph) Vertices() []Vertex {
	return d.vertices
}

func (d *Digraph) AddArc(vi, wi VertexIndex, len uint32) {
	// TODO validate indices vi and wi
	v := &d.vertices[vi]

	ai := d.NewArc(wi, len)
	v.AddArc(ai)
}

func (d *Digraph) AddArcByName(from, to string, len uint32) {
	vi := d.VertexIndex(from)
	wi := d.VertexIndex(from)

	d.AddArc(vi, wi, len)
}

func Reverse(d *Digraph) {
	rev := NewDigraph(d.name)
	for vi, v := range d.Vertices() {
		for ai := range v.Adj() {
			a := d.Arc(ai)
			wi := a.Tip()
			rev.AddArc(wi, vi, a.Length())
		}
	}
}

type Graph struct {
	*Digraph
}

func NewGraph(name string) *Graph {
	return &Graph{NewDigraph(name)}
}

func (g *Graph) AddEdge(from, to int, len uint32) {
	g.AddArc(from, to, len)
	if from != to { // avoid duplication on self-loops
		g.AddArc(to, from, len)
		// discount double direction to emulate an edge
		g.m--
	}
}

func (g *Graph) AddEdgeByName(from, to string, len uint32) {
	vi := g.VertexIndex(from)
	wi := g.VertexIndex(from)

	g.AddEdge(vi, wi, len)
}
