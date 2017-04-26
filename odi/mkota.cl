# MKOTA -- Make an artificial ODI OTA file.

procedure mkota (output, exptime, ccdtype)

string	output			{prompt="Output rootname"}
real	exptime			{prompt="Exposure time"}
string	ccdtype			{prompt="CCD type"}

string	ghdr = ""		{prompt="Global header text file"}
string	chdr = ""		{prompt="Cell header text file"}
int	nota1 = 1		{prompt="Number of OTAs (+) or OTA (-)"}
int	nota2 = 1		{prompt="Number of OTAs (+) or OTA (-)"}
int	ncols=506		{prompt="Number of columns"}
int	nlines=490		{prompt="Number of lines"}
int	cellgap1=28		{prompt="Cell gap along axis 1"}
int	cellgap2=9		{prompt="Cell gap along axis 2"}
int	otagap1=100		{prompt="OTA gap along axis 1"}
int	otagap2=100		{prompt="OTA gap along axis 2"}
string	filter="V"		{prompt="Filter"}
string	datasec="[1:480,1:490]"	{prompt="Data section"}
string	trimsec="[1:480,1:490]"	{prompt="Trim section"}
string	biassec="[481:506,1:490]"	{prompt="Bias section"}
string	bias = ""		{prompt="Bias rootname"}
string	flat = ""		{prompt="Flat rootname"}

file	imdata=""		{prompt="Image data"}
int	xdither = 0		{prompt="Image data X dither offset"}
int	ydither = 0		{prompt="Image data Y dither offset"}
real	skyrate=0.		{prompt="Sky count rate"}
file	badpix=""		{prompt="Bad pixel regions"}
bool	calibrated = no		{prompt="Calibrated?"}
real	biasval=500.		{prompt="Bias value"}
real	badval=500.		{prompt="Bad pixel value"}
real	zeroval=0.		{prompt="Zero level value"}
real	darkrate=0.		{prompt="Dark count rate"}
real	zeroslope=10.		{prompt="Slope of zero level"}
real	darkslope=0.		{prompt="Slope of dark count rate"}
real	flatslope=0.3		{prompt="Flat field slope"}
real	rdnoise=5.		{prompt="Read noise"}
real	gain=1.			{prompt="Gain"}
int	nseed=1			{prompt="Random number noise seed"}
bool	dirformat=yes		{prompt="Create in directory format?"}
bool	addkwds = yes		{prompt="Add keywords not in templates?"}
bool	mkpixels=yes		{prompt="Create pixels?"}
bool	overwrite=yes		{prompt="Overwrite existing image?"}
bool	verbose=yes		{prompt="Verbose output?"}

