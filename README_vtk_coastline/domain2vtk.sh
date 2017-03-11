#!/bin/bash
ncl -n domain2vtk.ncl "dtype=0" "cres=\"i\""> dummy.vtk
nl=`wc -l dummy.vtk | awk '{print $1}'`
tail -n $((nl-5)) dummy.vtk > coastline.vtk 

ncl -n domain2vtk.ncl "dtype=1" "cres=\"i\"" > dummy.vtk
nl=`wc -l dummy.vtk | awk '{print $1}'`
tail -n $((nl-5)) dummy.vtk > borders.vtk

ncl -n domain2vtk.ncl "dtype=2" "cres=\"l\"" > dummy.vtk
nl=`wc -l dummy.vtk | awk '{print $1}'`
tail -n $((nl-5)) dummy.vtk > rivers.vtk
rm -f dummy.vtk
