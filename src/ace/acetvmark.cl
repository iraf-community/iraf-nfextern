# ACETVMARK -- Mark list of objects in a display.
#
# The mosaic geometry file is that produced by the last MSCDISPLAY.

procedure acetvmark (image)

file	image		{prompt="Image"}
int	frame = 1	{prompt="Display frame"}
bool	erase = yes	{prompt="Erase frame?"}
string	catalog = "!catalog"		{prompt="Catalog"}
string	fields = "ra,dec" {prompt="Fields for RA/DEC or ID for mask overlay"}
string	catfilter = ""	{prompt="Catalog filter expression"}
string	wcs = "world"	{prompt="Coordinate type (logical|physical|world)",
			 enum="logical|physical|world"}
string	extnames = ""	{prompt="Extension name pattern"}
string	mark = "circle"	{prompt="Mark type",
			 enum="objmask|point|circle|rectangle|plus|cross|none"}
string	radii = "10"	{prompt="Radii of concentric circles"}
string	lengths = "0"	{prompt="Lengths and width of concentric rectangles"}
string	font = "raster"	{prompt="Default font"}
int	color = 205	{prompt="Gray level of marks to be drawn"}
bool	label = no	{prompt="Label the marked coordinates"}
int	nxoffset = 0	{prompt="X offset in display pixels of number"}
int	nyoffset = 0	{prompt="Y offset in display pixels of number"}
int	pointsize = 3	{prompt="Size of mark type point in display pixels"}
int	txsize = 1	{prompt="Size of text and numbers in font units\n"}

string	zcombine="auto"	{prompt="Tile zscaling method",
			enum="none|auto|minmax|average|median"}
bool	zscale = yes	{prompt="Use zscaling method?"}
real	z1 = 0.		{prompt="Minimum greylevel to display"}
real	z2 = 1000.	{prompt="Maximum greylevel to display"}
int	xgap = 0.	{prompt="Minimum tile gap in X"}
int	ygap = 0.	{prompt="Minimum tile gap in Y"}

struct	*fd

begin
	string	err = ""
	string	im, im1, cat, cat1, key, obm, temp
	int	frm, idx

	# Temporary files.
	temp = mktemp ("tmp$iraf")

	# Query parameters
	im = image
	frm = frame
	cat = catalog
	obm = "!objmask"

	# Expand possible MEF image.
	mscextensions (im, output="file", index="0-",
	    extname=extname, extver="", lindex=no, lname=yes,
	    lver=no, ikparams="", > temp//".extns")

	# Filter to temporary catalog or object mask.
	if (catfilter != "") {
	    if (mark == "objmask") {
		cat = ""
	        obm = temp // "_obm"
		hselect ("@"//temp//".extns", "$I,objmask", yes,
		    >> temp//".list")
	    } else {
		cat = temp // "_cat"
		obm = ""
		hselect ("@"//temp//".extns", "$I,catalog", yes,
		    >> temp//".list")
	    }
	    acefilter (im, icat=catalog, ocat=cat, iobjmask=obm,
		catfilter=catfilter, nmaxrec=INDEF, omtype="all",
		extnames=extnames, catomid=fields,
		update+, logfile="", verbose=0)

	    cat = "!catalog"
	    obm = "!objmask"
	}

	# Display object mask if that is selected.
	if (mark == "objmask") {
	    acedisplay (im, frm, bpmask="", overlay=obm, erase=erase,
		zscale=zscale, zrange=no, zcombine=zcombine, z1=z1, z2=z2,
		extname=extnames, xgap=xgap, ygap=ygap)

	    # Reset objmask keyword.
	    if (catfilter != "") {
		fd = temp//".list"
		while (fscan (fd, im1, obm) != EOF)
		    hedit (im1, "objmask", obm, update+, verify-, show-)
		fd = ""
	    }

	    delete (temp//"*", verify-)
	    return
	}

	# Extract coordinates from catalog.
	idx = stridx ("!", cat)
	if (idx > 0) {
	    key = substr (cat, idx+1, 1000)
	    fd = temp//".extns"
	    while (fscan (fd, im1) != EOF) {
		cat1 = ""; hselect (im1, key, yes) | scan (cat1)
		tdump (cat1, cdfile="", pfile="", datafile="STDOUT",
		    columns=fields, rows="", pwidth=-1, >> temp//"1.crd")
	    }
	    fd = ""
	} else {
	    fd = temp//".extns"
	    while (fscan (fd, im1) != EOF) {
		idx = stridx ("[", im1)
		if (idx > 0) {
		    cat1 = cat // substr (im1, idx, 1000)
		    tdump (cat1, cdfile="", pfile="", datafile="STDOUT",
			columns=fields, rows="", pwidth=-1, >> temp//"1.crd")
		} else
		    tdump (cat, cdfile="", pfile="", datafile="STDOUT",
			columns=fields, rows="", pwidth=-1, >> temp//"1.crd")
	    }
	    fd = ""
	}
	if (access (temp//"1.crd"))
	    match ("INDEF", temp//"1.crd", stop+, > temp//".crd")
	else
	    touch (temp//".crd")

	# Display image
	if (erase)
	    acedisplay (im, frm, bpmask="", overlay="", erase=erase,
		zscale=zscale, zrange=no, zcombine=zcombine, z1=z1, z2=z2,
		extname=extnames, xgap=xgap, ygap=ygap)


	# Mark display.
	idx = 0; count (temp//".crd") | scan (idx)
	if (idx > 0) {
	    mscztvmark (temp//".crd", frm, "uparm$mscdisp"//frm, output="",
		fields="1,2,3", wcs=wcs, mark=mark, radii=radii,
		lengths=lengths, font=font, color=color, label=label,
		nxoffset=nxoffset, nyoffset=nyoffset, pointsize=pointsize,
		txsize=txsize)
	} else
	    err = "Coordinates not found (check column names or selection)"

	# Reset catalog keyword.
	if (catfilter != "") {
	    fd = temp//".list"
	    while (fscan (fd, im1, cat1) != EOF)
		hedit (im1, "catalog", cat1, update+, verify-, show-)
	    fd = ""
	}

	# Delete all temporary files.
	delete (temp//"*", verify-)

	# Act on error.
	if (err != "")
	    #error (1, err)
	    printf ("WARNING: %s\n", err)
end
