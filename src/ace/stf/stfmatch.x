include	<math.h>
include	"starfocus.h"


# STF_MATCH -- Simple minimum separation match.
#
# This is very primitive in that not chaining and updating is done.
# Once one object matches another then its match will not change.
# A match results in setting the star ID to the same value.

procedure stf_match (sfds, nsfd, sep)

pointer	sfds				#I Array of object structures
int	nsfd				#I Number of objects structures
real	sep				#I Maximum separation (arcsec|-pix)

int	s1, s2, id
double	sep2, sep3, r1, d1, r2, d2
pointer	sfd1, sfd2

double	slDSEP()
int	deccmp(), ycmp(), stf_focsort()
extern	deccmp, ycmp, stf_focsort

begin
	if (IS_INDEFR(sep))
	    return

	# Reset the IDs.
	do s1 = 0, nsfd-1
	    SFD_ID(Memi[sfds+s1]) = INDEFI

	if (sep > 0.) {
	    # Sort.
	    call gqsort (Memi[sfds], nsfd, deccmp, NULL)

	    # Set separation.
	    sep2 = DEGTORAD (sep / 3600.)

	    # Go through all objects.
	    id = 0
	    for (s1=0; s1<nsfd; s1=s1+1) {
		sfd1 = Memi[sfds+s1]
		if (!IS_INDEFI(SFD_ID(sfd1)))
		    next
		#id = id + 1
		id = sfd1
		SFD_ID(sfd1) = id

		if (IS_INDEFD(SFD_RA(sfd1)) || IS_INDEFD(SFD_DEC(sfd1)))
		    next
		r1 = DEGTORAD (SFD_RA(sfd1) * 15)
		d1 = DEGTORAD (SFD_DEC(sfd1))
		for (s2=s1+1; s2<nsfd; s2=s2+1) {
		    sfd2 = Memi[sfds+s2]
		    if (IS_INDEFD(SFD_RA(sfd1)) || IS_INDEFD(SFD_DEC(sfd1)))
			break
		    d2 = DEGTORAD (SFD_DEC(sfd2))
		    if (d2 - d1 > sep2)
			break
		    if (!IS_INDEFI(SFD_ID(sfd2)))
			next
		    r2 = DEGTORAD (SFD_RA(sfd2) * 15)
		    sep3 = slDSEP (r1, d1, r2, d2)
		    if (sep3 > sep2)
			next
		    SFD_ID(sfd2) = id
		}
	    }
	} else {
	    # Sort.
	    call gqsort (Memi[sfds], nsfd, ycmp, NULL)

	    # Set separation.
	    sep2 = sep * sep

	    # Go through all objects.
	    id = 0
	    for (s1=0; s1<nsfd; s1=s1+1) {
		sfd1 = Memi[sfds+s1]
		if (!IS_INDEFI(SFD_ID(sfd1)))
		    next
		#id = id + 1
		id = sfd1
		SFD_ID(sfd1) = id

		if (IS_INDEFD(SFD_X(sfd1)) || IS_INDEFD(SFD_Y(sfd1)))
		    next
		r1 = SFD_X(sfd1)
		d1 = SFD_Y(sfd1)
		for (s2=s1+1; s2<nsfd; s2=s2+1) {
		    sfd2 = Memi[sfds+s2]
		    if (IS_INDEFD(SFD_X(sfd1)) || IS_INDEFD(SFD_Y(sfd1)))
			break
		    d2 = (SFD_Y(sfd2) - d1) ** 2
		    if (d2 > sep2)
			break
		    if (!IS_INDEFI(SFD_ID(sfd2)))
			next
		    r2 = d2 + (SFD_X(sfd2) - r1) ** 2
		    if (r2 > sep2)
			next
		    SFD_ID(sfd2) = id
		}
	    }
	}

	# Sort by focus.
	call qsort (Memi[sfds], nsfd, stf_focsort)
end


# DECCMP -- Compare by DEC.

int procedure deccmp (dummy, sfd1, sfd2)

pointer	dummy				#I Dummy data
int	sfd1, sfd2			#I Structures to compare

double	d1, d2

begin
	d1 = SFD_DEC(sfd1)
	d2 = SFD_DEC(sfd2)

	if (IS_INDEFD(d2)) {
	    if (IS_INDEFD(d1))
	        return (0)
	    else
		return (-1)
	}
	if (IS_INDEFD(d1))
	    return (1)

	if (d1 < d2)
	    return (-1)
	else if (d1 > d2)
	    return (1)
	else
	    return (0)
end


# YCMP -- Compare by Y.

int procedure ycmp (dummy, sfd1, sfd2)

pointer	dummy				#I Dummy data
int	sfd1, sfd2			#I Structures to compare

double	d1, d2

begin
	d1 = SFD_Y(sfd1)
	d2 = SFD_Y(sfd2)

	if (IS_INDEFD(d2)) {
	    if (IS_INDEFD(d1))
	        return (0)
	    else
		return (-1)
	}
	if (IS_INDEFD(d1))
	    return (1)

	if (d1 < d2)
	    return (-1)
	else if (d1 > d2)
	    return (1)
	else
	    return (0)
end
