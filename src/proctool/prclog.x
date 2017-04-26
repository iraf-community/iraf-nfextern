include	<time.h>
include	"prc.h"
include	"pi.h"


# PRCLOG - The purpose of these routines is to store up log information
# in a string buffer to be flushed later.


# PRCLOG_OPEN -- Allocate and open log string buffer.

procedure prclog_open (maxchar)

int	maxchar				#I Maximum size of string buffer.

int	logfd, logmaxchar, stropen()
pointer	logbuf
common	/prclogcom/ logfd, logbuf, logmaxchar

errchk	stropen

begin
	logmaxchar = maxchar
	call calloc (logbuf, logmaxchar, TY_CHAR)
	logfd = stropen (Memc[logbuf], logmaxchar, NEW_FILE)
end


# PRCLOG_CLOSE -- Close and free log string buffer.

procedure prclog_close ()

int	logfd, logmaxchar
pointer	logbuf
common	/prclogcom/ logfd, logbuf, logmaxchar

begin
	call close (logfd)
	call mfree (logbuf, TY_CHAR)
end


# PRCLOG -- Log information.
# If the prcessing image pointer is not NULL then the image name is prepended.

procedure prclog (str, pi, hdr)

char	str[ARB]		# Log string
pointer	pi			# PI pointer
int	hdr			# Write to header?

int	logfd, logmaxchar
pointer	logbuf
common	/prclogcom/ logfd, logbuf, logmaxchar

begin

	if (pi != NULL) {
	    call fprintf (logfd, "%d %s: ")
		call pargi (hdr)
	        call pargstr (PI_NAME(pi))
	} else {
	    call fprintf (logfd, "%d ")
		call pargi (hdr)
	}
	call putline (logfd, str)
	call putline (logfd, "\n")
end


# PRCLOG_FLUSH -- Flush output to the list of logfiles.

procedure prclog_flush (ollist, im)

pointer	ollist				# Output logfile list.
pointer	im				#I IMIO pointer (optional)

int	i, j, fd, hdr
pointer	sp, fname, time, line, str, key

int	clgfil(), open(), stropen(), fscan(), getlline()
int	stridxs(), imaccf(), strncmp()
long	clktime()
errchk	open, stropen

int	logfd, logmaxchar
pointer	logbuf
common	/prclogcom/ logfd, logbuf, logmaxchar

begin
	call smark (sp)
	call salloc (fname, SZ_FNAME, TY_CHAR)
	call salloc (time, SZ_DATE, TY_CHAR)
	call salloc (line, 10*SZ_LINE, TY_CHAR)
	call salloc (str, SZ_LINE, TY_CHAR)
	call salloc (key, 8, TY_CHAR)

	# Close string buffer.
	call close (logfd)

	if (im != NULL) {
	    do i = 1, ARB {
	        call sprintf (Memc[key], 8, "PROC%04d")
		    call pargi (i)
	        if (imaccf (im, Memc[key]) == NO)
		    break
	    }
	    call cnvdate (clktime(0), Memc[time], SZ_DATE)
	    logfd = stropen (Memc[logbuf], logmaxchar, READ_ONLY)
	    while (fscan (logfd) != EOF) {
		call gargi (hdr)
		call gargstr (Memc[line], SZ_LINE)
		if (hdr==NO || Memc[line+1] == EOS)
		    next
		call sprintf (Memc[key], 8, "PROC%04d")
		    call pargi (i)
		i = i + 1
		if (Memc[line+1] != '$' &&
		    strncmp (Memc[line+1], "trimsec", 7) != 0 &&
		    strncmp (Memc[line+1], "biassec", 7) != 0) {
		    j = stridxs (":", Memc[line])
		    if (j > 0)
			call strcpy (Memc[line+j+1], Memc[line+1], SZ_LINE)
		}
		call sprintf (Memc[str], SZ_LINE, "%s %s")
		    call pargstr (Memc[time])
		    call pargstr (Memc[line+1])
		call imastr (im, Memc[key], Memc[str])
	    }
	    call close (logfd)
	}

	# Write string buffer to the logfiles.
	call clprew (ollist)
	while (clgfil (ollist, Memc[fname], SZ_FNAME) != EOF) {
	    fd = open (Memc[fname], APPEND, TEXT_FILE)
	    logfd = stropen (Memc[logbuf], logmaxchar, READ_ONLY)
	    while (getlline (logfd, Memc[line], 10*SZ_LINE) != EOF)
	        call putline (fd, Memc[line+2])
	    call close (logfd)
	    call close (fd)
	}

	# Reopen string buffer at begining.
	logfd = stropen (Memc[logbuf], logmaxchar, NEW_FILE)

	call sfree (sp)
end


# PRCLOG_CLEAR -- Clear log string buffer.

procedure prclog_clear ()

int	logfd, logmaxchar, stropen()
pointer	logbuf
common	/prclogcom/ logfd, logbuf, logmaxchar

begin
	call close (logfd)
	logfd = stropen (Memc[logbuf], logmaxchar, NEW_FILE)
end
