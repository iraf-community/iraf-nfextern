# DPROC -- Process dark exposures.

procedure dproc (input)

file	input			{prompt="List of input ODI directories"}
file	output = ""		{prompt="List of processed directories"}
bool	list = no		{prompt="List only?\n"}

bool	trim = yes		{prompt="Trim?"}
bool	fixpix = yes		{prompt="Fix bad pixels by interpolation?"}
bool	overscan = yes		{prompt="Overscan correction?"}
bool	zerocor = yes		{prompt="Apply zero calibration?\n"}

string	bpm = ""		{prompt="List of masks or expression"}
string	zeros = ""		{prompt="List of zero images\n"} 

bool	verbose = yes		{prompt="Verbose output?"}
string	logfiles = "logfile"	{prompt="Log files"}

begin
	odiproc (input, output=output, list=list, intype="(dark)",
	    verbose=verbose, logfiles=logfiles, trim=trim, fixpix=fixpix,
	    biascor=overscan, zerocor=zerocor, bpm=bpm, zeros=zeros,
	    taskname="dproc")
end
