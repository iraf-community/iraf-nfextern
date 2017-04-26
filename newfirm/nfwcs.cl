# NFWCS -- NEWFIRM WCS task.
#
# This task derives WCS solutions using source catalogs.

procedure nfwcs (input)

string	input			{prompt="List of NEWFIRM exposures"}
string	sky = ""		{prompt="Optional sky exposure"}
string	outroot = ""		{prompt="Output rootname (+=input rootname)"}
file	coords = "!nftwomass $I $C"	{prompt="Astrometric reference catalog"}
string	cdef = "c1,c2,c3"	{prompt="Ref fields for ra, dec, and mag"}
real	search = 300.		{prompt="Search radius (arcsec)"}
real	raoffset = 0.		{prompt="RA offset (arcsec)"}
real	decoffset = 0.		{prompt="DEC offset (arcsec)"}
int	ngrid = 100		{prompt="Refit grid"}
bool	reset = no		{prompt="Reset offsets between input?"}
string	logfile = ""		{prompt="Logfile"}
bool	verbose = yes		{prompt="Verbose?"}

struct	*fd

begin
	int	i, j
	file	root, in, incrds, crds, cat, mcat, wcsdb, logfn
	file	temp, temp1, temp2, temp3, temp4
	string	cmd, sub
	struct	str

	cache acematch, acegeomap

	# Set temporary filenames.
	temp = mktemp ("nfwcs")
	temp1 = temp // "1.tmp"
	temp2 = temp // "2.tmp"
	temp3 = temp // "3.tmp"
	temp4 = temp // "4.tmp"

	files (input, sort-, > temp2); files (coords, sort-, > temp3)
	joinlines (temp2, temp3, output=temp1, delim=" ", missing="",
	    maxchars=4096, shortest-, verbose-)
	delete (temp2, verify-); delete (temp3, verify-)

	fd = temp1; incrds = ""
	for (j = 0; fscan (fd, in, incrds) != EOF; j += 1) {

	    # Check input and output.
	    if (imaccess(in//"[0]") == NO) {
	        printf ("Warning: image not found (%s)\n", in)
	        next
	    }
	    if (incrds == "") {
	        printf ("Warning: no coordinates specified for (%s)\n", in)
	        next
	    }

	    # Set input root.
	    i = strlstr (".fits", in)
	    if (i > 0)
	        in = substr (in, 1, i-1)

	    # Set output root.
	    if (outroot == "+")
	        root = in // "_"
	    else if (outroot == "")
	        root = temp // "_"
	    else if (j == 0)
		root = outroot // "_"
	    else
	        printf ("%s%03d_\n", outroot, j) | scan (root)

	    # Delete any temp files.
	    delete (temp//"[234_]*", verify-)

	    # Set output files.
	    logfn = logfile
	    if (logfn == "")
		logfn = root + "log.txt"
	    cat = root + "cat.fits"
	    mcat = root + "mcat.fits"
	    wcsdb = root + "wcsdb.txt"
	    if (!access(cat))
	        delete (mcat, verify-, >& "dev$null")

	    # Get the reference coordinates if necessary.
	    i = stridx ("!", incrds)
	    if (i > 0) {
	        crds = root + "coords.txt"
		if (!access(crds)) {
		    cmd = ""
		    str = substr (coords, i+1, 999)
		    for (i=stridx("$",str); i>0; i=stridx("$",str)) {
			cmd += substr (str, 1, i-1)
			sub = substr (str, i, i+1)
			if (sub == "$I")
			    cmd += in
			else if (sub == "$C")
			    cmd += crds
			else
			    cmd += sub
			str = substr (str, i+2, 999)
		    }
		    cmd += str
		    if (strstr("nftwomass", cmd) > 0 &&
		        strstr("search", cmd) == 0)
			cmd += " search=" + str(search)

		    if (access (crds))
			delete (crds, verify-)
		    if (verbose)
		        print (cmd) | tee (logfn, append+)
		    else
		        print (cmd, >> logfn)
		    iferr {
			print (cmd) | cl
		    } then
		    	;
		}
	    } else
	        crds = incrds

	    if (!access(crds)) {
		printf ("Warning: Could not get reference coordinates for %s\n", in)
		next
	    }

	    # Create the catalog.
	    if (!access(cat)) {
	        if (verbose)
		    i = 1
		else
		    i = 0
		if (sky == "")
		    acecatalog (in, masks="!BPM", exps="", gains="",
			spatialvar="", extnames="", logfiles=logfn,
			verbose=i, catalogs=cat,
			catdefs="nfdat$acematch.def", catfilter="",
			order="", nmaxrec=INDEF, magzero="INDEF",
			gwtsig=INDEF, gwtnsig=INDEF, objmasks="",
			omtype="all", skies="", sigmas="", fitstep=100,
			fitblk1d=10, fithclip=2., fitlclip=3., fitxorder=1,
			fityorder=1, fitxterms="half", blkstep=1,
			blksize=-10, blknsubblks=2, hdetect=yes,
			ldetect=no, updatesky=yes, bpdetect="1-100",
			bpflag="1-100", convolve="", hsigma=5., lsigma=10.,
			neighbors="8", minpix=8, sigavg=4., sigmax=4.,
			bpval=INDEF, splitstep=0., splitmax=INDEF,
			splitthresh=5., sminpix=8, ssigavg=10., ssigmax=5.,
			ngrow=0, agrow=0.)
		else
		    acediff (in, sky, masks="!BPM", exps="", gains="",
			scales="", extnames="", logfiles=logfn,
			verbose=i, rmasks="!BPM", rexps="",
			rgains="", rscales="", roffset="", catalogs=cat,
			catdefs="nfdat$acematch.def", catfilter="",
			order="", nmaxrec=INDEF, magzero="INDEF",
			gwtsig=INDEF, gwtnsig=INDEF, objmasks="",
			omtype="all", skies="", sigmas="", rskies="",
			rsigmas="", fitstep=100, fitblk1d=10,
			fithclip=2., fitlclip=3., fitxorder=1,
			fityorder=1, fitxterms="half", blkstep=1,
			blksize=-10, blknsubblks=2, hdetect=yes,
			ldetect=no, updatesky=yes, bpdetect="1-100",
			bpflag="1-100", convolve="", hsigma=5.,
			lsigma=10., neighbors="8", minpix=8, sigavg=4.,
			sigmax=4., bpval=INDEF, rfrac=0.5, splitstep=0.,
			splitmax=INDEF, splitthresh=5., sminpix=8,
			ssigavg=10., ssigmax=5., ngrow=0, agrow=0.)
	    }

	    # Match the catalogs.
	    if (access(mcat) == NO) {
		acematch.xi = raoffset; acematch.eta = decoffset
		acematch.theta = 0.
		acematch (cat, crds, imcatdef="", imwcs="", imfilter="",
		    refcatdef="="//cdef, reffilter="", matchcats=mcat,
		    all=no, search=search, rsearch=0.5, rstep=0.1,
		    histimages="", nim=400, nref=200, nmin=50., fwhm=1.,
		    match=2., fracmatch=0.5, erraction="warn",
		    logfiles=logfn, verbose=verbose)
		if (access(mcat) == NO)
		    next
		if (!reset) {
		    raoffset=acematch.xi; decoffset=acematch.eta
		}
	    }

	    # Do global contraints and possibly define fitting grid points.
	    acegeomap (mcat, temp2, wcs="", catdef="", filter="",
	        all=no, fitgeometry="general", reject=3., interactive=no,
		rms=2., ngrid=ngrid, logfiles=logfn, verbose=verbose)

	    # Set the WCS.
	    match ("#k IMAGE ", temp//"2*.tmp", stop-) |
	        fields ("STDIN", 4, lines="1-", print-, > temp3)
	    translit (temp3, "[]", " ", del-, collapse-) |
	        fields ("STDIN", 2, lines="1-", print-, > temp4)
	    delete (wcsdb, verify-, >& "dev$null")
	    if (verbose) {
		date | scan (str)
	        printf ("\nCCMAP: %s %s\n", envget("version"), str) |
		    tee (logfn, append+)
		ccmap (temp//"2*.tmp", wcsdb, solutions="@"//temp4,
		    images="@"//temp3, results="", xcolumn=4,
		    ycolumn=5, lngcolumn=1, latcolumn=2, xmin=INDEF,
		    xmax=INDEF, ymin=INDEF, ymax=INDEF, lngunits="hours",
		    latunits="degrees", insystem="j2000", refpoint="user",
		    lngref=acegeomap.ra, latref=acegeomap.dec,
		    refsystem="INDEF", lngrefunits="", latrefunits="",
		    projection="tnx", fitgeometry="general",
		    function="polynomial", xxorder=4, xyorder=4,
		    xxterms="full", yxorder=4, yyorder=4, yxterms="full",
		    maxiter=3, reject=3., update=yes, pixsystem="logical",
		    verbose=yes, interactive=no, graphics="stdgraph",
		    cursor="") | tee (logfn, append+)
		acesetwcs (cat, cat, wcsdb, "@"//temp4, catdef="",
		    verbose=yes) | tee (logfn, append+)
	    } else {
		date | scan (str)
	        printf ("\nCCMAP: %s %s\n", envget("version"), str, >> logfn)
	        print (str, >> logfn)
		ccmap (temp//"2*.tmp", wcsdb, solutions="@"//temp4,
		    images="@"//temp3, results="", xcolumn=4,
		    ycolumn=5, lngcolumn=1, latcolumn=2, xmin=INDEF,
		    xmax=INDEF, ymin=INDEF, ymax=INDEF, lngunits="hours",
		    latunits="degrees", insystem="j2000", refpoint="user",
		    lngref=acegeomap.ra, latref=acegeomap.dec,
		    refsystem="INDEF", lngrefunits="", latrefunits="",
		    projection="tnx", fitgeometry="general",
		    function="polynomial", xxorder=4, xyorder=4,
		    xxterms="full", yxorder=4, yyorder=4, yxterms="full",
		    maxiter=3, reject=3., update=yes, pixsystem="logical",
		    verbose=yes, interactive=no, graphics="stdgraph",
		    cursor="", >> logfn)
		acesetwcs (cat, cat, wcsdb, "@"//temp4, catdef="",
		    verbose=yes, >> logfn)

	    }

	    delete (temp//"[234_]*", verify-)

	}
	fd = ""

	delete (temp//"*", verify-)
end
