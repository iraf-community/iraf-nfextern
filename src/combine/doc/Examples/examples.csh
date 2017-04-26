#

@ seqnum = 120
@ mjd1 = 58323
@ mjd2 = 1234

# Darks
foreach det (demo)
foreach exptime (10)
foreach obstype ("dark dark")
foreach filter ("DARK")
foreach i (1 2 3)
@ mjd2 = $mjd2 + 1
echo $det $obstype $seqnum ${mjd1}.${mjd2} $exptime
echo $filter
end
@ seqnum++
@ mjd2 = $mjd2 + 40
end
end
end
end

# Dome flats
foreach det (demo)
foreach exptime (10 15)
foreach obstype ("flat dome")
foreach filter ("V #123" "R #124")
foreach i (1 2 3)
@ mjd2 = $mjd2 + 1
echo $det $obstype $seqnum ${mjd1}.${mjd2} $exptime
echo $filter
end
@ seqnum++
@ mjd2 = $mjd2 + 40
end
end
end
end

# Sky flats
foreach det (demo)
foreach exptime (10 15)
foreach obstype ("flat sky")
foreach filter ("V #123" "R #124")
foreach i (1 2 3)
@ mjd2 = $mjd2 + 1
echo $det $obstype $seqnum ${mjd1}.${mjd2} $exptime
echo $filter
end
@ seqnum++
@ mjd2 = $mjd2 + 40
end
end
end
end

# Objects
foreach det (demo)
foreach exptime (300)
foreach obstype ("object program")
foreach filter ("V #123" "R #124")
foreach i (1 2 3)
@ mjd2 = $mjd2 + 1
echo $det $obstype $seqnum ${mjd1}.${mjd2} $exptime
echo $filter
end
@ seqnum++
@ mjd2 = $mjd2 + 40
end
end
end
end
