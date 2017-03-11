begin
  ;--- selection of dataset (0: coastline, 1: borders, 2: rivers) ---
  ;dtype = 0

  ;--- dataset resolution ----
  ;cres = "i"

  ;--- threshold to split segments (in km) --- 
  thold = 100.0

  ;--- list of files ---
  if (dtype .eq. 0) then
    lfile = systemfunc("ls -al GSHHS_shp/"+cres+"/GSHHS_"+cres+"_L*.shp | awk '{print $9}'")
    desc = "GSHHS Coastline Dataset"
  end if
  if (dtype .eq. 1) then
    lfile = systemfunc("ls -al WDBII_shp/"+cres+"/WDBII_border_"+cres+"_L*.shp | awk '{print $9}'")
    desc = "WDBII Country Borders Dataset"
  end if
  if (dtype .eq. 2) then
    lfile = systemfunc("ls -al WDBII_shp/"+cres+"/WDBII_river_"+cres+"_L*.shp | awk '{print $9}'")
    desc = "WDBII Rivers Dataset"
  end if
  nfile = dimsizes(lfile)

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

  ;--- create temporary arrays ---
  p = new((/ 500000, 4/), "double")

  ;--- loop over files ---
  k = 0
  np = 0
  do i = 0, nfile-1
    ;--- open input file ---
    shp = addfile(lfile(i), "r")

    ;--- read data from shape file ---
    segments = shp->segments
    geometry = shp->geometry
    segsDims = dimsizes(segments)
    geomDims = dimsizes(geometry)

    ;--- read global attributes ---
    geom_segIndex = shp@geom_segIndex
    geom_numSegs  = shp@geom_numSegs
    segs_xyzIndex = shp@segs_xyzIndex
    segs_numPnts  = shp@segs_numPnts
    numFeatures   = geomDims(0)

    ;--- read lat/lon values from shapefile ---
    lon = shp->x
    lat = shp->y

    ;--- loop over each feature ---
    do nf = 0, numFeatures-1
      startSegment = geometry(nf, geom_segIndex)
      numSegments  = geometry(nf, geom_numSegs)

      ;--- loop over each segment ---
      do seg = startSegment, startSegment+numSegments-1
        startPT = segments(seg, segs_xyzIndex)
        endPT = startPT + segments(seg, segs_numPnts) - 1
        lat_sub := lat(startPT:endPT)
        lon_sub := lon(startPT:endPT)

        ;--- select segments that are inside the selected region ---
        ;--- fast method: uses box defined by min/max ---
        ;indx = ind(lat_sub .ge. minlat .and. lat_sub .le. maxlat .and. \
        ;           lon_sub .ge. minlon .and. lon_sub .le. maxlon)
        ;inout = 1  

        ;--- slow method: uses exact domain boundaries, much more accurate ---
        inout = gc_inout(lat_sub, lon_sub, ybox, xbox)
        indx = ind(inout)

        ;--- print out point data
        if (all(.not. ismissing(indx))) then
          j = dimsizes(lon_sub(indx))
          p(np:np+j-1,0) = lon_sub(indx) 
          p(np:np+j-1,1) = lat_sub(indx) 
          p(np:np+j-1,2) = 0.0
          p(np:np+j-1,3) = k
          np = np+j
          k = k+1 
        end if

        delete([/ inout, indx /])
      end do 
    end do

    ;--- delete temporary arrays ---
    delete([/ segments, geometry, lat, lon /])  
  end do

  ;--- print data ---
  print("# vtk DataFile Version 3.0")
  print(""+desc)
  print("ASCII")
  print("DATASET POLYDATA")

  id = 0
  np = min(ind(ismissing(p(:,0))))
  print("POINTS "+np+" float") 
  print(p(0,0)+" "+p(0,1)+" "+p(0,2))     
  do i = 1, np-1
    ;--- calculate distance between two consecutive points ---
    dist = gc_latlon(p(i,1), p(i,0), p(i-1,1), p(i-1,0), 2, 4)
    if (dist .gt. thold) then
      id = 1
    else
      id = 0
    end if
    
    ;--- update id of line segment ---
    p(i,3) = p(i-1,3)+id

    ;--- print data --- 
    print(p(i,0)+" "+p(i,1)+" "+p(i,2))
  end do

  nl = count_unique_values(p(:,3))
  print("LINES "+nl+" "+(np+nl))
  do i = 0, nl-1
    str = ""
    indx = ind(p(:,3) .eq. i)
    k = dimsizes(indx)
    do j = 0, k-1
      str = str+indx(j)+" "
    end do
    print(k+" "+str)
    delete(indx)
  end do
end
