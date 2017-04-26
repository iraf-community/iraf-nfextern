# NFFOCUS -- NEWFIRM focus task.
#
# This is layered on STFCAT and is tied specifically to using the
# ACE header FWHM value rather than the individual stars.

procedure nffocus (images)

string	images			{prompt="Image, number, or list"}
string	sky = ""		{prompt="Sky"}
string	bpm = "!BPM"		{prompt="Bad pixel mask"}
string	catalogs = "_cat"	{prompt="Catalog suffix"}
string	saturate = "9000"	{prompt="Saturation"}
int	nmaxrec = INDEF		{prompt="Maximum sources per array"}
real	match = 10		{prompt="Matching distance (arcsec|-pix)"}
real	sig = 2.5		{prompt="Sigma clipping factor (INDEF to skip)"}
string	logfile = "nffocus.log"	{prompt="Logfile"}
bool	verbose = yes		{prompt="Verbose?"}
bool	interactive = yes	{prompt="Interactive?"}
real	focus			{prompt="Best focus (output)"}
real	fwhm			{prompt="FWHM at best focus (output)"}

struct	*fd

begin
	int	vlevel = 0
	int	i, n, nocno, noctot
	real	telfocus, nocfocus, rsig, fsig, f1, f2, f3, f4
	string	ims, obstype, sat, logs, catfilter, err
	file	im, skyim, temp

	cache acefocus, sections

	ims = images
	skyim = sky
	if (isindef(sig)) {
	    rsig = 0; fsig = 0
	} else {
	    rsig = 0.9 * sig; fsig = sig
	}
	logs = logfile
	temp = mktemp ("tmp$iraf")

	# Set the verbose behavior.
	if (verbose) {
	    vlevel = 1
	    logs += ",STDOUT"
	}

	# Expand the input list.
	sections (ims, option="fullname", > temp//"A.tmp")
	if (sections.nimages == 1) {
	    delete (temp//"A.tmp", verify-)
	    im = ""
	    if (imaccess(ims))
		im = ims
	    else
		files ("*"//ims//".fits") | scan (im)
	    if (im == "" || !imaccess(im))
	        error (1, "No focus image found")
	    nocno = 0; noctot = 0
	    hselect (im//"[0]", "nocno,noctot", yes) | scan (nocno, noctot)
	    n = 0
	    i = strstr (".fits", im) - 1
	    if (i == -1)
		i = strlen (im) 
	    if (i > 5) {
		n = int (substr (im, i-4, i))
		im = substr (im, 1, i-5)
	    }
	    n = n - nocno + 1
	    for (i=n; i<n+noctot; i+=1)
		printf ("%s%05d.fits\n", im, i, >> temp//"A.tmp")
	}

	# Set the sky and focus images.
	err = ""; skyim = ""; ims = temp // ".tmp"
	f1 = INDEF; f2 = INDEF; f3 = INDEF; f4 = INDEF
	fd = temp // "A.tmp"; touch (ims)
	while (fscan (fd, im) != EOF) {
	    obstype = ""; telfocus = INDEF; nocfocus = INDEF
	    hselect (im//"[0]", "obstype,telfocus,nocfocus", yes) |
	        scan (obstype, telfocus, nocfocus)
	    print (im, " ", telfocus, nocfocus)
	    if (obstype == "sky")
	        skyim = im
	    else if (obstype == "object" || obstype == "focus") {
	        if (isindef(telfocus) || isindef(nocfocus))
		    err = "Missing focus values"
		else if (isindef(f1)) {
		    f1 = telfocus; f2 = telfocus
		    f3 = nocfocus; f4 = nocfocus
		} else {
		    f1 = min (f1, telfocus); f2 = max (f2, telfocus)
		    f3 = min (f3, nocfocus); f4 = max (f4, nocfocus)
		}
	        print (im, >> ims)
	    }
	}
	fd = ""; delete (temp//"A.tmp")
	count (ims) | scan (i)
	if (i < 3)
	    err = "Not enough focus images"
	if (f1 == f2 && f3 == f4)
	    err = "All focus values are the same"

	# Check for errors.
	if (err != "") {
	    delete (ims)
	    error (1, err)
	}

	if (sky != "")
	    skyim = sky
	printf ("sky = '%s'\nfocus:\n", skyim)
	concat (ims)
	ims = "@" // ims

	# Create the catalogs.
	#catfilter = "(FWHM<2.5*$FWHM||FLAGS?='R')&&ELLIP<0.2"
	catfilter = "(FWHM<2.5*$FWHM||FLAGS?='R')"
	if (fscan (saturate, sat) > 0)
	    catfilter += "&&PEAK+SKY<=" // sat
	printf ("Creating catalogs (if necessary) ...\n")
	if (skyim == "")
	    acecatalog (ims, masks=bpm, exps="", gains="", spatialvar="",
		extnames="", logfiles=logfile, verbose=vlevel,
		catalogs="+"//catalogs, catdefs="nfdat$acefocus1.dat",
		catfilter=catfilter, order="-PEAK", nmaxrec=nmaxrec,
		magzero="INDEF", gwtsig=INDEF, gwtnsig=INDEF, objmasks="",
		omtype="all", skies="", sigmas="", fitstep=100,
		fitblk1d=10, fithclip=2., fitlclip=3., fitxorder=1,
		fityorder=1, fitxterms="half", blkstep=1, blksize=-10,
		blknsubblks=2, hdetect=yes, ldetect=no, updatesky=yes,
		bpdetect="1-100", bpflag="1-100", convolve="", hsigma=5.,
		lsigma=10., neighbors="8", minpix=8, sigavg=4., sigmax=4.,
		bpval=INDEF, splitstep=0., splitmax=INDEF, splitthresh=5.,
		sminpix=8, ssigavg=10., ssigmax=5., ngrow=0, agrow=0.)
	else
	    acediff (ims, skyim, masks=bpm, exps="", gains="", scales="",
		extnames="", logfiles=logfile, verbose=vlevel,
		rmasks="!BPM", rexps="", rgains="", rscales="", roffset="",
		catalogs="+"//catalogs, catdefs="nfdat$acefocus1.dat",
		catfilter=catfilter, order="-PEAK", nmaxrec=INDEF,
		magzero="INDEF", gwtsig=INDEF, gwtnsig=INDEF, objmasks="",
		omtype="all", skies="", sigmas="", rskies="", rsigmas="",
		fitstep=100, fitblk1d=10, fithclip=2., fitlclip=3.,
		fitxorder=1, fityorder=1, fitxterms="half", blkstep=1,
		blksize=-10, blknsubblks=2, hdetect=yes, ldetect=no,
		updatesky=yes, bpdetect="1-100", bpflag="1-100",
		convolve="", hsigma=5., lsigma=10., neighbors="8",
		minpix=8, sigavg=4., sigmax=4., bpval=INDEF, rfrac=0.5,
		splitstep=0., splitmax=INDEF, splitthresh=5., sminpix=8,
		ssigavg=10., ssigmax=5., ngrow=0, agrow=0.)

	# Determine the focus.
	printf ("Determining focus ...\n")
	if (f1 != f2)
	    acefocus (ims, catdef="nfdat$acefocus.dat", filter="",
	       focus="!telfocus", match=match, rsig=rsig, fsig=fsig,
	       logfiles=logs, interactive=interactive, graphcur="")
	else {
	    print ("WARNING: TELFOCUS all the same, using NOCFOCUS")
	    acefocus (ims, catdef="nfdat$acefocus.dat", filter="",
	       focus="!nocfocus", match=match, rsig=rsig, fsig=fsig,
	       logfiles=logs, interactive=interactive, graphcur="")
	}

	focus = acefocus.bestfocus
	fwhm = acefocus.bestsize
	if (!isindef(fwhm))
	    printf ("Recommended focus is %.6g with FWHM of %.2f\n",
		focus, fwhm)

	if (temp != "")
	    delete (temp//"*", verify-)
end
