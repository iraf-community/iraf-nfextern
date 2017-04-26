# ACECUTOUTS -- Cutout catalog sources into a MEF file.

procedure acecutouts (image, catalog, output)

string	image = "!image"	{prompt="Input image"}
file	catalog			{prompt="Input catalog"}
file	output			{prompt="Output MEF cutout file"}
string	extname = "im"		{prompt="Root of extension name"}
int	ncpix = 101		{prompt="Number of column pixels per cutout"}
int	nlpix = 101		{prompt="Number of line pixels per cutout"}
int	blkavg = 1		{prompt="Block average factor"}
string	coords = "RA,DEC"	{prompt="Catalog image coordinate fields"}
string	wcs = "world h 1"	{prompt="Coordinate type"}
string	tiles = "GRID"		{prompt="Cutout DETSEC tiling"}
int	gap = 2			{prompt="Tiling gap (pix)"}
string	fields = ""		{prompt="List of fields to add to header"}
bool	nobp = no		{prompt="Only cutouts with no bad pixels?"}

struct	*fd, *fd1

begin
	string	temp, cat, out, im, ob, key, section, in1, out1
	string	axes, units, ctype1, ctype2, cval1, cval2
	int	i, idx, row, ncutout, ncols, nextend, ctile, ltile
	int	naxis1, naxis2, ncdet, nldet, nbpm
	int	c1, c2, l1, l2, nc, nl, loffset
	real	x, y, c, l, lx, ly, rz, dz, sdz, cdz, denom, r, d

	cache	tabpar

	# Temporary file rootname.
	temp = mktemp ("tmp$iraf")

	# Set parameters
	im = image
	cat = catalog
	out = output

	# Check catalog.
	tinfo (cat, ttout-)
	if (tinfo.nrows == 0) {
	    printf ("WARNING: Table is empty (%s)\n", cat)
	    return
	}

	# Set image from catalog if needed.
	idx = stridx ("!", im)
	if (idx > 0) {
	    key = substr (im, idx+1, 1000)
	    thselect (cat,  key, yes) | scan (im)
	}

	# Extract coordinates from catalog.
	print (coords) | translit ("STDIN", ",", " ", del-) |
	    scan (cval1, cval2, ctype1, ctype2)
	if (nscan() < 4) {
	    ctype1 = cval1
	    ctype2 = cval2
	}
	tprint (cat, prparam=no, prdata=yes, pwidth=80, plength=0, showrow=no,
	    orig_row=yes, showhdr=no, showunits=no,
	    columns=cval1//","//cval2, rows="-",
	    option="plain", align=no, sp_col="", lgroup=0, > temp//"2.crd")
	tprint (cat, prparam=no, prdata=yes, pwidth=80, plength=0, showrow=no,
	    orig_row=yes, showhdr=no, showunits=no,
	    columns=ctype1//","//ctype2, rows="-",
	    option="plain", align=no, sp_col="", lgroup=0, > temp//"3.crd")
	joinlines (temp//"2.crd", temp//"3.crd", output=temp//"1.crd",
	    delim=" ", missing="INDEF",  maxchars=161, shortest+, verbose-)
	delete (temp//"[23].crd", verify-)
	count (temp//"1.crd") | scan (ncutout)

	# Set tiling.
	key = tiles; tiles = "NONE"; ncols = INDEF
	idx = fscan (key, tiles, ncols)
	if (tiles=="IMAGE" || tiles=="GRID" || tiles=="PA" || tiles=="NONE") {
	    rename (temp//"1.crd", temp//".crd", field="all")
	    if (tiles == "GRID" && isindef(ncols))
	        ncols = sqrt (ncutout)
	    ;
	} else {
	    # Check for constants in the tile specification.
	    print (tiles) | translit ("STDIN", ",", " ", del-) |
	        scan (axes, units)
	    if (nscan() == 2) {
		ctile = 0; ltile = 0
		if (strupr(axes)!="CUTOUT" &&
		    (fscan(axes,ctile) == 0 || axes != str(ctile))) {
		    ctile = INDEF
		    tdump (cat, cdfile="", pfile="", datafile=temp//"2.crd",
			columns=axes, rows="", pwidth=-1)
		    joinlines (temp//"[12].crd", output=temp//"3.crd",
		        delim=" ", missing="INDEF",  maxchars=161, shortest+,
			verbose-)
		} else {
		    system.touch (temp//"2.crd")
		    joinlines (temp//"[12].crd", output=temp//"3.crd",
		        delim=" ", missing="INDEF",  maxchars=161, shortest-,
			verbose-)
		}
		if (strupr(units)!="CUTOUT" &&
		    (fscan(units,ltile) == 0 || units != str(ltile))) {
		    ltile = INDEF
		    tdump (cat, cdfile="", pfile="", datafile=temp//"4.crd",
			columns=units, rows="", pwidth=-1)
		    joinlines (temp//"[34].crd", output=temp//".crd",
		        delim=" ", missing="INDEF",  maxchars=161, shortest+,
			verbose-)
		} else {
		    system.touch (temp//"4.crd")
		    joinlines (temp//"[34].crd", output=temp//".crd",
		        delim=" ", missing="INDEF",  maxchars=161, shortest-,
			verbose-)
		}
		delete (temp//"[1234].crd", verify-)
		count (temp//".crd") | scan (ncutout)
	    } else {
		delete (temp//"1.crd", verify-)
		ncutout = 0
	    }
	    ncols = 4
	}

	# Check coordinates.
	if (ncutout == 0) {
	    delete (temp//"*", verify-)
	    printf ("WARNING: Fields not found in %s\n", cat)
	    printf ("  Check for empty catalog or incorrect column names\n")
	    return
	}

	# Convert WCS to logical pixels if necessary.
	axes = "1 2"; units = ""
	idx = fscan (wcs, key)
	key = substr (key, 1, 1)
	if (key != "l") {
	    if (key == "g") {
	        idx = fscan (wcs, key, rz, dz, axes)
	        if (idx < 3) {
		    delete (temp//"*", verify-)
		    error (2, "missing tangent point")
		}

		rz /= RADIAN; dz /= RADIAN
		sdz = sin (dz); cdz = cos (dz)
		fd = temp//".crd"
		while (fscan(fd,x,y,cval1,cval2,c,l) != EOF) {
		    x /= 3600 * RADIAN; y /= 3600 * RADIAN
		    denom = cdz - y * sdz
		    r = mod(atan2(x,denom)+rz, TWOPI)
		    if (r < 0)
		        r += TWOPI
		    d = atan2(sdz+y*cdz,sqrt(x*x+denom*denom))
		    r *= RADIAN; d *= RADIAN
		    if (nscan() == 6)
			printf ("%.1h %.1h %s %s %d %d\n",
			    r, d, cval1, cval2, c, l, >>temp//".tmp")
		    else
			printf ("%.1h %.1h %s %s\n",
			    r, d, cval1, cval1, >> temp//".tmp")
		}
		fd = ""; delete (temp//".crd", verify-)
		key = "w"
		if (substr(axes,1,1) == "1")
		    axes = "1 2"
		else
		    axes = "2 1"
	    } else if (key == "w") {
	        idx = fscan (wcs, key, units, axes)
		rename (temp//".crd", temp//".tmp")
		if (substr(axes,1,1) == "1") {
		    axes = "1 2"
		    if (substr(units,1,1) == "h")
		        units = "h n"
		    else
		        units = ""
		} else {
		    axes = "2 1"
		    if (substr(units,1,1) == "h")
		        units = "n h"
		    else
		        units = ""
		}
	    } else
		rename (temp//".crd", temp//".tmp")

	    wcsctran (temp//".tmp", temp//".crd", im, key, "logical",
		col=axes, units=units, formats="", min_sig=7, verbose-)
	    delete (temp//".tmp", ver-)
	}

	# Initialize output file if needed.
	nextend = 0; ncdet = 0; nldet = 0
	if (imaccess(out//"[0]")) {
	    hselect (out//"[0]", "NEXTEND", yes) | scan (nextend)
	    hselect (out//"[0]", "DETSIZE", yes) |
	        translit ("STDOUT", "[:,]", " ") | scan (idx, ncdet, idx, nldet)
	} else
	    mkglbhdr (im, out)

	# Expand optional keywords.
	files (fields, > temp//".keys")

	# Append the cutouts.
	hselect (im, "naxis1,naxis2", yes) | scan (naxis1, naxis2)
	loffset = nldet / nlpix
	fd = temp//".crd"; ncutout = 0
	for (row=1; fscan(fd,x,y,cval1,cval2,c,l)!=EOF; row+=1) {

	    # Skip coordinates outside the input image.
	    if (nint(x)<1 || nint(x)>naxis1 || nint(y)<1 || nint(y)>naxis2)
		next

	    ncutout += 1

	    # Set the grid coordinate if needed.
	    if (nscan() != 6) {
		if (tiles == "IMAGE") {
		    c = x
		    l = y
		} else if (tiles == "PA") {
		    if (ncutout == 1) {
		        rz = x
			dz = y
		    }
		    r = sqrt ((x-rz)**2 + (y-dz)**2)
		    if (r > 0) {
		        d = real(gap) / min (ncpix, nlpix) * r
			d = max (d, (ncutout - 1) * ncpix * 1.414)
			c = rz + d / r * (x - rz)
			l = dz + d / r * (y - dz)
		    } else {
			c = nint (x)
			l = nint (y)
		    }
		} else if (tiles == "GRID") {
		    if (ncutout == 1)
		        ncutout = ncutout + nextend
		    c = mod ((ncutout-1), ncols) + 1
		    l = (ncutout-1) / ncols + 1 + loffset
		} else {
		    c = INDEF
		    l = INDEF
		}
	    } else {
		if (isindef(c)) {
		    c = ctile
		    if (isindef(ctile))
		       c = ncutout
		}
		if (isindef(l)) {
		    l = ltile
		    if (isindef(ltile))
		       l = ncutout
		}
	    }

	    # Get input cutout section.
	    c1 = max (1, nint(x)-ncpix/2)
	    c2 = min (naxis1, c1+ncpix-1)
	    c1 = max (1, c2-ncpix+1)
	    l1 = max (1, nint(y)-nlpix/2)
	    l2 = min (naxis2, l1+nlpix-1)
	    l1 = max (1, l2-nlpix+1)
	    lx = x - c1 + 1
	    ly = y - l1 + 1
	    printf ("[%d:%d,%d:%d]\n", c1, c2, l1, l2) | scan (section)
	    in1 = im
	    idx = strstr (".fits", in1)
	    if (idx > 0)
		in1 = substr (in1, 1, idx-1) // substr (in1, idx+5, 999)
	    if (nobp) {
	        mimstat (in1//section, imasks="!^BPM", omasks="", fields="npix",
		    lower=INDEF, upper=INDEF, nclip=0, format=no) | scan (nbpm)
		if (nbpm > 0) {
		    ncutout -= 1
		    next
		}
	    }
	    if (blkavg > 1)
	        blkavg (in1//section, temp, blkavg, blkavg, option="average")
	    else
		imcopy (in1//section, temp, verbose=no)

	    # Set output cutout extension and possible DETSEC keyword.
	    nextend += 1
	    if (tiles == "IMAGE") {
		ncdet = max (ncdet, c2)
		nldet = max (nldet, l2)

		printf ("%s[%s%04d%04d_%03d,append,inherit]\n",
		    out, extname, nint(x), nint(y), nextend) | scan (out1)
		printf ("[%d:%d,%d:%d]\n", c1, c2, l1, l2) | scan (key)
		hedit (temp, "DETSEC", key, add+, verify-, show-, update+)
	    } else if (tiles == "PA") {
		c1 = max (1, nint(c)-ncpix/2)
		c2 = min (naxis1, c1+ncpix-1)
		c1 = max (1, c2-ncpix+1)
		l1 = max (1, nint(l)-nlpix/2)
		l2 = min (naxis2, l1+nlpix-1)
		l1 = max (1, l2-nlpix+1)
		ncdet = max (ncdet, c2)
		nldet = max (nldet, l2)

		printf ("%s[%s%04d%04d_%03d,append,inherit]\n",
		    out, extname, nint(x), nint(y), nextend) | scan (out1)
		printf ("[%d:%d,%d:%d]\n", c1, c2, l1, l2) | scan (key)
		hedit (temp, "DETSEC", key, add+, verify-, show-, update+)
	    } else if (!isindef(c) && !isindef(l)) {
		c1 = (nint(c) - 1) * (ncpix + gap) + 1
		c2 = c1 + ncpix - 1
		l1 = (nint(l) - 1) * (nlpix + gap) + 1
		l2 = l1 + nlpix - 1
		ncdet = max (ncdet, c2)
		nldet = max (nldet, l2)

		printf ("%s[%s%03d%03d_%03d,append,inherit]\n",
		    out, extname, nint(c), nint(l), nextend) | scan (out1)
		if (tiles != "NONE") {
		    printf ("%d %d\n", nint(c), nint(l)) | scan (key)
		    hedit (temp, "COTILE1", nint(c),
		        add+, verify-, show-, update+)
		    hedit (temp, "COTILE2", nint(l),
		        add+, verify-, show-, update+)
		    printf ("[%d:%d,%d:%d]\n", c1, c2, l1, l2) | scan (key)
		    hedit (temp, "DETSEC", key, add+, verify-, show-, update+)
		}
	    }

	    # Set header information.
	    in1 = substr (in1, strldx("/",in1)+1, 999)
	    if (strlen (in1//section) <= 68)
		hedit (temp, "COIMAGE", in1//section,
		    add+, verify-, show-, update+)
	    else {
		hedit (temp, "COIMAGE", in1, add+, verify-, show-, update+)
		hedit (temp, "COSEC", section, add+, verify-, show-, update+)
	    }
	    hedit (temp, "COX", lx, add+, verify-, show-, update+)
	    hedit (temp, "COY", ly, add+, verify-, show-, update+)
	    hedit (temp, "COPX", x, add+, verify-, show-, update+)
	    hedit (temp, "COPY", y, add+, verify-, show-, update+)
	    if (stridx(":",cval1)>0 || stridx(":",cval2)>0 ||
	        cval1 == "INDEF" || cval2 == "INDEF") {
		hedit (temp, "CO"//ctype1, "", add+, verify-, show-, update+)
		hedit (temp, "CO"//ctype2, "", add+, verify-, show-, update+)
	    }
	    hedit (temp, "CO"//ctype1, cval1, add+, verify-, show-, update+)
	    hedit (temp, "CO"//ctype2, cval2, add+, verify-, show-, update+)

	    fd1 = temp // ".keys"
	    while (fscan (fd1, key) != EOF) {
	        tabpar (cat, key, row)
		hedit (temp, key, tabpar.value, add+, verify-, show-, update+)
	    }
	    fd1 = ""

	    # Add to the output.
	    imcopy (temp, out1, verbose=no)
	    imdelete (temp, verify-)
	}
	fd = ""; delete (temp//".crd")

	# Update global header.
	hedit (out//"[0]", "NEXTEND", nextend, add+, verify-, show-, update+)
	if (ncdet > 0 && nldet > 0) {
	    printf ("[%d:%d,%d:%d]\n", 1, ncdet, 1, nldet) | scan (key)
	    hedit (out//"[0]", "DETSIZE", key, add+, verify-, show-, update+)
	}

	# Clean up.
	delete (temp//"*", verify-)
end
