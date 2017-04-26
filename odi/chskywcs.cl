# CHSKYWCS -- Change the sky WCS projection.

procedure chskywcs (input, output, projection)

string	input			{prompt="List of images"}
string	output			{prompt="List of output images"}
string	projection		{prompt="WCS projection desired"}
bool	verbose = yes		{prompt="Verbose output?"}
real	gridspacing = 200	{prompt="Approx. fitting grid spacing (pixels)\n"}

string	function = "polynomial" {prompt="Surface type",
				    enum="|polynomial|chebyshev|legendre|"}
int	xxorder = 4             {prompt="Order of xi fit in x"}
int	xyorder = 4             {prompt="Order of xi fit in y"}
string	xxterms = "half"        {prompt="Xi fit cross terms type",
				    enum="|full|half|none|"}
int	yxorder = 4             {prompt="Order of eta fit in x"}
int	yyorder = 4             {prompt="Order of eta fit in y"}
string	yxterms = "half"        {prompt="Eta fit cross terms type",
				    enum="|full|half|none|"}

struct	*fd

begin
	file im, in, out, grid, tmp, tmp1, tmp2
	int	nx, ny
	real	x, y, naxis1, naxis2, xstep, ystep
	string	proj, ctype1, ctype2, lngref, latref

	# Set temporary files.
	tmp = mktemp ("tmp$iraf")
	tmp1 = tmp // "a"
	tmp2 = tmp // "b"
	grid = tmp // "c"

	# Expand lists and set query parameters.
	sections (input, option="fullname", > tmp1)
	nx = sections.nimages
	sections (output, option="fullname", > tmp2)
	ny = sections.nimages
	if (ny < 0 && ny != nx) {
	    printf ("WARNING: Input and output lists don't match\n")
	    delete (tmp1//","//tmp2, v-)
	    return
	}
	joinlines (tmp1, tmp2, output=tmp, delim=" ", miss="-", short-, verb-)
	delete (tmp1//","//tmp2, v-)
	proj = projection

	fd = tmp
	while (fscan (fd, in, out) != EOF) {

	    # Set output.
	    if (out == "-")
		out = in
	    if (out != in && imaccess(out)) {
		printf ("WARNING: %s already exists - skipping\n", out)
		next
	    }

	    # Make grid of fitting coordinates.
	    hselect (in, "naxis1, naxis2, ctype1, ctype2", yes) |
		scan (naxis1, naxis2, ctype1, ctype2)
	    nx = nint ((naxis1 - 1.) / gridspacing) + 1
	    ny = nint ((naxis2 - 1.) / gridspacing) + 1
	    xstep = (naxis1 - 1.) / (nx - 1)
	    ystep = (naxis2 - 1.) / (ny - 1)
	    for (y = 1; y <= naxis2; y += ystep)
		for (x = 1; x <= naxis1; x += xstep)
		    printf ("%.1f\t%.1f\t%.1f\t%.1f\n", x, y, x, y, >> tmp1)
	    if (substr(ctype1,1,2)=="RA") {
		lngref = "CRVAL1"
		latref = "CRVAL2"
		wcsctran (tmp1, grid, in, "logical", "world", col="3 4",
		    units="", formats="%.3H %.2h", min=9, verb-)
	    } else {
		lngref = "CRVAL2"
		latref = "CRVAL1"
		wcsctran (tmp1, grid, in, "logical", "world", col="4 3",
		    units="", formats="%.3H %.2h", min=9, verb-)
	    }
	    mscctran (tmp1, tmp2, in, "logical", "astro", col="1 2",
		units="", formats="", min=12, verb-)
	    delete (tmp1, v-)

	    # Fit new WCS and update header.
	    if (out != in) {
		imcopy (in, out, verb-)
		im = out
	    } else
	        im = in

	    ccmap (grid, "dev$null", solutions="", images=im, results="",
		xcolumn=1, ycolumn=2, lngcolumn=3, latcolumn=4,
		xmin=1., xmax=naxis1, ymin=1., ymax=naxis2,
		lngunits="hours", latunits="degrees", insystem="j2000",
		refpoint="user", xref="CRPIX1", yref="CRPIX2",
		lngref=lngref, latref=latref, refsystem="INDEF",
		lngrefunits="degrees", latrefunits="degrees", projection=proj,
		fitgeometry="general", function=function,
		xxorder=xxorder, xyorder=xyorder, xxterms=xxterms,
		yxorder=yxorder, yyorder=yyorder, yxterms=yxterms,
		maxiter=0, reject=3, update=yes, pixsystem="logical",
		verbose=no, interactive=no, > "dev$null")
	    delete (grid, ver-)

	    # Compute residuals from previous WCS.
	    mscctran (tmp2, grid, out, "logical", "astro", col="3 4",
		units="", formats="", min=12, verb-)
	    delete (tmp2, v-)

	    list = grid
	    while (fscan (list, x, y, xstep, ystep) != EOF) {
		x -= xstep
		y -= ystep
		x *= 1000
		y *= 1000
		print (x, >> tmp1)
		print (y, >> tmp2)
	    }
	    list = ""; delete (grid, v-)

	    # Output information.
	    if (verbose) {
		printf ("%s (%s) -> %s (%s):\n",
		    in, substr(ctype1,6,99), out, strupr(proj))
		tstat (tmp1, "c1", out="", low=INDEF, high=INDEF, rows="-")
		printf ("  X residuals:   %-9.1f %-9.1f %-9.1f %-9.1f %-9s\n",
		    tstat.mean, tstat.stddev, tstat.vmin, tstat.vmax, "marcsec")
		tstat (tmp2, "c1", out="", low=INDEF, high=INDEF, rows="-")
		printf ("  Y residuals:   %-9.1f %-9.1f %-9.1f %-9.1f %-9s\n",
		    tstat.mean, tstat.stddev, tstat.vmin, tstat.vmax, "marcsec")
	    }

	    if (im == "velvect") {
		imdelete (im, v-)
		rtextimage (tmp1, tmp1, dim=nx//","//ny, header-)
		rtextimage (tmp2, tmp2, dim=nx//","//ny, header-)
		velvect (tmp1, tmp2, title="wcschtype")
		imdelete (tmp1//","//tmp2, v-)
	    }
	    delete (tmp1//","//tmp2, v-)
	}
	fd = ""; delete (tmp, v-)
end
