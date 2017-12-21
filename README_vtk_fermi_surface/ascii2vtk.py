import vtk
import numpy as np

# read data
energy = 4.5
d = np.loadtxt("3D_Fermi_energy_contour_4.5_VHD.txt", usecols = (0,1,2))

# create points
pts = vtk.vtkPoints()
npts = d.shape[0]
vrt = vtk.vtkCellArray()
for i in xrange(0, npts):
    id = pts.InsertNextPoint(d[i])
    vrt.InsertNextCell(1)
    vrt.InsertCellPoint(id)

pd = vtk.vtkPolyData()
pd.SetPoints(pts)
pd.SetVerts(vrt)

# add data
field = vtk.vtkFieldData()
field.AllocateArrays(1)
arr = vtk.vtkFloatArray()
arr.SetNumberOfComponents(1)
arr.SetName('dummy')
k = 0
for i in xrange(0, npts):
    arr.InsertTuple1(k, energy)
    k = k+1
field.AddArray(arr)
pd.SetFieldData(field)

# write to disk
ofile = 'data_vhd_%d.vtp' % (energy*10)
wrt = vtk.vtkXMLPolyDataWriter() 
wrt.SetFileName(ofile)
wrt.SetDataModeToAscii()
wrt.SetInputData(pd)
wrt.Write()
