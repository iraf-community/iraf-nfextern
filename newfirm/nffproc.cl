# NFFPROC -- Process flat exposures.

procedure nffproc (input)

string	input			{prompt="List of input NEWFIRM files"}
file	output = "flat_+"	{prompt="List of processed dark files\n"}

bool	trim = yes		{prompt="Trim?"}
bool	fixpix = yes		{prompt="Fix bad pixels by interpolation?"}
bool	biascor = no		{prompt="Bias reference pixel correction?"}
bool	darkcor = yes		{prompt="Apply dark count calibration?"}
bool	lincor = yes		{prompt="Linearity correction?"}
bool	normalize = yes		{prompt="Normalize?\n"}

string	bpm = "nfdat$nfbpm"	{prompt="List of masks or expression"}
string	darks = "Dark_*"	{prompt="List of dark images"} 
real	floor = INDEF		{prompt="Output minimum value (ADU)\n"}

bool	list = no		{prompt="List only?"}
string	logfiles = "STDOUT,logfile"	{prompt="Log files"}

begin
	bool	replace
	string	outtype, linval
	struct	expr, repexpr

	# Set output type.
	if (list)
	    outtype = "vlist"
	else
	    outtype = "image"

	# Set replacement.
	if (isindef(floor)) {
	   replace = no
	   repexpr = ""
	} else {
	   replace = yes
	   repexpr = "(max($I," // floor // "))"
	}

	# Process or list.
	_nfproc (input, output, intype="(obstype='flat')", outtype=outtype,
	    logfiles=logfiles, trim=trim, fixpix=fixpix, biascor=biascor,
	    lincor=lincor, darkcor=darkcor, replace=replace,
	    normalize=normalize, bpm=bpm, darks=darks,
	    repexpr=repexpr, taskname="nffproc")

end
