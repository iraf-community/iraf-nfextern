# NFGROUP -- Group NEWFIRM data

procedure nfgroup (input, output)

file	input			{prompt="List of input NEWFIRM files"}
string	output			{prompt="Output rootname"}
string	select = ""		{prompt="Selection expression"}
bool	mef = yes		{prompt="Output MEF names"}
bool	imageid = yes		{prompt="Group by imageid"}
bool	obstype = no		{prompt="Group by observation type"}
bool	filter = yes		{prompt="Group by filter"}
bool	seqnum = no		{prompt="Group by sequence number"}
bool	exptime = no		{prompt="Group by exposure time"}
bool	mjd = no		{prompt="Group by MJD"}
real	mjdgap = INDEF		{prompt="Maximum gap in MJD value (sec)"}

begin
	string	in, out, extension, group, seqval, temp
	real	seqgap = INDEF

	in = input
	out = output

	extension = ""
	group = ""
	seqval = ""
	if (!mef && imageid)
	    extension = "imageid"
	if (obstype)
	    group += "//'_'//obstype"
	if (filter)
	    group += "//'_'//mkid(filter,1,1)"
	if (seqnum)
	    group += "//'_'//seqnum"
	if (exptime)
	    group += "//'_'//exptime"
	if (mjd && !isindef(mjdgap)) {
	    seqval = "@'MJD-OBS'"
	    seqgap = mjdgap / 3600. / 24.
	}
	group = substr (group, 3, 999)
	if (out == "")
	    group = substr (group, 6, 999)
	if (extension != "")
	    group += "//'_'"

	if (mef) {
	    temp = mktemp ("tmp$iraf")
	    mscextensions (in, output="file", index="0", extname="",
	        extver="", lindex=yes, lname=no, lver=no, dataless=yes,
		ikparams="", > temp)
	    cgroup ("@"//temp, out, select=select, group=group, seqval=seqval,
		seqgap=seqgap, extension=extension)
	    delete (temp, verify-)
	} else
	    cgroup (in, out, select=select, group=group, seqval=seqval,
		seqgap=seqgap, extension=extension)
end
