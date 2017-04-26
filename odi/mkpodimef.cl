# MKPODIMEF -- Process pODI exposures into MEF and display.

procedure mkpodimef (input)

file	input			{prompt="Input ODI directory"}
file	output = ""		{prompt="Output file or directory (ending in /)"}
bool	overscan = yes		{prompt="Overscan correction?"}
string	adjust = "scale"	{prompt="Cell adjustment (none|zero|scale)",
				 enum="none|zero|scale"}
string	biassec = "[481:536,*]"	{prompt="Temporary biassec override"}
bool	override = no		{prompt="Override previous processing?"}
bool	verbose = yes		{prompt="Verbose output?\n\nDisplay Options"}

string	display = "center"	{prompt="Display (none|center|default)"}
int	frame = 1		{prompt="Frame to be written", min=1, max=16}
bool	zscale = yes		{prompt="Scale display range?"}
string	zcombine = "auto"	{prompt="Algorithm for OTA scaling",
				 enum="none|auto|minmax|average|median"}
real	z1 = 0.			{prompt="Minimum value to be displayed"}
real	z2 = 1000.		{prompt="Maximum value to be displayed"}

begin
	file	in, out, mef

	# Set input and output.
	in = input
	out = output
	if (strldx("/",in) == strlen(in))
	    in = substr (in, 1, strlen(in)-1)
	if (out == "")
	    mef = in
	else if (strldx("/",out) == strlen(out))
	    mef = out // in
	else
	    mef = out
	if (strstr(".fits",mef) == 0)
	    mef += ".fits"

	# Workarounds.
	odiproc.biassec = biassec

	if (!imaccess(mef) || override) {
	    if (overscan) {
		# Overscan subtract if desired.
		odiproc (in, output="poditmp", list=no, verbose=verbose,
		    logfiles="", trim=yes, fixpix=no, biascor=overscan,
		    saturation=no, zerocor=no, darkcor=no, flatcor=no,
		    replace=no, normalize=no, intype="", override=override,
		    taskname="mkpodimef")

		# Reformat.
		odireformat ("poditmp", mef, outtype="mef", pattern="",
		    adjust=adjust, override=override, verbose=verbose)

		# Clean up.
		!rm -r poditmp
	    } else
		odireformat (in, mef, outtype="mef", pattern="",
		    adjust=adjust, override=override, verbose=verbose)
	}

	if (display == "center")
	    mscdisplay (mef, frame, zrange=no, zcombine=zcombine,
		 zscale=zscale, z1=z1, z2=z2, extname="xy[234][234]")
	else if (display != "none")
	    mscdisplay (mef, frame, zrange=no, zcombine=zcombine,
		 zscale=zscale, z1=z1, z2=z2, extname="")

end
