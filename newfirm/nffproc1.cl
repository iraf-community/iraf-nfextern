# NFFPROC -- Process flat exposures.

procedure nffproc (input)

string	input			{prompt="List of input NEWFIRM files"}
file	output = "flat_+"	{prompt="List of processed dark files\n"}

bool	trim = yes		{prompt="Trim?"}
bool	fixpix = yes		{prompt="Fix bad pixels by interpolation?"}
bool	biascor = no		{prompt="Bias reference pixel correction?"}
bool	darkcor = yes		{prompt="Apply dark count calibration?"}
bool	lincor = yes		{prompt="Linearity correction?\n"}

string	darks = "Dark_*"	{prompt="List of dark images\n"} 

bool	list = no		{prompt="List only?"}
string	logfiles = "STDOUT,logfile"	{prompt="Log files"}

begin
	string	intype, outtype, linval
	struct	expr

	# Set input type.
	intype = "(obstype='flat')"

	# Set output type.
	if (list)
	    outtype = "vlist"
	else
	    outtype = "image"

	# Set linearity parameters.
	if (nflinearize.exprdb == "")
	    error (2, "Must specify expression database")
	if (nflinearize.coeffs == "parameter")
	    linval = "nflinearize.lin\I"
	else if (nflinearize.coeffs == "exprdb")
	    linval = "L\I"
	else if (nflinearize.coeffs == "keyword")
	    linval = "lincoeff"
	else if (nflinearize.coeffs == "image")
	    linval = "$L"
	else
	    error (1, "Unknown coefficient type")

	# Set expression.
	printf ("%%(lin(%s))\n", linval) | scan (expr)
	
	# Compute linearity or list the expressions.
	nfproc (input, output, outtype=outtype, logfiles=logfiles,
	    trim=trim, fixpix=fixpix, biascor=biascor, lincor=lincor,
	    permask=no, zerocor=no, darkcor=yes, flatcor=no, skysub=no,
	    replace=no, normalize=no, zorder="TXB", dorder="TXBZ",
	    forder="TXBZDL,N", order="TXBZDLF,S", bpm="(bpm)", obm="",
	    trimsec="(trimsec)", biassec="(biassec)", linexpr=expr,
	    linimage=linimage, persist="", perwindow="5", zeros="",
	    darks=darks, flats="", flatexpr="", skies="", skymatch="",
	    skymode="median 10", repexpr="", repimage="", intype=intype,
	    ztype="", dtype="(obstype='dark')", ftype="(obstype='flat')",
	    gtype="", stype="", imageid="(str(imageid))", filter="",
	    sortval="(@'mjd-obs')", exptime="(exptime)", opdb="",
	    exprdb=nflinearize.exprdb, override=no, copy=no,
	    erraction="warn", gdevice="stdgraph", gcursor="", gplotfile="",
	    taskname="nffproc")

end
