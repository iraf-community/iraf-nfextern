# NFLIST -- List data.

procedure nflist (input)

file	input			{prompt="List of input NEWFIRM files"}
string	obstype = ""		{prompt="Obstype string to match"}
bool	showops = no		{prompt="Show operations to be done?"}

begin
	string	intype

	if (obstype != "")
	    intype = "(obstype?='{"//obstype//"}')"
	else
	    intype = ""

	if (showops)
	    nfproc (input, "", outtype="list", logfiles="STDOUT", intype=intype,
	        dtype="(obstype='dark')", ftype="(fflat)", gtype="(gflat)",
		stype="(obstype='sky')", taskname="nflist")
	else
	    nfproc (input, "", outtype="list", logfiles="STDOUT", intype=intype,
		dtype="(obstype='dark')", ftype="(fflat)", gtype="(gflat)",
		stype="(obstype='sky')", trim-, fixpix-, biascor-, lincor-,
		darkcor-, flatcor-, skysub-, replace-, normalize-,
		taskname="nflist")
end
