begin
  ;--- domain file ---
  dfile = "../DOM1_DOMAIN000.nc" 

  ;--- open domain file and read coordinate data ---
  dom = addfile(dfile, "r")

  lon2d = dom->xlon
  lat2d = dom->xlat

  minlat = min(lat2d)
  maxlat = max(lat2d)
  minlon = min(lon2d)
  maxlon = max(lon2d)

  ;--- get dimension sizes ---
  jm = dimsizes(lat2d(:,0))
  im = dimsizes(lat2d(0,:))

  ;--- create domain box (w buffer zone) ---
  npoint = (im+jm)*2
  xbox = new((/ npoint /), typeof(lon2d))
  ybox = new((/ npoint /), typeof(lat2d))

  xbox(0:im-1) = lon2d(0,:)
  xbox(im:im+jm-1) = (/ lon2d(:,im-1) /)
  xbox(im+jm:im*2+jm-1) = (/ lon2d(jm-1,::-1) /)
  xbox(im*2+jm:(im+jm)*2-1) = (/ lon2d(::-1,0) /)

  ybox(0:im-1) = lat2d(0,:)
  ybox(im:im+jm-1) = (/ lat2d(:,im-1) /)
  ybox(im+jm:im*2+jm-1) = (/ lat2d(jm-1,::-1) /)
  ybox(im*2+jm:(im+jm)*2-1) = (/ lat2d(::-1,0) /)

  ;--- open input file ---
  ;nc = addfile("ETOPO1_Ice_g_gmt4_sub.grd", "r")
  nc = addfile("ETOPO2v2c_f4_sub.nc", "r")

  lon1d = nc->x
  lat1d = nc->y
  topo = nc->z

  nlat = dimsizes(lat1d)
  nlon = dimsizes(lon1d)

  ;--- create mask for domain ---
  if (.not. fileexists("mask.nc")) then
    ;--- slow method: uses exact domain boundaries, much more accurate ---
    inout = new((/ nlat, nlon /), "logical")
    do i = 0, nlon-1
      do j = 0, nlat-1 
       inout(j,i) = gc_inout(lat1d(j), lon1d(i), ybox, xbox)
      end do
    end do
    msk2d = where(inout, 1, 0)

    ;--- write to file ---
    filo = "mask.nc"
    system("/bin/rm -f "+filo)
    fout = addfile(filo, "c")

    setfileoption(fout, "DefineMode", True)
    dimNames = (/"lat", "lon"/)
    dimSizes = (/ nlat, nlon /)
    dimUnlim = (/ False, False /)
    filedimdef(fout, dimNames, dimSizes, dimUnlim)
    filevardef(fout, "mask", "integer", (/"lat", "lon"/))
    setfileoption(fout, "DefineMode", False)
    fout->mask = (/ msk2d /)
  else
    fin = addfile("mask.nc", "r")
    msk2d = fin->mask
  end if

  ;--- print data ---
  print("# vtk DataFile Version 3.0")
  print("ETOPO1 dataset")
  print("ASCII")
  print("DATASET POLYDATA")

  jmin = 0
  nlatr = 0
  do i = 0, nlon-1
    nlatr = where(nlatr .gt. sum(msk2d(:,i)), nlatr, sum(msk2d(:,i)))
    if (.not. all(msk2d(:,i) .eq. 0)) then
      jmin = min(ind(msk2d(:,i) .eq. 1))
    end if
  end do

  imin = 0
  nlonr = 0
  do j = 0, nlat-1
    nlonr = where(nlonr .gt. sum(msk2d(j,:)), nlonr, sum(msk2d(j,:)))
    if (.not. all(msk2d(j,:) .eq. 0)) then
      imin = min(ind(msk2d(j,:) .eq. 1))
    end if
  end do 

  ids = new((/ nlatr, nlonr /), "integer")
 
  id = 0
  np = sum(msk2d)
  print("POINTS "+np+" float") 
  do j = 0, nlat-1
    do i = 0, nlon-1
      if (msk2d(j,i) .eq. 1) then
        ids(j-jmin,i-imin) = id
        print(lon1d(i)+" "+lat1d(j)+" 0")
        id = id+1
      end if
    end do
  end do   

  print("POLYGONS "+((nlatr-1)*(nlonr-1))+" "+(((nlatr-1)*(nlonr-1))+((nlatr-1)*(nlonr-1))*4))

  do j = 0, nlatr-2
    do i = 0, nlonr-2
      print("4 "+ids(j,i)+" "+ids(j,i+1)+" "+ids(j+1,i+1)+" "+ids(j+1,i))
    end do
  end do

  print("POINT_DATA "+id)
  print("SCALARS Elevation float 1")
  print("LOOKUP_TABLE mytable")
  do j = 0, nlat-1
    do i = 0, nlon-1
      if (msk2d(j,i) .eq. 1) then
        print(""+topo(j,i))   
      end if
    end do
  end do  
end
