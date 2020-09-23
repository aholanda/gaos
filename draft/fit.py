#!/usr/bin/env python

import math
import numpy as np
import sys

# This program fits xy dataset using Least Squares Fitting--Exponential
# source: http://mathworld.wolfram.com/LeastSquaresFittingExponential.html

def exp_fit(xs, ys):
        sum_y = 0.0
        sum_xy = 0.0
        sum_x2y = 0.0
        sum_ylny = 0.0
        sum_xylny = 0.0
        
        for y in ys:
                sum_y += float(y)

        for i in range(len(xs)):
                sum_xy += float(xs[i])*float(ys[i])

        for i in range(len(xs)):
                print xs[i],ys[i]
                sum_x2y += float(xs[i])**2  * float(ys[i])
                
        for i in range(len(ys)):
                sum_ylny = float(ys[i])*np.log(float(ys[i]))
                
        for i in range(len(xs)):
                sum_xylny += int(xs[i])*float(ys[i])*np.log(float(ys[i]))


        a = (sum_x2y*sum_ylny - sum_xy*sum_xylny) / (sum_y*sum_x2y - math.pow(sum_xy, 2))

        b = (sum_y*sum_xylny - sum_xy*sum_ylny) / (sum_y*sum_x2y - math.pow(sum_xy, 2))

        return (a,b)
        
if __name__ == '__main__':
        xs = []
        ys = []
        if len(sys.argv) == 2:
                f = open(sys.argv[1], 'r')
                for ln in f.readlines():
                        (x, y) = ln.rstrip().split('\t')
                        xs.append(x)
                        ys.append(y)
                f.close()

                (a,b) = exp_fit(xs, ys)

                print 'a=', a, 'b=', b
        else:
                print 'usage: ' + sys.argv[0] + '<filename>'
                print '''\t<filename> contains x values at the first column and 
                y values at the second delimited by tab.'''
                        
