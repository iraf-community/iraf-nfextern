# ZPROC -- Process zero exposures.

procedure zproc (input)

file	input			{prompt="List of input ODI directories"}
file	output = ""		{prompt="List of processed directories"}
bool	list = no		{prompt="List only?\n"}

bool	trim = yes		{prompt="Trim?"}
bool	fixpix = yes		{prompt="Fix bad pixels by interpolation?"}
bool	overscan = yes		{prompt="Overscan correction?\n"}

string	bpm = ""		{prompt="List of masks or expression\n"}

bool	verbose = yes		{prompt="Verbose output?"}
string	logfiles = "logfile"	{prompt="Log files"}

begin
	odiproc (input, output=output, outtype="ota", list=list,
	    intype="(zero)", verbose=verbose, logfiles=logfiles,
	    trim=trim, fixpix=fixpix, biascor=overscan, merge=no, bpm=bpm,
	    taskname="zproc")
end
