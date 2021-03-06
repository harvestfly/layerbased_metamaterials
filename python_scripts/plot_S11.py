# -*- coding: utf-8 -*-

from pyx import *
import numpy as np
import sys
text.set(mode="latex")
unit.set(xscale=1)
c = canvas.canvas()
text.set(text.LatexRunner)
text.preamble(r"\usepackage{amsmath}")
unit.set(xscale=1.0)
import argparse

parser = argparse.ArgumentParser()
parser.add_argument("--infile", action = "store")
parser.add_argument("--outfile", action = "store")
parser.add_argument("--measdata", action = "store")
args = parser.parse_args()

data = np.loadtxt(args.infile, delimiter = ",")
S11_dB = 20*np.log10(abs(data[:, 1] + 1j*data[:, 2]))
Mdata = np.loadtxt(args.measdata)

g = graph.graphxy(width=8,
		x = graph.axis.lin(title = r"$f$ [GHz]"),
		y = graph.axis.lin(title = r"$20\log (S_{ij})$", max=0),
		key = graph.key.key(pos="br", dist=0.1)
                )
g.plot([graph.data.values(x = data[:, 0]/1e9, y = S11_dB, 
        title = r"$S_{11}$")], [graph.style.line([color.rgb.black])])
g.plot([graph.data.values(x = Mdata[:, 0], y = Mdata[:, 1], 
    title = r"$S^\text{meas.}_{11}$")],
       [graph.style.line([color.rgb.blue, style.linestyle.dashed])])

 

g.writePDFfile(args.outfile)
