# NFDPROC -- Process dark exposures.

procedure nfdproc (input)

file	input			{prompt="List of input NEWFIRM files"}
file	output = "dark_+"	{prompt="List of processed dark files\n"}

bool	trim = yes		{prompt="Trim?"}
bool	fixpix = yes		{prompt="Fix bad pixels by interpolation?"}
string	bpm = "nfdat$nfbpm"	{prompt="List of masks or expression"}
bool	biascor = no		{prompt="Bias reference pixel correction?\n"}

bool	list = no		{prompt="List only?"}
string	logfiles = "STDOUT,logfile"	{prompt="Log files"}

begin
	string	outtype

	# Set output type.
	if (list)
	    outtype = "vlist"
	else
	    outtype = "image"
	
	# Process or list.
	_nfproc (input, output, intype="(obstype='dark')", outtype=outtype,
	    logfiles=logfiles, trim=trim, fixpix=fixpix, biascor=biascor,
	    bpm=bpm, taskname="nfdproc")

end
