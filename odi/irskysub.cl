# IRSKYSUB -- This is a wrapper on IRPROC that does only sky subtractions.

procedure irskysub (input, output)

string	input = ""		{prompt="List of input images"}
string	output = "s+"		{prompt="List of output images"}
string	skies = ""		{prompt="List of skies (empty to use input)"}
string	skymatch = ""		{prompt="Match boolean expression"}
string	skymode = "nearest"	{prompt="Sky subtraction mode"}
string	inmask = "!objmask"	{prompt="Input mask or keyword reference"}
string	logfiles = "STDOUT,logfile"	{prompt="List of output logfiles"}

begin
	irproc (input, output, skies=skies, logfiles=logfiles,
	    skymatch=skymatch, skymode=skymode, inmask=inmask,
	    outmasks="", biascor=no, darkcor=no, lincor=no, satcor=no,
	    flatcor=no, skysub=yes, fixpix=no, trim=no, normalize=no,
	    order="S", intype="", stype="", dtype="", ftype="",
	    override=yes, copy=yes, erraction="warn")
end
