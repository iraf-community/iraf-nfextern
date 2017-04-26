# MSCEXTRACT -- Extract extensions into a new MEF.

procedure mscextract (input, output, extname)

string	input = ""		{prompt="List of input MEF files"}
string	output = ""		{prompt="List of output MEF files"}
string	extname = ""		{prompt="Extension name pattern"}
bool	verbose = yes		{prompt="Verbose?"}

begin
	struct	cmd

	printf ("imcopy $input $output verbose=%b\n", verbose) | scan (cmd)
	msccmd (cmd, input, output, extname=extname, ikparams="",
	    alist=no, flist=yes, dataless=no, verbose=no, exec=yes)
end
