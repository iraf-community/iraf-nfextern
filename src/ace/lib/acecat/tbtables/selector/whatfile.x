# Copyright restrictions apply - see tables$copyright.tables 
# 
include <imhdr.h>
include "whatfile.h"

# WHATFILE -- Return integer code indicating type of image

int procedure whatfile (file)

char	file[ARB]	# i: file name
#--
int	flag

int	is_image()

begin
	# This function exists mostly for backwards compatibility. 
	# The recommended function to use is is_image, as it does
	# not need special macros

	switch (is_image(file)) {
	case ERR:
	    flag = IS_UNKNOWN
	case NO:
	    flag = IS_TABLE
	case YES:
	    flag = IS_IMAGE
	}

	return (flag)
end

# IS_IMAGE -- Return YES if file is image, NO if table, and ERR if can't decide

int procedure is_image (file)

char	file[ARB]	# i: file name
#--
int	image, gindex, gsize
pointer	sp, tp, im, fname, root, ext
pointer	ksection, section, rowselect, colselect

int	tbtacc(), imaccess(), access(), fnextn()
pointer	tbtopn(), immap()

errchk	rdselect

begin
	call smark (sp)
	call salloc (fname, SZ_PATHNAME, TY_CHAR)
	call salloc (root, SZ_PATHNAME, TY_CHAR)
	call salloc (ext, SZ_FNAME, TY_CHAR)
	call salloc (ksection, SZ_FNAME, TY_CHAR)
	call salloc (section, SZ_FNAME, TY_CHAR)
	call salloc (rowselect, SZ_PATHNAME, TY_CHAR)
	call salloc (colselect, SZ_PATHNAME, TY_CHAR)

	# Remove row and column selectors from file name

	call rdselect (file, Memc[fname], Memc[rowselect], Memc[colselect], 
		       SZ_PATHNAME)

	# Remove extension specifier

	call imparse (Memc[fname], Memc[root], SZ_PATHNAME, Memc[ksection],
		      SZ_FNAME, Memc[section], SZ_FNAME, gindex, gsize)

	# Check to see if file exists

	if (access (Memc[root], 0, 0) == NO) {
	    # File does not exist under current name

	    if (fnextn (Memc[root], Memc[ext], SZ_FNAME) == 0) {
		# The file name does not have an extension, so use
		# tests which add default extensions

		if (imaccess (Memc[root], READ_ONLY) == YES) {
		    image = YES
		} else {
		    image = ERR
		}

		call tbtext (Memc[root], Memc[root], SZ_PATHNAME)
		if (tbtacc (Memc[root]) == YES) {
		    if (image == YES) {
			image = ERR
		    } else {
			image = NO
		    }
		}

	    } else {
		# Standard test for image when file does not exist
		# Any name of a non-existent file might be a table

		image = imaccess (Memc[root], NEW_FILE)
	    }

	} else if (gindex == 0) {
	    # If the primary header is explicitly specified, open
	    # the file as an image if it maps successfully

	    ifnoerr (im = immap (Memc[fname], READ_ONLY, NULL)) {
		image = YES
		call imunmap (im)

	    } else {
		image = ERR
	    }

	} else if (gindex == -1) {
	    # The test for images without extensions and images with
	    # explicit extensions is the same except an extra check
	    # is done to see if the primary image contains data

	    ifnoerr (im = immap (Memc[fname], READ_ONLY, NULL)) {
		image = YES
		call imunmap (im)

	    } else ifnoerr (tp = tbtopn (Memc[fname], READ_ONLY, NULL)) {
		image = NO
		call tbtclo (tp)

	    } else {
		image = ERR
	    }

	    # If a table has a bona fide primary image, it is really
	    # an image written by stwfits with gftoxdim = yes

	    if (image == NO) {
		call sprintf (Memc[fname], SZ_PATHNAME, "%s[0]")
		call pargstr (Memc[root])

		ifnoerr (im = immap (Memc[fname], READ_ONLY, NULL)) {
		    if (IM_NDIM(im) > 0)
			image = ERR

		    call imunmap (im)
		}
	    }

	} else {
	    # If no extension is specified try to open the file both ways

	    ifnoerr (im = immap (Memc[fname], READ_ONLY, NULL)) {
		image = YES
		call imunmap (im)

	    } else ifnoerr (tp = tbtopn (Memc[fname], READ_ONLY, NULL)) {
		image = NO
		call tbtclo (tp)

	    } else {
		image = ERR
	    }
	}

	call sfree (sp)
	return (image)
end