begin
	int	no1, no2, nx, ny, ix, iy, ox, oy, c1, c2, l1, l2, seed
	real	exp, v1, v2, slope, crpix1, crpix2
	real	rand1, rand2, rand3, rand4, rand5
	string	out, ota, type, im, im1, otaname, extname, detsec, s
	struct	line, otaid
	file	randdat

	# Make list of random numbers if needed.
	randdat = "urand.dat"
	if (!access (randdat)) {
	    for (oy=0; oy<8; oy+=1) {
		for (ox=0; ox<8; ox+=1) {
		    for (iy=0; iy<8; iy+=1) {
			for (ix=0; ix<8; ix+=1) {
			    printf ("%d%d%d%d ", ox, oy, ix, iy, >> randdat)
			    urand (1, 5, ndigits=4, seed=INDEF,
			        scale=1., >> randdat)
			}
		    }
		}
	    }
	}

	# Get query parameters.
	out = output
	exp = exptime
	type = ccdtype

	# Create directory if needed.
	if (dirformat && access(out)==NO)
	    mkdir (out)

	# Remove previous images.
	if (overwrite) {
	    if (dirformat)
		delete (out//"/*", verify-)
	    else
		delete (out//"??.fits", verify-)
	}

	# Create the OTAs.
	seed = nseed; no1 = 0; no2 = 0
	if (nota1 <= 0) { no1 = -nota1; nota1 = no1 + 1 }
	if (nota2 <= 0) { no2 = -nota2; nota2 = no2 + 1 }
	for (oy=no2; oy<nota2; oy+=1) {
	    for (ox=no1; ox<nota1; ox+=1) {
	        otaid = 1100+oy*8+ox
		printf ("%s.%d%d\n", out, oy, ox) | scan (otaname)
		if (dirformat)
		    printf ("%s/%s\n", out, otaname) | scan (ota)
		else
		    printf ("%s%d%d\n", out, oy, ox) | scan (ota)
		if (imaccess (ota))
		    next
		if (verbose)
		    printf ("Creating %s ...\n", ota)

	# Create single OTA

	# Make global header.
	im = ota
	mkpattern (im, output="", 
	    title="", pixtype="short", ndim=0, header=ghdr)
	nhedit (im, "FILENAME", otaname//".fits", "Original host filename",
	    comfile="", after="", before="", update+, add=addkwds,
	    addonly-, delete-, verify-, show-)
	#nhedit (im, "FPPOS", "xy"//oy//ox, "",
	#    comfile="", after="", before="", update+, add=addkwds,
	#    addonly-, delete-, verify-, show-)
	nhedit (im, "FPPOS", "xy"//ox//oy, "",
	    comfile="", after="", before="", update+, add=addkwds,
	    addonly-, delete-, verify-, show-)
#	nhedit (im, "OTA_ID", otaid, "",
#	    comfile="", after="", before="", update+, add=addkwds,
#	    addonly-, delete-, verify-, show-)
#	nhedit (im, "CCDNAME", otaname, "OTA name",
#	    comfile="", after="", before="", update+, add=addkwds,
#	    addonly-, delete-, verify-, show-)
	nhedit (im, "CELLGAP1", cellgap1, "Cell gap between columns",
	    comfile="", after="", before="", update+, add=addkwds,
	    addonly-, delete-, verify-, show-)
	nhedit (im, "CELLGAP2", cellgap2, "Cell gap between rows",
	    comfile="", after="", before="", update+, add=addkwds,
	    addonly-, delete-, verify-, show-)
#	nhedit (im, "OTAGAP1", otagap1, "OTA gap between columns",
#	    comfile="", after="", before="", update+, add=addkwds,
#	    addonly-, delete-, verify-, show-)
#	nhedit (im, "OTAGAP2", otagap2, "OTA gap between rows",
#	    comfile="", after="", before="", update+, add=addkwds,
#	    addonly-, delete-, verify-, show-)
	nhedit (im, "EXPTIME", exp, "[s] exposure time",
	    comfile="", after="", before="", update+, add=addkwds,
	    addonly-, delete-, verify-, show-)
	nhedit (im, "EXPREQ", exp, "[s] exposure time",
	    comfile="", after="", before="", update+, add=addkwds,
	    addonly-, delete-, verify-, show-)
	if (type != "") {
	    if (type == "zero")
		nhedit (im, "OBSTYPE", "BIAS", "observation type",
		    comfile="", after="", before="", update+,
		    add=addkwds, addonly-, delete-, verify-, show-)
	    else if (type == "flat")
		nhedit (im, "OBSTYPE", "DFLAT", "observation type",
		    comfile="", after="", before="", update+,
		    add=addkwds, addonly-, delete-, verify-, show-)
	    else if (type == "object")
		nhedit (im, "OBSTYPE", "OBJECT", "observation type",
		    comfile="", after="", before="", update+,
		    add=addkwds, addonly-, delete-, verify-, show-)
	    else
		nhedit (im, "OBSTYPE", strupr(type), "observation type",
		    comfile="", after="", before="", update+,
		    add=addkwds, addonly-, delete-, verify-, show-)
	}
	if (filter != "")
	    nhedit (im, "FILTER", filter, "filter",
		comfile="", after="", before="", update+, add=addkwds,
		addonly-, delete-, verify-, show-)
	if (bias != "") {
	    printf ("%s%d%d\n", bias, oy, ox) | scan (im1)
	    nhedit (im, "BIASFIL", im1, "bias calibration file",
		comfile="", after="", before="", update+, add=addkwds,
		addonly-, delete-, verify-, show-)
	}
	if (flat != "") {
	    printf ("%s%d%d\n", flat, oy, ox) | scan (im1)
	    nhedit (im, "FLATFIL", im1, "flat field calibration file",
		comfile="", after="", before="", update+, add=addkwds,
		addonly-, delete-, verify-, show-)
	}
	nhedit (im, "XDITHER", xdither, "[pix] dither offset",
	    comfile="", after="", before="", update+, add=addkwds,
	    addonly-, delete-, verify-, show-)
	nhedit (im, "YDITHER", ydither, "[pix] dither offset",
	    comfile="", after="", before="", update+, add=addkwds,
	    addonly-, delete-, verify-, show-)

	# Make extensions.
	seed += 1
	for (iy=0; iy<8; iy+=1) {
	    for (ix=0; ix<8; ix+=1) {
	        printf ("^%d%d%d%d \n", oy, ox, ix, iy) | scan (s)
	        match (s, "urand.dat", meta+) |
		    scan (s, rand1, rand2, rand3, rand4, rand5)
		rand1 = 2 * rand1 - 1
		rand2 = 2 * rand2 - 1
		rand3 = 2 * rand3 - 1
		rand4 = 2 * rand4 - 1
		rand5 = 2 * rand5 - 1

		# Create the extension image.
		printf ("xy%d%d\n", ix, iy) | scan (extname)
		if (dirformat)
		    printf ("%s/%s\n", out, extname) | scan (im)
		else
		    im = extname
		if (mkpixels)
		    im1 = im // datasec
		else
		    im1 = im
		if (imaccess(im))
		    imdelete (im, verify-)
		s = str (ncols) // " " // str (nlines)
		if (mkpixels) {
		    mkpattern (im, output="", pattern="constant",
		        option="replace", v1=0., v2=0., size=1, title="",
			pixtype="ushort", ndim=2, ncols=ncols, nlines=nlines,
			header=chdr)
		    hselect (im//datasec, "naxis1,naxis2", yes) | scan (nx, ny)
		} else {
		    mkpattern (im, output="", pattern="constant",
		        option="replace", v1=0., v2=0., size=1, title="",
			pixtype="ushort", ndim=2, ncols=1, nlines=1,
			header=chdr)
		    # Need to not hardcode this.
		    nx = 480; ny = 494
		}

		# Add a data image.
		if (imaccess (imdata) == yes && type == "object") {
		    c1 = ox * (8 * (nx + cellgap1) + otagap1) +
		         ix * (nx + cellgap1) + 1 + xdither
		    c2 = c1 + nx - 1
		    l1 = oy * (8 * (ny + cellgap2) + otagap2) +
		         iy * (ny + cellgap2) + 1 + ydither
		    l2 = l1 + ny - 1
		    printf ("[%d:%d,%d:%d]\n", c1, c2, l1, l2 ) | scan (s)
		    imexpr ("min(a*b,16000.)", im//"tmp", imdata//s, exp,
		        verb-)
		    imcopy (im//"tmp", im1, verbose-)
		    imdelete (im//"tmp", verify-)

		    hselect (imdata, "CRPIX*", yes) | scan (crpix1, crpix2)
		}

		# Add sky.
		if (type == "flat" || type == "object") {
		    v1 = exp * skyrate
		    mkpattern (im1, output="", pattern="constant",
			option="add", v1=v1, v2=0., size=1)

		    # Add flat field response.
		    if (mkpixels && !calibrated) {
			v2 = 1. + 0.5 * rand1
			slope = min (flatslope, (v2 - 0.1) * 2.)
			v1 = v2 - slope / 2.
			v2 = v1 + slope
			mkpattern (im1, output="", pattern="slope",
			    option="multiply", v1=v1, v2=v2, size=1)
		    }
		}
		    
		# Add zero level and dark count.
		if (mkpixels && !calibrated) {
		    slope = zeroslope
		    v2 = zeroval
		    if (type != "zero") {
			slope += exp * darkslope
			v2 += exp * darkrate
		    }
		    slope *= (1 + 0.5 * rand2)
		    v2 *= (1 + 0.5 * rand3)
		    v1 = v2 - slope
		    v2 = v1 + slope
		    mkpattern (im1, output="", pattern="slope",
			option="add", v1=v1, v2=v2, size=1)
		}

		# Add bias.
		if (mkpixels && !calibrated) {
		    v1 = biasval * (1 + 0.05 * rand4)
		    mkpattern (im, output="", pattern="constant",
			option="add", v1=v1, v2=0, size=1)
		}

		# Set bad pixels.
		if (mkpixels && access (badpix)) {
		    list = badpix
		    while (fscan (list, c1, c2, l1, l2) != EOF) {
			if (nscan() != 4)
			    next
			c1 = max (1, c1)
			c2 = min (ncols, c2)
			l1 = max (1, l1)
			l2 = min (nlines, l2)
			s = "["//c1//":"//c2//","//l1//":"//l2//"]"
			mkpattern (im//s, output="", pattern="constant",
			    option="replace", v1=badval, v2=0, size=1)
		    }
		}

		# Add noise.
		if (mkpixels) {
		    v1 = rdnoise * (1 + 0.1 * rand5)
		    mknoise (im, output="", background=0., gain=gain,
		        rdnoise=v1, poisson=yes, seed=seed, cosrays="",
			ncosrays=0, energy=30000., radius=0.5, ar=1., pa=0.,
			comments=no)
		}

		# Set image header
#		nhedit (im, "CCDNAME", otaname, "OTA name",
#		    comfile="", after="", before="", update+, add=addkwds,
#		    addonly-, delete-, verify-, show-)
#		nhedit (im, "CELLGAP1", cellgap1, "Cell gap between columns",
#		    comfile="", after="", before="", update+, add=addkwds,
#		    addonly-, delete-, verify-, show-)
#		nhedit (im, "CELLGAP2", cellgap2, "Cell gap between rows",
#		    comfile="", after="", before="", update+, add=addkwds,
#		    addonly-, delete-, verify-, show-)
#		nhedit (im, "OTAGAP1", otagap1, "OTA gap between columns",
#		    comfile="", after="", before="", update+, add=addkwds,
#		    addonly-, delete-, verify-, show-)
#		nhedit (im, "OTAGAP2", otagap2, "OTA gap between rows",
#		    comfile="", after="", before="", update+, add=addkwds,
#		    addonly-, delete-, verify-, show-)
		nhedit (im, "EXPTIME", exp, "[s] exposure time",
		    comfile="", after="", before="", update+, add=addkwds,
		    addonly-, delete-, verify-, show-)
		nhedit (im, "DRKTIME", exp, "[s] exposure time",
		    comfile="", after="", before="", update+, add=addkwds,
		    addonly-, delete-, verify-, show-)
		nhedit (im, "EXPREQ", exp, "[s] exposure time",
		    comfile="", after="", before="", update+, add=addkwds,
		    addonly-, delete-, verify-, show-)
		if (filter != "")
		    nhedit (im, "FILTER", filter, "filter",
		        comfile="", after="", before="", update+, add=addkwds,
			addonly-, delete-, verify-, show-)
		nhedit (im, "AMPNAME", extname, "Cell name",
		    comfile="", after="", before="", update+, add=addkwds,
		    addonly-, delete-, verify-, show-)
		if (type != "") {
		    if (type == "zero")
			nhedit (im, "OBSTYPE", "BIAS", "observation type",
			    comfile="", after="", before="", update+,
			    add=addkwds, addonly-, delete-, verify-, show-)
		    else if (type == "flat")
			nhedit (im, "OBSTYPE", "DFLAT", "observation type",
			    comfile="", after="", before="", update+,
			    add=addkwds, addonly-, delete-, verify-, show-)
		    else if (type == "object")
			nhedit (im, "OBSTYPE", "OBJECT", "observation type",
			    comfile="", after="", before="", update+,
			    add=addkwds, addonly-, delete-, verify-, show-)
		    else
			nhedit (im, "OBSTYPE", strupr(type), "observation type",
			    comfile="", after="", before="", update+,
			    add=addkwds, addonly-, delete-, verify-, show-)
		}
		if (datasec != "")
		    nhedit (im, "DATASEC", datasec, "data section",
		        comfile="", after="", before="", update+, add=addkwds,
			addonly-, delete-, verify-, show-)
		if (trimsec != "")
		    nhedit (im, "TRIMSEC", trimsec, "trim section",
		        comfile="", after="", before="", update+, add=addkwds,
			addonly-, delete-, verify-, show-)
		if (biassec != "")
		    nhedit (im, "BIASSEC", biassec, "bias section",
		        comfile="", after="", before="", update+, add=addkwds,
			addonly-, delete-, verify-, show-)
		v1 = rdnoise * (1 + 0.1 * rand5)
		nhedit (im, "RDNOISE", v1, "[adu] readout noise",
		    comfile="", after="", before="", update+, add=addkwds,
		    addonly-, delete-, verify-, show-)
		nhedit (im, "GAIN", gain, "[e-/adu] gain",
		    comfile="", after="", before="", update+, add=addkwds,
		    addonly-, delete-, verify-, show-)

		# Do MEF stuff.

		# Since MSCDISP can only display a single OTA...
		#c1 = ox * (8 * (nx + cellgap1) + otagap1) +
		#     ix * (nx + cellgap1) + 1
		#l1 = oy * (8 * (ny + cellgap2) + otagap2) +
		#     iy * (ny + cellgap2) + 1
		c1 = ix * (nx + cellgap1) + 1
		l1 = iy * (ny + cellgap2) + 1
		c2 = c1 + nx - 1; l2 = l1 + ny - 1
		printf ("[%d:%d,%d:%d]\n", c1, c2, l1, l2 ) | scan (s)
		nhedit (im, "DETSEC", s, "detector section",
		    comfile="", after="", before="", update+, add=addkwds,
		    addonly-, delete-, verify-, show-)
		    
		c1 = ox * (8 * (nx + cellgap1) + otagap1) +
		     ix * (nx + cellgap1) + 1
		l1 = oy * (8 * (ny + cellgap2) + otagap2) +
		     iy * (ny + cellgap2) + 1
		c2 = c1 + nx - 1; l2 = l1 + ny - 1
		if (defpar("crpix1")) {
		    c1 = crpix1 - c1; l1 = crpix2 - l1
		}
		nhedit (im, "CRPIX1", c1, "",
		    comfile="", after="", before="", update+, add=addkwds,
		    addonly-, delete-, verify-, show-)
		nhedit (im, "CRPIX2", l1, "",
		    comfile="", after="", before="", update+, add=addkwds,
		    addonly-, delete-, verify-, show-)
		c1 = ix * (nx + cellgap1) + 1
		l1 = iy * (ny + cellgap2) + 1
		c2 = c1 + nx - 1; l2 = l1 + ny - 1
		printf ("[%d:%d,%d:%d]\n", c1, c2, l1, l2 ) | scan (s)
		nhedit (im, "CCDSEC", s, "detector section",
		    comfile="", after="", before="", update+, add=addkwds,
		    addonly-, delete-, verify-, show-)
		c1 = 1 - c1; l1 = 1 - l1
		nhedit (im, "LTV1", c1, "IRAF pixel to CCD transformation",
		    comfile="", after="", before="", update+, add=addkwds,
		    addonly-, delete-, verify-, show-)
		nhedit (im, "LTV2", l1, "IRAF pixel to CCD transformation",
		    comfile="", after="", before="", update+, add=addkwds,
		    addonly-, delete-, verify-, show-)
		nhedit (im, "LTM1_1", 1., "IRAF pixel to CCD transformation",
		    comfile="", after="", before="", update+, add=addkwds,
		    addonly-, delete-, verify-, show-)
		nhedit (im, "LTM2_2", 1., "IRAF pixel to CCD transformation",
		    comfile="", after="", before="", update+, add=addkwds,
		    addonly-, delete-, verify-, show-)

		imcopy (im, ota//"["//extname//",append,inherit]", verbose-)
		imdelete (im)
	    }
	}

	    }
	}

end
