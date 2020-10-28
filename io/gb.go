package io

import (
	"bufio"
	"fmt"
	"log"
	"os"
	"strconv"
	"strings"

	g "github.com/aholanda/graphs"
)

const (
	graphMark    string = "* GraphBase graph"
	verticesMark        = "* Vertices"
	arcsMark            = "* Arcs"

	// Mark context of sections in the graph description.
	graphSection    = 0
	verticesSection = 1
	arcsSection     = 2

	// Prefix used for arcs and vertices
	arcLabelPrefix    = "A"
	vertexLabelPrefix = "V"

	// File name extension
	fileNameExtension = ".gb"

	// empty util types
	nilUtilTypes = "ZZZZZZZZZZZZZZ"

	// Field separator
	fieldSep string = ","
)

func check(err error, filename string, lineno int) {
	if err != nil {
		log.Fatalf("%v at %s:%d\n", err, filename, lineno)
	}
}

func quote(name string) string {
	return "\"" + name + "\""
}

func unquote(name string) string {
	name = strings.TrimPrefix(name, "\"")
	return strings.TrimSuffix(name, "\"")
}

func removePrefix(str, prefix string) string {
	newStr := strings.TrimPrefix(str, prefix)

	return newStr
}

func lookupArc(label string, arcs []g.Arc) (*g.Arc, error) {
	if label == "0" {
		return nil, nil
	}
	i, err := strconv.Atoi(removePrefix(label, "A"))

	return &arcs[i], err
}

func lookupVertex(label string, verts []g.Vertex) (*g.Vertex, error) {
	i, err := strconv.Atoi(removePrefix(label, "V"))
	return &verts[i], err
}

func ReadGB(filepath string) *g.Digraph {
	// Line number and counters for vertices and arcs
	var lineno, nV, nA = 0, 0, 0
	// number of vertices and arcs
	var n, m int = 0, 0
	// mark the attributes used in the graph
	var utilTypes string
	// current line in the buffer
	var line string
	// current context
	var curSection int = 0 // Graph description starts at comments.
	// Graph to be returned
	var graph *g.Digraph
	// array of arcs to feed the adjacency list
	var arcs []g.Arc

	file, err := os.Open(filepath)
	check(err, filepath, -1)
	defer file.Close()

	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		lineno++
		line = scanner.Text()

		if strings.HasPrefix(line, graphMark) {
			curSection = graphSection
			fmt.Sscanf(line, graphMark+" (util_types %14s,%dV,%dA)",
				&utilTypes, &n, &m)

			if n < 1 {
				log.Fatalf("wrong number of vertices=%d at line %d\n",
					n, lineno)
			}

			if m < 1 {
				log.Fatalf("wrong number of arcs=%d at line %d\n",
					m, lineno)
			}

			graph = g.NewDigraph(n)
			arcs = make([]g.Arc, m)

			continue
		}

		if strings.HasPrefix(line, verticesMark) {
			curSection = verticesSection
			continue
		}

		if strings.HasPrefix(line, arcsMark) {
			curSection = arcsSection
			continue
		}

		if curSection == verticesSection {
			fields := strings.Split(line, ",")
			v := &graph.Vertices[nV]
			v.Name = unquote(fields[0])
			v.Arcs, err = lookupArc(fields[1], arcs)
			check(err, filepath, lineno)

			nV++
		} else if curSection == arcsSection {
			// e.g. (ignore all spaces)
			// tip, nextArc, length, some_arc_attribute
			// V0,  A2,      3,      V1
			fields := strings.Split(line, ",")
			a := &arcs[nA]
			a.Tip, err = lookupVertex(fields[0], graph.Vertices)
			check(err, filepath, lineno)
			a.Next, err = lookupArc(fields[1], arcs)
			check(err, filepath, lineno)
			a.Len, err = strconv.Atoi(fields[2])
			check(err, filepath, lineno)

			nA++
		} else {
			fmt.Println(line)
		}
	}

	check(scanner.Err(), filepath, lineno)

	return graph
}

// TODO: generalize argument for writegb
func WriteGB(graph *g.Digraph) {
	// number of vertices
	var n int = graph.Order()
	// number of arcs
	var m int = graph.Size()
	// counter for the arcs indices
	var mm int = 0
	// Line number
	var lineno int = 0
	// Output file name
	var filename string = graph.Name + fileNameExtension
	// Map vertex pointer and its index
	var vertexToIndex map[*g.Vertex]int = make(map[*g.Vertex]int, n)
	// Index arc pointer
	var arcs []*g.Arc = make([]*g.Arc, m)
	// Map arc pointer and its index
	var arcToIndex map[*g.Arc]int = make(map[*g.Arc]int, m)
	// arc label
	var arcLabel string = arcLabelPrefix

	file, err := os.Create(filename)
	check(err, filename, -1)

	defer file.Close()

	firstline := fmt.Sprintf("%s (util_types %s,%dV,%dA)\n",
		graphMark, nilUtilTypes, graph.Order(), graph.Size())
	_, err = file.WriteString(firstline)
	lineno++
	check(err, filename, lineno)

	// Mark the begin of "* Vertices" section
	_, err = file.WriteString(verticesMark + "\n")
	lineno++
	check(err, filename, lineno)

	// list the vertices and their attributes
	for i := 0; i < n; i++ {
		v := &graph.Vertices[i]

		vertexToIndex[v] = i

		line := quote(v.Name) + fieldSep
		if v.Arcs == nil {
			arcLabel = "0"
		} else {
			arcs[mm] = v.Arcs
			arcToIndex[v.Arcs] = mm
			arcLabel = arcLabelPrefix + strconv.Itoa(mm)
			mm++
			// Capture the rest os arcs in the adjacency list
			for a := v.Arcs.Next; a != nil; a = a.Next {
				arcs[mm] = a
				arcToIndex[a] = mm
				mm++
			}
		}
		line += arcLabel
		_, err = file.WriteString(line + "\n")
		lineno++
		check(err, filename, lineno)
	}

	// Mark the begin of "* Arcs" section
	_, err = file.WriteString(arcsMark + "\n")
	lineno++
	check(err, filename, lineno)

	// List the arcs and their attributes;
	// each line nA corresponds to the arc index.
	for i := 0; i < mm; i++ {
		a := arcs[i]
		vi := strconv.Itoa(vertexToIndex[a.Tip])
		// next arc index
		nextAi := "0"
		if a.Next != nil {
			nextAi = "A" + strconv.Itoa(arcToIndex[a.Next])
		}
		line := "V" + vi + fieldSep + nextAi +
			fieldSep + strconv.Itoa(a.Len)

		_, err = file.WriteString(line + "\n")
		lineno++
		check(err, filename, lineno)
	}
}
