function __fish_complete_brazil_targets -d "Print list of targets from build.xml and imported files"
	set -l buildfile "build.xml"
  set -l configfile "Config"
	if test -f $buildfile
		# show ant targets
		__fish_filter_ant_targets $buildfile

		# find files with buildfile
		set files (sed -n "s/^.*<import[^>]* file=[\"']\([^\"']*\)[\"'].*\$/\1/p" < $buildfile)

		# iterate through files and display their targets
    set -l happytrailsroot (pwd | sed -e 's|/src.*$||')/env/(cat $configfile | grep HappierTrails | sed -e 's|^[^a-zA-Z]\+||' -e 's/[ \t]*=[ \t]*/-/' -e 's/;.*$//')/runtime
		for file in $files;
			__fish_filter_ant_targets (echo $file | sed -e "s|\\\${happytrails.root}|$happytrailsroot|")
		end
	end
end
