#!/bin/bash

ncl -n topo2vtk.ncl > dummy.vtk
nl=`wc -l dummy.vtk | awk '{print $1}'`
tail -n $((nl-5)) dummy.vtk > topo_v2.vtk
rm -f dummy.vtk

