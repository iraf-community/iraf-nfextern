procedure demo ()

file	fname = "home$demo.dat"		{prompt="Demo file"}
string	dmprompt = "cl>"		{prompt="Demo prompt"}
bool	dmpause = yes			{prompt="Demo pause?"}
bool	dmexecute = yes			{prompt="Demo execute?"}
int	dmdelay = 0			{prompt="Demo delay (sec)"}
struct	*fd

begin
	string	prompt = "cl>"
	bool	echo = yes
	bool	pause = yes
	int	delay = 1
	bool	execute = yes
	bool	comment_echo = yes
	bool	comment_pause = no
	int	comment_delay = 0
	bool	blank_echo = yes 

	file	f
	bool	pse, cpse
	string	str1, exe, curpack
	struct	inline, str

	# Set parameters.
	f = fname
	prompt = dmprompt
	pause = dmpause
	execute = dmexecute
	delay = dmdelay

	# Check demo file.
	if (!access(f)) {
	    printf ("Demo file not found (%s)\n", f) | scan (str)
	    error (1, str)
	}

	# Execute the demo commands.
	fd = f
	while (fscan (fd, inline) != EOF) {
	    if (fscan (inline, str1, str) < 1) {
		if (blank_echo)
		    printf ("%s\n", inline)
		next
	    }

	    pse = pause
	    cpse = comment_pause
	    exe = execute

	    if (str1 == "") {
	        if (blank_echo)
		    printf ("%s\n", inline)
	    } else if (substr(str1,1,3) == "###")
	        ;
	    else if (substr(str1,1,2) == "##") {
	        if (substr(str1,3,3) == "-")
		    pse = no
		else if (substr(str1,3,3) == "+")
		    pse = yes

		inline = str
		if (fscan (inline, str1, str) == 0)
		    next
		if (str1 == "set")
		    printf ("demo.%s\n", str) | cl
		else if (str1 == "package") {
		    if (echo) {
			printf ("%s %s", prompt, str)
			if (pse) {
			    exe = ukey
			    printf ("\n")
			    if (exe == "q")
			        return
			} else {
			    printf ("\n")
			    sleep (delay)
			}
		    }
		    if (exe == "q")
		        return
		    if (exe != "n" && exe != "no") {
			printf ("%s\n?\nkeep\n", str) | cl
			curpack = str
			prompt = curpack // ">"
		    }
		} else if (str1 == "help" || str1 == "phelp") {
		    if (echo) {
			printf ("%s %s", prompt, inline)
			if (pse) {
			    exe = ukey
			    printf ("\n")
			} else {
			    printf ("\n")
			    sleep (delay)
			}
		    }
		    if (exe == "q")
		        return
		    if (exe != "n" && exe != "no")
			printf ("%s\n%s\n", curpack, inline) | cl
		} else {
		    if (echo) {
			printf ("%s %s", prompt, inline)
			if (pse) {
			    exe = ukey
			    printf ("\n")
			} else {
			    printf ("\n")
			    sleep (delay)
			}
		    }
		    if (exe == "q")
		        return
		    if (exe != "n" && exe != "no")
			printf ("%s\n", inline) | cl
		}
	    } else if (str1 == "#") {
	        if (substr(str1,2,2) == "-")
		    cpse = no
		else if (substr(str1,2,2) == "+")
		    cpse = yes

		if (comment_echo) {
		    printf ("%s", inline)
		    if (cpse) {
			exe = ukey
			printf ("\n")
		    } else  {
			printf ("\n")
			sleep (comment_delay)
		    }
		    if (exe == "q")
		        return
		}
	    } else {
		if (echo) {
		    printf ("%s %s", prompt, inline)
		    if (pause) {
			exe = ukey
			printf ("\n")
		    } else {
			printf ("\n")
			sleep (delay)
		    }
		}
		if (exe == "q")
		    return
		if (exe != "n" && exe != "no")
		    printf ("%s\n", inline) | cl
	    }
	}
	fd = ""
end
