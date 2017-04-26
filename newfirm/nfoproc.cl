# NFOPROC -- Process object exposures.

procedure nfoproc (input)

string	input			{prompt="List of input NEWFIRM exposures"}
file	output = "obj_+"	{prompt="List of processed object exposures\n"}

bool	trim = yes		{prompt="Trim?"}
bool	fixpix = yes		{prompt="Fix bad pixels by interpolation?"}
bool	biascor = no		{prompt="Bias reference pixel correction?"}
bool	darkcor = yes		{prompt="Apply dark count calibration?"}
bool	lincor = yes		{prompt="Linearity correction?"}
bool	flatcor = yes		{prompt="Apply flat field calibration?"}

string	bpm = "nfdat$nfbpm"	{prompt="List of masks or expression"}
string	darks = "Dark_*"	{prompt="List of dark calibrations"} 
string	flats = "Flat_*"	{prompt="List of flat calibrations"} 
string	flattype = "on"		{prompt="Type of flat field (on|off|diff)\n",
					enum="on|off|diff"}

bool	list = no		{prompt="List only?"}
string	logfiles = "STDOUT,logfile"	{prompt="Log files"}

begin
	string	outtype, linval
	struct	linexpr, flatexpr

	# Set output type.
	if (list)
	    outtype = "vlist"
	else
	    outtype = "image"

	# Set flat field expression.
	if (flattype == "on")
	    flatexpr = "$I/max(0.1,$F)"
	else if (flattype == "off")
	    flatexpr = "$I/max(0.1,$G)"
	else
	    flatexpr = "$I/max(0.1,$F-$G)"
	
	# Process or list.
	_nfproc (input, output, intype="(obstype='object')", outtype=outtype,
	    logfiles=logfiles, trim=trim, fixpix=fixpix, biascor=biascor,
	    lincor=lincor, darkcor=darkcor, flatcor=flatcor,
	    order="TXBDLF", bpm=bpm, darks=darks, flats=flats,
	    flatexpr=flatexpr, taskname="nfoproc")

end
