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
	graphMark    string = "* GraphBase"
	verticesMark        = "* Vertices"
	arcsMark            = "* Arcs"

	// Mark context of sections in the graph description.
	graphSection    = 0
	verticesSection = 1
	arcsSection     = 2
)

func check(err error) {
	if err != nil {
		log.Fatal(err)
	}
}

func lookupArc(label string, arcs *[]Arc) *Arc {
	if label == "0" {
		return nil
	}
	i := strconv.Atoi(strings.TrimPrefix("A", label))
	return &arcs[i]
}

func lookupArc(label string, verts *[]Vertex) *Vertex {
	i := strconv.Atoi(strings.TrimPrefix("V", label))
	return &verts[i]
}

func ReadGB(filepath string) *g.Graph {
	// Line number and counters for vertices and arcs
	var lineno, nV, nA = 0, 0, 0
	// number of vertices and arcs
	var n, m uint = 0, 0
	// mark the attributes used in the graph
	var utilTypes string
	// current line in the buffer
	var line string
	// current context
	var curSection int = 0 // Graph description starts at comments.
	// Graph to be returned
	var graph g.Graph
	// array of arcs to feed the adjacency list
	var arcs []g.Arc

	file, err := os.Open(filepath)
	check(err)
	defer file.Close()

	graph := g.NewGraph("graph")

	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		lineno++
		line = scanner.Text()

		if strings.HasPrefix(line, graphMark) {
			curSection = graphSection
			fmt.Sscanf(line, "GraphBase graph (util_types %s,%dV,%dA)",
				&utilTypes, &n, &m)

			if n == 0 || m == 0 {
				log.Fatalf("wrong number of vertices or arcs at line\n", lineno)
			}
			graph = g.NewGraph(n)
			arcs = make([]Arc, m)

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
			v := graph.Vertices[nV]
			v.name = fields[0]
			v.arcs = lookupArc(fields[1], &arcs)

			nV++
		} else if curSection == arcsSection {
			// e.g. (ignore all spaces)
			// tip, nextArc, length, some_arc_attribute
			// V0,  A2,      3,      V1
			fields := strings.Split(line, ",")
			a := &arcs[nA]
			a.tip = lookupVertex(fields[0], &graph.Vertices)
			a.next = lookupArc(fields[1], &arcs)
			a.len = strconv.Atoi(fields[2])

			nA++
		} else {
			fmt.Println(line)
		}
	}

	check(scanner.Err())

	return &graph
}