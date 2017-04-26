# OPROC -- Process object exposures.

procedure oproc (input)

file	input			{prompt="List of input ODI directories"}
file	output = ""		{prompt="List of processed directories"}
string	outtype = "ota"		{prompt="Output type (ota|image|mef)",
				 enum="ota|image|mef"}
bool	list = no		{prompt="List only?\n"}

bool	trim = yes		{prompt="Trim?"}
bool	fixpix = yes		{prompt="Fix bad pixels by interpolation?"}
bool	overscan = yes		{prompt="Overscan correction?"}
bool	zerocor = yes		{prompt="Apply zero calibration?"}
bool	darkcor = no		{prompt="Apply dark calibration?"}
bool	flatcor = yes		{prompt="Apply flat field calibration?"}
bool	merge = yes		{prompt="Merge cells?\n"}

string	bpm = ""		{prompt="List of masks or expression"}
string	zeros = ""		{prompt="List of zero images"} 
string	darks = ""		{prompt="List of dark images"} 
string	flats = ""		{prompt="List of flat field images\n"}

bool	verbose = yes		{prompt="Verbose output?"}
string	logfiles = "logfile"	{prompt="Log files"}

begin
	odiproc (input, output=output, outtype=outtype, list=list,
	    intype="(object)", verbose=verbose, logfiles=logfiles,
	    trim=trim, fixpix=fixpix, biascor=overscan, zerocor=zerocor,
	    darkcor=darkcor, flatcor=flatcor, merge=merge, bpm=bpm,
	    zeros=zeros, darks=darks, flats=flats, taskname="oproc")
end
