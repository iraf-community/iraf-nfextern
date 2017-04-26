# fproc -- Process flat exposures.

procedure fproc (input)

file	input			{prompt="List of input ODI directories"}
file	output = ""		{prompt="List of processed directories"}
bool	list = no		{prompt="List only?\n"}

bool	trim = yes		{prompt="Trim?"}
bool	fixpix = yes		{prompt="Fix bad pixels by interpolation?"}
bool	overscan = yes		{prompt="Overscan correction?"}
bool	zerocor = yes		{prompt="Apply zero calibration?"}
bool	darkcor = no		{prompt="Apply dark calibration?"}
bool	normalize = yes		{prompt="Normalize?\n"}

string	bpm = ""		{prompt="List of masks or expression"}
string	zeros = ""		{prompt="List of zero images"} 
string	darks = ""		{prompt="List of dark images"} 
real	floor = 1.		{prompt="Output minimum value (ADU)\n"}

bool	verbose = yes		{prompt="Verbose output?"}
string	logfiles = "logfile"	{prompt="Log files"}

begin
	bool	replace
	string	repexpr

	# Set replacement.
	if (isindef(floor))
	   replace = no
	else
	   replace = yes
	repexpr = "(max($I," // floor // "))"

	odiproc (input, output=output, outtype="ota", list=list,
	    intype="(flat)", verbose=verbose, logfiles=logfiles,
	    trim=trim, fixpix=fixpix, biascor=overscan, zerocor=zerocor,
	    darkcor=darkcor, normalize=normalize, merge=no, bpm=bpm,
	    replace=replace, repexpr=repexpr, zeros=zeros, darks=darks,
	    taskname="fproc")
end
