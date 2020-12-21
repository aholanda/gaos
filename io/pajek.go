// Copyright 2020 University of São Paulo/Brazil.
// All rights reserved.
// Use of this source code is governed by a MIT-style
// license that can be found in the LICENSE file.

package io

import (
	"bufio"
	"fmt"
	"io"
	"log"
	"os"
	"strconv"
	"strings"

	g "github.com/aholanda/graphs"
)

// Description of Pajek format
// http://vlado.fmf.uni-lj.si/pub/networks/pajek/doc/draweps.htm

const (
	// pajekSectionMark marks the start of a section,
	// after the symbol the section name is written.
	pajekSectionMark byte = '*'

	//// Sections in the file ////
	// pajekNetworkSectionEnum acts as a state value
	// to indicate the file pointer is in the network
	// line that contains the graph name.
	// The value is used after the label "*network"
	// is found and it's optional.
	pajekNetworkSectionEnum int = 0
	// pajekVerticesSectionEnum acts as a state value
	// to indicate the file pointer is in the vertices'
	// section. The value is used after the label "*vertices"
	// is found.
	pajekVerticesSectionEnum int = 1
	// pajekArcsSectionEnum acts as a state value
	// to indicate the file pointer is in the arcs'
	// section. The value is used after the label "*arcs"
	// is found.
	pajekArcsSectionEnum int = 2
	// TODO: edges' and edgelist section

	// pajekSeparator separates graph elements like
	// vertices and their names and attibutes,
	// arcs' or edges' ids and their attributes.
	pajekSeparator string = " "

	// PajekFormatExtension is used as suffix for
	// files with graph description in the Pajek
	// format.
	PajekFormatExtension string = ".net"
)

// pajekSectionNames array links the labels to each section
// terminated with "SectionEnum".
var pajekSectionNames = [...]string{"network", "vertices", "arcs"}

// WritePajek writes the graph elements in a file
// named filename using the Pajek format to describe
// the graph.
func WritePajek(digraph *g.Digraph, filename string) {
	file, err := os.Create(filename)
	if err != nil {
		log.Fatalf("failed with error: %v", err)
	}

	// Vertex section
	fmt.Fprintf(file, "%s%s %d\n",
		string(pajekSectionMark),
		pajekSectionNames[pajekVerticesSectionEnum],
		digraph.V())

	vIter := g.NewVertexIterator(digraph)
	for vIter.HasNext() {
		v := vIter.Value()

		fmt.Fprintf(file, "%d%s\"%s\"\n", v+1, pajekSeparator,
			digraph.VertexName(v))
	}

	// arcs section
	fmt.Fprintf(file, "%sarcs\n", string(pajekSectionMark))
	vIter = g.NewVertexIterator(digraph)
	for i := 0; vIter.HasNext(); i++ {
		v := vIter.Value()

		aIter := g.NewArcIterator(digraph, v)
		for aIter.HasNext() {
			w := aIter.Value()
			fmt.Fprintf(file, "%d%v%d\n", v+1, pajekSeparator, w+1)
		}
	}
}

// ReadPajek reads the graph description in a file
// named filename in the Pajek format to fill and
// returns a data structure with these elements.
func ReadPajek(filename string) *g.Digraph {
	var line string
	var lineno int          // Line number
	var curSection int = -1 // Mark current section
	var d *g.Digraph
	var graphID string

	file, err := os.Open(filename)
	if err != nil {
		log.Fatalf("failed with error: %v", err)
	}
	defer file.Close()

	// Start reading from the file with a reader.
	reader := bufio.NewReader(file)
	for {
		lineno++
		line, err = reader.ReadString('\n')
		if err == io.EOF {
			break
		}
		// Remove new line
		line = strings.TrimSuffix(line, "\n")

		if line[0] == pajekSectionMark {
			tks := strings.Split(line[1:], pajekSeparator)
			if strings.ToLower(tks[0]) == pajekSectionNames[pajekNetworkSectionEnum] {
				curSection = pajekNetworkSectionEnum
				graphID = tks[1]
				continue
			} else if strings.ToLower(tks[0]) == pajekSectionNames[pajekVerticesSectionEnum] {
				curSection = pajekVerticesSectionEnum
				n, err := strconv.Atoi(tks[1])
				if err != nil {
					log.Fatalf("failed to get the number of vertices at line %d: %v",
						lineno, err)
				}
				d = g.NewDigraph(n)
				d.NameIt(graphID)
				continue
			} else if strings.ToLower(tks[0]) == pajekSectionNames[pajekArcsSectionEnum] {
				curSection = pajekArcsSectionEnum
				continue
			} else {
				log.Fatalf("unknown section name at line %d: \"%s\"", lineno, tks[0])
			}
		}

		// Process line with a vertex
		if curSection == pajekVerticesSectionEnum {
			tks := strings.Split(line, pajekSeparator)
			v, err := strconv.Atoi(tks[0])
			if err != nil {
				log.Fatalf("failed to read the vertex index at line %d: %v ",
					lineno, err)
			}

			if tks[1] != "" {
				// Remove double quotes
				vname := strings.TrimPrefix(tks[1], "\"")
				vname = strings.TrimSuffix(vname, "\"")
				// Name the vertex
				d.NameVertex(g.VertexID(v-1), vname)
			} else {
				log.Fatalf("failed to read the vertex name at line %d ",
					lineno)
			}
		}

		// Process line with an arc
		if curSection == pajekArcsSectionEnum {
			tks := strings.Split(line, pajekSeparator)
			v, err := strconv.Atoi(tks[0])
			if err != nil {
				log.Fatalf("failed to read the vertex source index at line %d: %v ",
					lineno, err)
			}

			w, err := strconv.Atoi(tks[1])
			if err != nil {
				log.Fatalf("failed to read the vertex destination index at line %d: %v ",
					lineno, err)
			}
			d.AddArc(g.VertexID(v-1), g.VertexID(w-1))
		}

		if err != nil {
			break
		}
	}
	return d
}
