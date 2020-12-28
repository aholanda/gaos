// Copyright 2020 University of São Paulo/Brazil.
// All rights reserved.
// Use of this source code is governed by a MIT-style
// license that can be found in the LICENSE file.

package graphs

import (
	"log"
	"reflect"
)

// ComputingPerformer is an interface to use with
// structures that must run the method Compute()
// to set their elements with the desired states.
type ComputingPerformer interface {
	hadRunCompute() bool
	Compute()
}

// ComputeWasCalled checks if the Compute() method
// was called.
func ComputeWasCalled(cp ComputingPerformer) {
	if cp.hadRunCompute() == false {
		t := reflect.TypeOf(3)
		log.Fatalf("Please run Compute() method after creating the %s structure",
			t.String())
	}

}
