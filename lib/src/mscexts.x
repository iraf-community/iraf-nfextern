# MSCEXTENSIONS -- Expand template of files into a list of image extensions.
#
# This differs from IMEXTENSIONS in that extension zero is not returned
# unless it is a simple image and, in that case, the extension is removed.

int procedure mscextensions (files, index, extname, extver, lindex, lname, lver,
	ghdr, ikparams, err, imext)

char	files[ARB]		#I List of ME files
char	index[ARB]		#I Range list of extension indexes
char	extname[ARB]		#I Patterns for extension names
char	extver[ARB]		#I Range list of extension versions
int	lindex			#I List index number?
int	lname			#I List extension name?
int	lver			#I List extension version?
int	ghdr			#I Include dataless global header?
char	ikparams[ARB]		#I Image kernel parameters
int	err			#I Print errors?
int	imext			#O Image extensions?
int	list			#O Image list

char	c
int	i, j, nphu, nimages, fd
pointer	sp, temp, image, image0, im, immap()
int	imextensions(), gstrmatch(), imtopen(), imtgetim(), open()
errchk	imextensions, open, immap, delete

begin
	call smark (sp)
	call salloc (temp, SZ_FNAME, TY_CHAR)
	call salloc (image, SZ_FNAME, TY_CHAR)
	call salloc (image0, SZ_FNAME, TY_CHAR)

	# Get the list.
	list = imextensions (files, index, extname, extver, lindex, lname,
	    lver, ikparams, err)

	# Check and edit the list.
	nphu = 0
	nimages = 0
	call mktemp ("@tmp$iraf", Memc[temp], SZ_FNAME)
	fd = open (Memc[temp+1], NEW_FILE, TEXT_FILE)
	while (imtgetim (list, Memc[image], SZ_FNAME) != EOF) {
	    if (gstrmatch (Memc[image], "\[0\]", i, j) > 0) {
	        call strcpy (Memc[image], Memc[image0], SZ_FNAME)
		call strcpy (Memc[image+j], Memc[image+i-1], SZ_FNAME)
		ifnoerr (im = immap (Memc[image], READ_ONLY, 0)) {
		    call imunmap (im)
		    nphu = nphu + 1
		} else if (ghdr == YES)
		    call strcpy (Memc[image0], Memc[image], SZ_FNAME)
		else
		    next
	    } else if (gstrmatch (Memc[image], "\[1\]", i, j) > 0) {
		c = Memc[image+j]
		Memc[image+j] = EOS
		Memc[image+i] = '0'
		iferr {
		    im = immap (Memc[image], READ_ONLY, 0)
		    call imunmap (im)
		    Memc[image+j] = c
		    Memc[image+i] = '1'
		} then {
		    Memc[image+j] = c
		    call strcpy (Memc[image+j], Memc[image+i-1], SZ_FNAME)
		    nphu = nphu + 1
		}
	    }
	    nimages = nimages + 1
	    call fprintf (fd, "%s\n")
		call pargstr (Memc[image])
	}
	call close (fd)

	# Return new list and extension flag.
	imext = YES
	if (nphu == nimages)
	    imext = NO
	call imtclose (list)
	list = imtopen (Memc[temp])
	call delete (Memc[temp+1])
	call sfree (sp)
	return (list)
end
