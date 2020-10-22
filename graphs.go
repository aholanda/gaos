package graphs

// Go keeps compatibility of 64-bit types when
// compiled in 32-bit architecture.
// https://groups.google.com/g/golang-nuts/c/mtnn-01Dh_I

type Vertex struct {
	name string
	arcs *Arc // Head of adjacency list of arcs
}

func (v *Vertex) Arcs() *Arc {
	return v.arcs
}

type Arc struct {
	tip  *Vertex // Vertex pointed by this Arc
	next *Arc    // Next arc in the adjacency list
	len  uint    // Arc length
}

func (d *Digraph) NewArc(v *Vertex, length uint) *Arc {
	var a Arc = Arc{v, nil, length}
	d.arcs = append(d.arcs, a)
	d.m++

	return &a
}

func (a *Arc) Tip() *Vertex {
	return a.tip
}

func (a *Arc) Length() uint {
	return a.len
}

type Digraph struct {
	name         string             // name of the graph
	vertices     []Vertex           // array of vertices
	arcs         []Arc              // array of arcs
	n            uint               // number of vertices
	m            uint               // number of arcs
	nameToVertex map[string]*Vertex // names for vertices (optional)
}

func NewDigraph(name string) *Digraph {
	return &Digraph{
		name,
		make([]Vertex, 0),
		make([]Arc, 0),
		0,
		0,
		make(map[string]*Vertex, 0),
	}
}

func (d *Digraph) Vertex(name string) *Vertex {
	if v, ok := d.nameToVertex[name]; ok {
		return v
	}

	v := &d.vertices[d.n]
	v.name = name
	v.arcs = nil
	d.nameToVertex[name] = v

	return v
}

func (d *Digraph) Vertices() []Vertex {
	return d.vertices
}

func (d *Digraph) Order() uint {
	return d.n
}

func (d *Digraph) Size() uint {
	return d.m
}

func (d *Digraph) AddArc(from, to string, length uint) {
	var a, b *Arc
	var v, w *Vertex

	v = d.Vertex(from)
	w = d.Vertex(to)
	a = d.NewArc(w, length)

	b = v.arcs
	v.arcs = a
	a.next = b
}

func Reverse(d *Digraph) {
	rev := NewDigraph(d.name)
	for _, v := range d.Vertices() {
		for a := v.arcs; a != nil; a = a.next {
			w := a.Tip()
			rev.AddArc(w.name, v.name, a.len)
		}
	}
}

type Graph struct {
	*Digraph
}

func NewGraph(name string) *Graph {
	return &Graph{NewDigraph(name)}
}

func (g *Graph) AddEdge(from, to string, len uint) {
	g.AddArc(from, to, len)
	if from != to { // avoid duplication on self-loops
		g.AddArc(to, from, len)
		// discount double direction to emulate an edge
		g.m--
	}
}
