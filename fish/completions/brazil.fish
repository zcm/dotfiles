function __brazil_resolve_alias
  if [ $argv[1] = 'ws' ]; echo 'workspace'
  else if [ $argv[1] = 'vs' ]; echo 'versionset'
  else if [ $argv[1] = 's3' ]; echo 's3Binary'
  else if [ $argv[1] = 'pb' ]; echo 'packagebuilder'
  else if [ $argv[1] = 'mv' ]; echo 'majorversion'
  else if [ $argv[1] = 'pkg' ]; echo 'package'
  else; echo $argv[1]; end
end

function __brazil_nc1 # "Needs command" -- shortened for performance
  set cmd (commandline -opc)
  if [ (count $cmd) -eq 1 ]
    return 0
  end
  return 1
end

function __brazil_nc2
  set cmd (commandline -opc)
  if [ (count $cmd) -eq 2 ]
    if [ (__brazil_resolve_alias $cmd[2]) = $argv[1] ]
      return 0
    end
  end
  return 1
end

function __brazil_nc3
  set cmd (commandline -opc)
  if [ (count $cmd) -eq 3 ]
    if [ (__brazil_resolve_alias $cmd[2]) = $argv[1] -a (__brazil_resolve_alias $cmd[3]) = $argv[2] ]
      return 0
    end
  end
  return 1
end

function __brazil_uc # "Using command" -- shortened for performance also
  set cmd (commandline -opc)
  if [ (count $cmd) -lt 3 ]
    return 1
  end
  if [ -z "$cmd[2]" -o -z "$cmd[3]" ]
    return 1
  end
  if [ $argv[1] != (__brazil_resolve_alias $cmd[2]) -o \( $argv[2] != $cmd[3] -a "--$argv[2]" != $cmd[3] \) ]
    return 1
  end
  return 0
end

function __brazil_ex # "Excludes" -- false when specified parameters are in $argv
  set cmd (commandline -opc)
  for x in $argv
    if contains -- $x $cmd
      return 1
    end
  end
  return 0
end

function __brazil_only # Only when the option(s) are present
  set cmd (commandline -opc)
  for x in $argv
    if not contains -- $x $cmd
      return 1
    end
  end
  return 0
end

function __brazil_any # Only when any of the option(s) are present
  set cmd (commandline -opc)
  for x in $argv
    if contains -- $x $cmd
      return 0
    end
  end
  return 1
end

function __brazil_last_only
  set cmd (commandline -opc)
  set ncmd (count $cmd)
  [ $cmd[$ncmd] = $argv[1] ]
  return $status
end

function __brazil_last_any
  set cmd (commandline -opc)
  set ncmd (count $cmd)
  for x in $argv
    if [ $cmd[$ncmd] = $x ]
      return 0
    end
  end
  return 1
end

function __brazil_once_per
  set cmd (commandline -opc)
  set plusidx 0
  for i in (seq (count $argv))
    echo "i = $i"
    if [ "$argv[$i]" = '+' ]
      set plusidx $i
    end
  end
  set cmdstart (math $plusidx+1)
  for c in $cmd[-1..1]
    for x in $argv[1..$plusidx]
      if [ $c = $x ]
        return 1
      end
    end
    for x in $argv[$cmdstart..-1]
      if [ $c = $x ]
        return 0
      end
    end
  end
  return 1
end

function __brazil_nd # "Not dash"
  not echo (commandline -ct) | grep -q -e '^-'
  return $status
end

function __brazil_complete
  if [ "$argv[1]" = '+COMPILE' ]
    echo 'complete' (echo \"$argv[2..-1]\" | sed -e 's/"\([-_a-zA-Z0-9]\+\)"/\1/g')
  else
    complete $argv[2..-1]
  end
end

function __brazil_complete_arg_vars
  __brazil_complete $argv[1] -c brazil -A -x -n "__brazil_uc $argv[2..3]; and __brazil_nd; and not __brazil_last_any $argv[4..-1]" -a "$argv[4..-1]"
end

function __brazil_complete_arg_vars_skipfirst
  __brazil_complete $argv[1] -c brazil -A -x -n "__brazil_uc $argv[2..3]; and __brazil_nd; and not __brazil_last_any $argv[5..-1]" -a "$argv[4..-1]"
end

function __brazil_complete_arg_vars_single
  __brazil_complete $argv[1] -c brazil -A -x -n "__brazil_uc $argv[2..3]; and __brazil_nd; and __brazil_ex $argv[4..-1]; and not __brazil_last_any $argv[4..-1]" -a "$argv[4]"
end

function __brazil_complete_help1
  set resolved (__brazil_resolve_alias $argv[2])
  __brazil_complete $argv[1] -c brazil -x -n '__brazil_nc2 help' -a "$argv[2]" --description "Help for \"$resolved\" command"
end

function __brazil_complete_help2
  __brazil_complete $argv[1] -c brazil -x -n "__brazil_nc3 help $argv[2]" -a "$argv[3]" --description "Help for $argv[2] \"$argv[3]\" action"
end

function __brazil_complete_action
  __brazil_complete $argv[1] -c brazil -f -n "__brazil_nc2 $argv[2]" -a "$argv[3]" --description "$argv[4]"
  __brazil_complete $argv[1] -c brazil -f -n "__brazil_nc2 $argv[2]" -l "$argv[3]" --description "$argv[4]"
  __brazil_complete_help2 $argv[1] $argv[2] $argv[3]
end

function __brazil_complete_action_opt_compile
  set cmd $argv[1]
  set act $argv[2]
  set long $argv[3]
  set short
  set arglist
  set desc
  set has_A 1
  set has_f 1
  set has_x 1
  set has_r 1
  set has_a 1
  set has_ac 1
  set has_excludes 1
  set has_only 1
  set has_any 1
  set has_lastonly 1
  set has_lastany 1
  set has_onceper 1
  set token 0
  set token_exclude 1
  set token_short 2
  set token_desc 3
  set token_only 4
  set token_any 5
  set token_lastonly 6
  set token_lastany 7
  set token_a 8
  set token_ac 9
  set token_onceper 10
  set seen_once 1
  set seen_short 1
  set excludes
  set onlys
  set anys
  set lastonlys
  set lastanys
  set oncepers
  for arg in $argv[4..-1]
    switch $arg
      case +once
        if [ $seen_once -eq 0 ]
          echo "$cmd $act: error: Cannot have multiple +once options" >&2
        else
          set seen_once 0
          set has_excludes 0
          if [ $seen_short -eq 0 ]
            set excludes "--$long" "-$short" $excludes
          else
            set excludes "--$long" $excludes
          end
        end
      case +ex
        set token 1
      case +short
        set token 2
      case +desc
        set token 3
      case +A
        set has_A 0
      case +f
        set has_f 0
      case +x
        set has_x 0
      case +r
        set has_r 0
      case +only
        set token 4
      case +any
        set token 5
      case +lastonly
        set token 6
      case +lastany
        set token 7
      case +a
        set token 8
      case +ac
        set token 9
      case +onceper
        set token 10
      case '*'
        switch $token
          case 1
            set has_excludes 0
            set excludes $excludes $arg
          case 2
            if [ $seen_once -eq 0 ]
              echo "$cmd $act: error: +short must be before +once" >&2
            end
            set seen_short 0
            set short $short $arg
          case 3
            set desc $arg
          case 4
            set has_only 0
            set onlys $onlys $arg
          case 5
            set has_any 0
            set anys $anys $arg
          case 6
            set has_lastonly 0
            set lastonlys $lastonlys $arg
          case 7
            set has_lastany 0
            set lastanys $lastanys $arg
          case 8
            set arglist $arg
            set has_a 0
          case 9
            set arglist $arg
            set has_ac 0
          case 10
            set has_onceper 0
            set oncepers $oncepers $arg
        end
    end
  end
  set conds "__brazil_uc $cmd $act"
  if [ $has_excludes -eq 0 ]
    set conds "$conds; and __brazil_ex $excludes"
  end
  if [ $has_only -eq 0 ]
    set conds "$conds; and __brazil_only $onlys"
  end
  if [ $has_any -eq 0 ]
    set conds "$conds; and __brazil_any $anys"
  end
  if [ $has_lastonly -eq 0 ]
    set conds "$conds; and __brazil_last_only $lastonlys"
  end
  if [ $has_lastany -eq 0 ]
    set conds "$conds; and __brazil_last_any $lastanys"
  end
  if [ $has_onceper -eq 0 ]
    set conds "$conds; and __brazil_once_per --$long"
    if [ $seen_short -eq 0 ]
      set conds "$conds" -$short
    end
    set non_ex_oncepers
    for x in $oncepers
      if [ (echo $x | cut -c 1-3) = 'ex:' ]
        set conds $conds (echo $x | cut -c 1-3 --complement)
      else
        set non_ex_oncepers $non_ex_oncepers $x
      end
    end
    set conds "$conds + $non_ex_oncepers"
  end
  set params -c brazil
  if [ "$argv[3]" = '+a' ]
    set has_a 0
    set arglist $argv[4]
  else if [ "$argv[3]" = '+ac' ]
    set has_ac 0
    set arglist $argv[4]
  else
    set params $params -l $long
  end
  if [ $has_a -eq 0 ]
    set params $params "-a \"$arglist\""
  else if [ $has_ac -eq 0 ]
    set params $params "-a \"($conds; and $arglist)\""
  end
  if [ $seen_short -eq 0 ]
    set params $params -o $short
  end
  if [ $has_A -eq 0 ]
    set params $params -A
  end
  if [ $has_f -eq 0 ]
    set params $params -f
  end
  if [ $has_x -eq 0 ]
    set params $params -x
  end
  if [ $has_r -eq 0 ]
    set params $params -r
  end
  echo complete $params -d "\"$desc\"" -n "\"$conds\""
end

function __brazil_complete_action_opt
  if [ "$argv[1]" = '+COMPILE' ]
    __brazil_complete_action_opt_compile $argv[2..-1]
  else
    eval (__brazil_complete_action_opt_compile $argv[2..-1])
  end
end

function __brazil_complete_action_opt_packages
  __brazil_complete_action_opt $argv[1] $argv[2] $argv[3] +ac "__amazon_complete_packages" +desc 'Brazil package' +x $argv[4..-1]
end

function __brazil_complete_action_opt_versionsets
  __brazil_complete_action_opt $argv[1] $argv[2] $argv[3] +ac '__amazon_complete_version_sets' +desc 'Version set' +x $argv[4..-1]
end

function __brazil_completions
  set all_flavors DEV.STD.PTHREAD RLS.STD.PTHREAD PROF.STD.PTHREAD DEBUG.STD.PTHREAD
  set all_platforms X86_LINUX_GCC_GLIBC23 RHEL4 RHEL4_64 RHEL5 RHEL5_64
  set all_deptypes runtime legacy targets_only
  set all_sorts topo reversetopo alpha

  set compile '+NOCOMPILE'
  if [ "$argv[1]" = '--compile' ]
    set compile '+COMPILE'
    functions __brazil_resolve_alias __brazil_nc1 __brazil_nc2 __brazil_nc3 __brazil_uc __brazil_ex __brazil_only __brazil_any __brazil_last_only __brazil_last_any __brazil_once_per __brazil_nd
    echo ''
  end

  __brazil_complete $compile -c brazil -f
  __brazil_complete $compile -c brazil -f -n '__brazil_nc1' -a 'workspace' --description 'Configure workspace'
  __brazil_complete $compile -c brazil -f -n '__brazil_nc1' -a 'ws' --description 'Alias for "workspace"'
  __brazil_complete $compile -c brazil -f -n '__brazil_nc1' -a 'versionset' --description 'Manipulate version sets'
  __brazil_complete $compile -c brazil -f -n '__brazil_nc1' -a 'vs' --description 'Alias for "versionset"'
  __brazil_complete $compile -c brazil -f -n '__brazil_nc1' -a 's3Binary' --description 'S3Binary system for large files'
  __brazil_complete $compile -c brazil -f -n '__brazil_nc1' -a 's3' --description 'Alias for "s3Binary"'
  __brazil_complete $compile -c brazil -f -n '__brazil_nc1' -a 'packagebuilder' --description 'Handle build requests in Package Builder'
  __brazil_complete $compile -c brazil -f -n '__brazil_nc1' -a 'pb' --description 'Alias for "packagebuilder"'
  __brazil_complete $compile -c brazil -f -n '__brazil_nc1' -a 'majorversion' --description 'Modify package major versions'
  __brazil_complete $compile -c brazil -f -n '__brazil_nc1' -a 'mv' --description 'Alias for "majorversion"'
  __brazil_complete $compile -c brazil -A -x -n '__brazil_nc1' -a 'help' --description 'Help using brazil'
  __brazil_complete $compile -c brazil -f -n '__brazil_nc1' -a 'branch' --description 'Create and delete branches'

  for cmd in workspace ws versionset vs s3Binary s3 packagebuilder pb package pkg majorversion mv branch
    __brazil_complete_help1 $compile $cmd
  end

  __brazil_complete_action $compile workspace attachenvironment 'Attach an environment for override'
  __brazil_complete_action $compile workspace checkout 'Checkout a snapshot into the current workspace'
  __brazil_complete_action $compile workspace clean 'Remove all build artifacts from the workspace'
  __brazil_complete_action $compile workspace clone 'Make a new workspace based on a snapshot'
  __brazil_complete_action $compile workspace create 'Create a new workspace'
  __brazil_complete_action $compile workspace delete 'Delete an existing workspace'
  __brazil_complete_action $compile workspace detachenvironment 'Detach an environment for overrides'
  __brazil_complete_action $compile workspace dryrun 'Submit dry-run build of local code to PackageBuilder'
  __brazil_complete_action $compile workspace list 'Show the present status of the workspace'
  __brazil_complete_action $compile workspace merge 'Merge from the tracking versionset'
  __brazil_complete_action $compile workspace pull 'Pull all git packages in the workspace'
  __brazil_complete_action $compile workspace push 'Push all snapshotable packages to GitFarm'
  __brazil_complete_action $compile workspace remove 'Remove a package from an existing workspace'
  __brazil_complete_action $compile workspace show 'Display a summary of the current workspace'
  __brazil_complete_action $compile workspace snapshot 'Upload a snapshot of the workspace'
  __brazil_complete_action $compile workspace sync 'Sync metadata in an existing workspace'
  __brazil_complete_action $compile workspace transmogrify 'Run transmogrifier transforms on packages'
  __brazil_complete_action $compile workspace use 'Use a package or version set in an existing workspace'

  __brazil_complete_action $compile versionset addflavors 'Add flavors to a version set'
  __brazil_complete_action $compile versionset addplatforms 'Add platforms to a version set'
  __brazil_complete_action $compile versionset addtargets 'Mark existing package major version as target'
  __brazil_complete_action $compile versionset buildmissingpackageversions 'Build missing package versions'
  __brazil_complete_action $compile versionset clone 'Clone a version set'
  __brazil_complete_action $compile versionset create 'Create a version set'
  __brazil_complete_action $compile versionset deprecate 'Deprecate a version set'
  __brazil_complete_action $compile versionset extendexpiration 'Extend the expiration date of a version set'
  __brazil_complete_action $compile versionset history 'Display the revision history of a specified version set'
  __brazil_complete_action $compile versionset merge 'Merge package trees between version sets'
  __brazil_complete_action $compile versionset print 'Display a specified version set'
  __brazil_complete_action $compile versionset printdependencies 'Display dependencies of a package'
  __brazil_complete_action $compile versionset recreate 'Pull in latest versions of targets and all deps from parent'
  __brazil_complete_action $compile versionset removeflavors 'Remove flavors from a version set'
  __brazil_complete_action $compile versionset removeplatforms 'Remove platforms from a version set'
  __brazil_complete_action $compile versionset removetargets 'Remove a package major version as the target of a VS'
  __brazil_complete_action $compile versionset removeunusedpackages 'Check for unused packages with a version set'
  __brazil_complete_action $compile versionset revert 'Revert a version set to a previous revision'
  __brazil_complete_action $compile versionset revive 'Revive a deprecated or expired version set'
  __brazil_complete_action $compile versionset setvfidependencytype 'Set the VFI dependency type to use'

  __brazil_complete_action $compile s3Binary upload 'Upload a file to s3'
  __brazil_complete_action $compile s3Binary download 'Download a file from S3'
  __brazil_complete_action $compile s3Binary history 'List revisions of a key in S3'

  __brazil_complete_action $compile branch list 'List branches of a package known to Brazil'

  __brazil_complete_action $compile packagebuilder build 'Submit a build request to PackageBuilder'
  __brazil_complete_action $compile packagebuilder delete 'Delete a build request in PackageBuilder'
  __brazil_complete_action $compile packagebuilder view 'View the current status of PackageBuilder build request'

  __brazil_complete_action $compile majorversion removefromlive "Remove major versions from the 'live' version set"
  __brazil_complete_action $compile majorversion setmasterversionset "Set a package major version's master version set"

  __brazil_complete_arg_vars $compile workspace use --version -v --branch -b --versionset -vs --package -p --root -r --eventId -eid --cln --layout --majorversion
  __brazil_complete_action_opt $compile workspace use 'latestVersion' +desc 'Use highest version of packages in the active version set' +once +f
  __brazil_complete_action_opt $compile workspace use 'version' +short 'v' +desc 'Version of specified package to use' +once +f #:Brazil package version:_complete_package_versions
  __brazil_complete_action_opt $compile workspace use 'branch' +short 'b' +desc 'Name of branch to use' +once +f #:Brazil package branch:_complete_package_branches
  __brazil_complete_action_opt $compile workspace use 'versionset' +short 'vs' +desc 'Name of version set to use' +once +f
  __brazil_complete_action_opt_versionsets $compile workspace use +lastany --versionset -vs
  __brazil_complete_action_opt $compile workspace use 'package' +short 'p' +desc 'Name of package to use' +f
  __brazil_complete_action_opt_packages $compile workspace use +lastany --package -p
  __brazil_complete_action_opt $compile workspace use 'root' +short 'r' +desc 'Root of workspace to use' +once +f #:directory:_dirs
  __brazil_complete_action_opt $compile workspace use 'eventId' +short 'eid' +desc 'eventId at which to use the specified version set' +once +f
  __brazil_complete_action_opt $compile workspace use 'cln' +desc 'Change level [git: sha1, p4: cln, svn: revision]' +once +f
  __brazil_complete_action_opt $compile workspace use 'layout' +desc 'Layout to use' +once +f #:layout:_complete_brazil_layouts
  __brazil_complete_action_opt $compile workspace use 'gitMode' +desc 'Checkout as git repository' +once +f +ex --nogitMode
  __brazil_complete_action_opt $compile workspace use 'nogitMode' +desc 'Do not checkout as git repository' +once +f +ex --gitMode
  __brazil_complete_action_opt $compile workspace use 'readOnly' +desc 'Pull source from cache without hitting Perforce' +once +f
  __brazil_complete_action_opt $compile workspace use 'force' +short 'f' +desc "Remove package's local repository without prompting" +once +f
  __brazil_complete_action_opt $compile workspace use 'majorversion' +desc 'Use current Y.Z version of the specified package' +once +f

  __brazil_complete_arg_vars $compile workspace sync --metadata -md --timestamp -ts --root -r --eventId -eid
  __brazil_complete_action_opt $compile workspace sync 'source' +desc 'Explicitly sync source' +once +f
  __brazil_complete_action_opt $compile workspace sync 'metadata' +short 'md' +desc 'Explicity sync metadata' +once +f
  __brazil_complete_action_opt $compile workspace sync 'eventId' +short 'eid' +desc 'eventId at which to sync' +once +f +ex --timestamp -ts
  __brazil_complete_action_opt $compile workspace sync 'timestamp' +short 'ts' +desc 'Timestamp at which to sync' +once +f +ex --eventId -eid
  __brazil_complete_action_opt $compile workspace sync 'root' +short 'r' +desc 'Root of workspace to use' +once +f #:directory:_dirs
  __brazil_complete_action_opt $compile workspace sync 'makeSupport' +desc 'Explicitly sync make-support files' +once +f

  __brazil_complete_arg_vars $compile workspace remove --package -p --root -r
  __brazil_complete_action_opt $compile workspace remove 'package' +short 'p' +desc 'Name of the package to remove'
  # TODO(zmurray): It would be nice for remove to complete only those packages actually IN your workspace.
  __brazil_complete_action_opt_packages $compile workspace remove +lastany --package -p
  __brazil_complete_action_opt $compile workspace remove 'root' +short 'r' +desc 'Root of workspace to use' +once +f #:directory:_dirs
  __brazil_complete_action_opt $compile workspace remove 'force' +short 'f' +desc "Remove package's local repository without prompting" +once +f

  __brazil_complete_arg_vars_single $compile workspace show --root -r
  __brazil_complete_action_opt $compile workspace show 'root' +short 'r' +desc 'Root of workspace to use' +once +f #:directory:_dirs

  __brazil_complete_arg_vars $compile workspace create --versionset -vs --root -r --name -n --eventId -eid
  __brazil_complete_action_opt $compile workspace create 'versionset' +short 'vs' +desc 'Version set to use' +once +f
  __brazil_complete_action_opt_versionsets $compile workspace create +lastany --versionset -vs
  __brazil_complete_action_opt $compile workspace create 'root' +short 'r' +desc 'Root of new workspace' +once +f #:Root path:_path_files -/
  __brazil_complete_action_opt $compile workspace create 'name' +short 'n' +desc 'Name of new workspace' +once +f #:Workspace name: 
  __brazil_complete_action_opt $compile workspace create 'eventId' +short 'eid' +desc 'eventId at which to sync' +once +f #:Workspace name: 

  __brazil_complete_arg_vars_single $compile workspace clean --root -r
  __brazil_complete_action_opt $compile workspace clean 'root' +short 'r' +desc 'Root of workspace to use' +once +f #:directory:_dirs

  __brazil_complete_arg_vars $compile workspace detachenvironment --root -r --alias
  __brazil_complete_action_opt $compile workspace detachenvironment 'root' +short 'r' +desc 'Root of workspace to use' +once +f #:directory:_dirs
  __brazil_complete_action_opt $compile workspace detachenvironment 'alias' +desc 'Apollo environment alias to detach' +once +f #:environment name:_complete_local_environments

  __brazil_complete_arg_vars $compile workspace attachenvironment --root -r --alias
  __brazil_complete_action_opt $compile workspace attachenvironment 'root' +short 'r' +desc 'Root of workspace to use' +once +f #:directory:_dirs
  __brazil_complete_action_opt $compile workspace attachenvironment 'alias' +desc 'Apollo environment alias to attach' +once +f #:environment name:_complete_local_environments

  __brazil_complete_arg_vars $compile workspace dryrun --package -p --description -d --root -r --compute-profile
  __brazil_complete_action_opt $compile workspace dryrun 'package' +short 'p' +desc 'Name of specific packages to build' +f
  __brazil_complete_action_opt_packages $compile workspace dryrun +lastany --package -p
  __brazil_complete_action_opt $compile workspace dryrun 'description' +short 'd' +desc 'Description of the changes in the dry run' +once +f +desc #:message: 
  __brazil_complete_action_opt $compile workspace dryrun 'root' +short 'r' +desc 'Root of workspace to use' +once +f #:directory:_dirs
  __brazil_complete_action_opt $compile workspace dryrun 'unoptimized' +short 'unopt' +desc 'Rebuild all consumer packages' +once +f +ex --rebuild-package-only -z
  __brazil_complete_action_opt $compile workspace dryrun 'git-head' +desc 'Rebuild all consumer packages' +once +f +ex --git-head
  __brazil_complete_action_opt $compile workspace dryrun 'compute-profile' +desc 'Rebuild all consumer packages' +once +f +ex --compute-profile
  __brazil_complete_action_opt $compile workspace dryrun 'rebuild-package-only' +short 'z' +desc 'Rebuild all consumer packages' +once +f +ex --rebuild-package-only -z --unoptimized -unopt

  __brazil_complete_arg_vars $compile workspace merge --newPackageMV -np --root -r --packageMissingDependencies -p
  __brazil_complete_action_opt $compile workspace merge 'newPackageMV' +short 'np' +desc 'Name of new major version to add to version set' +f
  __brazil_complete_action_opt $compile workspace merge 'root' +short 'r' +desc 'Root of workspace to use' +once +f
  __brazil_complete_action_opt $compile workspace merge 'async' +desc 'Do not wait for the dry-run build request to complete' +once +ex '--noAsync' +f
  __brazil_complete_action_opt $compile workspace merge 'noAsync' +desc 'Wait for the dry-run build request to complete' +once +ex '--async' +f
  __brazil_complete_action_opt $compile workspace merge 'clean' +desc 'Abort in-progress merge and remove existing merges' +once +f
  __brazil_complete_action_opt $compile workspace merge 'continue' +desc 'Continue in-progress merge in foreground' +once +f
  __brazil_complete_action_opt $compile workspace merge 'tip' +desc 'Merge from the tip of the tracking version set' +once +f
  __brazil_complete_action_opt $compile workspace merge 'lastMergeSource' +short 'lms' +desc 'Merge from last merged version set' +once +f
  __brazil_complete_action_opt $compile workspace merge 'findMissingDependencies' +short 'fmd' +desc 'Scan workspace for missing dependencies in version set' +once +f
  __brazil_complete_action_opt $compile workspace merge 'packageMissingDependencies' +short 'p' +desc 'Name of package with missing dependencies to merge' +once +f
  __brazil_complete_action_opt $compile workspace merge 'abort' +desc 'Abort an in-progress merge' +once +f
  __brazil_complete_action_opt $compile workspace merge 'newMerge' +desc 'Run the merge as if no local merges exist' +once +ex '--noNewMerge' +f
  __brazil_complete_action_opt $compile workspace merge 'noNewMerge' +desc "Don't run the merge as if no local merges exist" +once +ex '--newMerge' +f
  __brazil_complete_action_opt $compile workspace merge 'notDryRun' +short 'ndr' +desc 'Make changes to your version set' +once +f
  __brazil_complete_action_opt $compile workspace merge 'importVfi' +desc 'Import VFI for non-dry-run merge' +once +f

  __brazil_complete_arg_vars $compile workspace transmogrify --package -p --root -r --label -l
  __brazil_complete_action_opt $compile workspace transmogrify 'root' +short 'r' +desc 'Root folder in a workspace on which to operate' +once +f
  __brazil_complete_action_opt $compile workspace transmogrify 'package' +short 'p' +desc 'Package to be transformed' +once +f
  __brazil_complete_action_opt_packages $compile workspace transmogrify +lastany --package -p
  __brazil_complete_action_opt $compile workspace transmogrify 'label' +short 'l' +desc 'Label of the transform to be applied' +once +f

  __brazil_complete_arg_vars_single $compile workspace pull --rebase
  __brazil_complete_action_opt $compile workspace pull 'rebase' +desc "Rebase local changes like 'git pull --rebase'" +once +f

  __brazil_complete_arg_vars $compile workspace list --include --exclude
  __brazil_complete_action_opt $compile workspace list 'include' +desc 'Comma-separated list of packages to include' +once +f
  __brazil_complete_action_opt_packages $compile workspace list +lastonly --include
  __brazil_complete_action_opt $compile workspace list 'exclude' +desc 'Comma-separated list of packages to exclude' +once +f
  __brazil_complete_action_opt_packages $compile workspace list +lastonly --exclude
  __brazil_complete_action_opt $compile workspace list 'pull' +desc 'Pull changes before doing anything' +once +f

  __brazil_complete_arg_vars $compile workspace snapshot --include --exclude
  __brazil_complete_action_opt $compile workspace snapshot 'include' +desc 'Comma-separated list of packages to include' +once +f
  __brazil_complete_action_opt $compile workspace snapshot 'exclude' +desc 'Comma-separated list of packages to exclude' +once +f
  __brazil_complete_action_opt $compile workspace snapshot 'pull' +desc 'Pull changes before doing anything' +once +f

  __brazil_complete_arg_vars $compile workspace push --include --exclude
  __brazil_complete_action_opt $compile workspace push 'include' +desc 'Comma-separated list of packages to include' +once +f
  __brazil_complete_action_opt $compile workspace push 'exclude' +desc 'Comma-separated list of packages to exclude' +once +f
  __brazil_complete_action_opt $compile workspace push 'pull' +desc 'Pull changes before doing anything' +once +f
  __brazil_complete_action_opt $compile workspace push 'tags' +desc 'Push all local tags along with the content' +once +f

  # Both $compile 'workspace clone' and 'workspace checkout' take only a single, unnamed parameter. (Thanks for the consistency, Brazil.)

  __brazil_complete_arg_vars $compile versionset addflavors --flavors -f --versionset -vs
  __brazil_complete_action_opt $compile versionset addflavors 'flavors' +short 'f' +desc 'Comma-separated list of flavors to add' +once +f
  __brazil_complete_action_opt $compile versionset addflavors +a "$all_flavors" +desc 'Flavor' +lastany --flavors -f +f
  __brazil_complete_action_opt $compile versionset addflavors 'versionset' +short 'vs' +desc 'Version set name' +once +f
  __brazil_complete_action_opt_versionsets $compile versionset addflavors +lastany --versionset -vs

  __brazil_complete_arg_vars $compile versionset addplatforms --platforms -p --versionset -vs
  __brazil_complete_action_opt $compile versionset addplatforms 'platforms' +short 'p' +once +f +desc 'Comma-separated list of platforms to add'
  __brazil_complete_action_opt $compile versionset addplatforms +a "$all_platforms" +desc 'Platform' +lastany --platforms -p +f
  __brazil_complete_action_opt $compile versionset addplatforms 'versionset' +short 'vs' +desc 'Version set name' +once +f
  __brazil_complete_action_opt_versionsets $compile versionset addplatforms +lastany --versionset -vs

  __brazil_complete_arg_vars $compile versionset addtargets -packages -p --versionset -vs
  __brazil_complete_action_opt $compile versionset addtargets 'packages' +short 'p' +once +f +desc 'Comma-separated list of packages to make targets' #:Brazil package version:_complete_package_versions
  __brazil_complete_action_opt_packages $compile versionset addtargets +lastany --package -p
  __brazil_complete_action_opt $compile versionset addtargets 'versionset' +short 'vs' +desc 'Version set name' +once +f
  __brazil_complete_action_opt_versionsets $compile versionset addtargets +lastany --versionset -vs

  __brazil_complete_arg_vars_single $compile versionset buildmissingpackageversions --versionset -vs
  __brazil_complete_action_opt $compile versionset buildmissingpackageversions 'versionset' +short 'vs' +desc 'Version set name' +once +f
  __brazil_complete_action_opt_versionsets $compile versionset buildmissingpackageversions +lastany --versionset -vs

  __brazil_complete_arg_vars $compile versionset clone -ts -rev -eid --timestamp --revision --eventId --from --p4group --to --owner --mailingList
  __brazil_complete_action_opt $compile versionset clone 'timestamp' +short 'ts' +desc 'Time to clone from' +once +f +ex --eventId --revision -eid -rev
  __brazil_complete_action_opt $compile versionset clone 'revision' +short 'rev' +desc 'Revision to clone from' +once +f +ex --eventId --timestamp -eid -ts
  __brazil_complete_action_opt $compile versionset clone 'eventId' +short 'eid' +desc 'eventId to clone from' +once +f +ex --revision --timestamp -rev -ts
  __brazil_complete_action_opt $compile versionset clone 'from' +desc 'Name of the source version set' +once +f
  __brazil_complete_action_opt_versionsets $compile versionset clone +lastonly --from
  __brazil_complete_action_opt $compile versionset clone 'p4group' +desc 'p4group owner of the version set group' +once +f #:perforce group:_perforce_groups
  __brazil_complete_action_opt $compile versionset clone 'to' +desc 'Name of the destination version set' +once +f
  __brazil_complete_action_opt_versionsets $compile versionset clone +lastonly --to
  __brazil_complete_action_opt $compile versionset clone 'overwrite' +desc 'Overwrite destination if it already exists' +once +f +ex --noOverwrite
  __brazil_complete_action_opt $compile versionset clone 'noOverwrite' +desc 'Do not overwrite destination if it exists' +once +f +ex --overwrite
  __brazil_complete_action_opt $compile versionset clone 'owner' +desc 'Owner for newly created version set groups' +once +f
  __brazil_complete_action_opt $compile versionset clone 'mailingList' +desc 'Mailing list for newly created version set groups' +once +f
  __brazil_complete_action_opt $compile versionset clone 'buildMissing' +desc 'Rebuild deprecated packages' +once +f +ex --noBuildMissing
  __brazil_complete_action_opt $compile versionset clone 'noBuildMissing' +desc 'Do not rebuild deprecated packages' +once +f +ex --buildMissing

  __brazil_complete_arg_vars $compile versionset create -eid -vs --eventId --flavors --from --owner --mailingList --p4Group --platforms --targets --versionset --vfiDependencyType --additionalMajorVersions
  __brazil_complete_action_opt $compile versionset create 'eventId' +short 'eid' +desc 'eventId to create from' +once +f
  __brazil_complete_action_opt $compile versionset create 'flavors' +desc 'Comma-separated list of flavors' +once +f
  __brazil_complete_action_opt $compile versionset create +a "$all_flavors" +desc 'Flavor' +lastonly --flavors +f
  __brazil_complete_action_opt $compile versionset create 'from' +desc 'Name of the parent version set' +once +f
  __brazil_complete_action_opt_versionsets $compile versionset create +lastonly --from
  __brazil_complete_action_opt $compile versionset create 'owner' +desc 'Login of the owner' +once +f #:list: 
  __brazil_complete_action_opt $compile versionset create 'overwrite' +desc 'Overwrite if version set already exists' +once +f +ex --noOverwrite
  __brazil_complete_action_opt $compile versionset create 'noOverwrite' +desc 'Do not overwrite an existing version set' +once +f +ex --overwrite
  __brazil_complete_action_opt $compile versionset create 'mailingList' +desc 'Mailing list of version set group' +once +f #:perforce group:_perforce_groups
  __brazil_complete_action_opt $compile versionset create 'p4Group' +desc 'Source permissions group' +once +f #:perforce group:_perforce_groups
  __brazil_complete_action_opt $compile versionset create 'platforms' +desc 'Comma-separated list of platforms' +once +f
  __brazil_complete_action_opt $compile versionset create +a "$all_platforms" +desc 'Platform' +lastonly --platforms +f
  __brazil_complete_action_opt $compile versionset create 'targets' +desc 'Comma-separated list of targets' +once +f +ex --noTargets #:Brazil package version:_complete_package_versions
  __brazil_complete_action_opt $compile versionset create 'noTargets' +desc 'Create a new empty version set' +once +f +ex --targets
  __brazil_complete_action_opt $compile versionset create 'versionset' +short 'vs' +desc 'Version set name' +once +f
  __brazil_complete_action_opt_versionsets $compile versionset create +lastany --versionset -vs
  __brazil_complete_action_opt $compile versionset create 'vfiDependencyType' +desc 'VFI dependency type [default: "runtime"]' +once +f
  __brazil_complete_action_opt $compile versionset create +a "$all_deptypes" +desc 'Dependency type' +lastonly --vfiDependencyType +f
  __brazil_complete_action_opt $compile versionset create 'additionalMajorVersions' +desc 'Comma-separated list of extra major versions' +once +f +ex --noTargets #:Brazil package version:_complete_package_versions

  __brazil_complete_arg_vars_skipfirst $compile versionset deprecate --force --versionset -vs
  __brazil_complete_action_opt $compile versionset deprecate 'versionset' +short 'vs' +desc 'Version set name' +once +f
  __brazil_complete_action_opt_versionsets $compile versionset deprecate +lastany --versionset -vs
  __brazil_complete_action_opt $compile versionset deprecate 'force' +short 'f' +desc "Don't ask for confirmation" +once +f

  __brazil_complete_arg_vars $compile versionset extendexpiration -d -vs --days --versionset
  __brazil_complete_action_opt $compile versionset extendexpiration 'days' +short 'd' +once +f +desc 'Days from now to extend (max: 120)'
  __brazil_complete_action_opt $compile versionset extendexpiration 'versionset' +short 'vs' +desc 'Version set name' +once +f
  __brazil_complete_action_opt_versionsets $compile versionset extendexpiration +lastany --versionset -vs

  __brazil_complete_arg_vars $compile versionset history -d -vs --days --versionset
  __brazil_complete_action_opt $compile versionset history 'versionset' +short 'vs' +desc 'Version set name' +once +f
  __brazil_complete_action_opt_versionsets $compile versionset history +lastany --versionset -vs
  __brazil_complete_action_opt $compile versionset history 'max' +short 'm' +desc 'Limit of returned results' +once +f
  __brazil_complete_action_opt $compile versionset history 'short' +short 's' +desc 'Print shortened history' +once +f

  __brazil_complete_arg_vars $compile versionset import --description -desc --flavor --versionset -vs --eventId -eid --name
  __brazil_complete_action_opt $compile versionset import 'description' +short 'desc' +desc 'VFI description for Apollo' +once +f
  __brazil_complete_action_opt $compile versionset import 'flavor' +desc 'Flavor to import' +once +f
  __brazil_complete_action_opt $compile versionset import 'versionset' +short 'vs' +desc 'Version set name' +once +f
  __brazil_complete_action_opt $compile versionset import 'eventId' +short 'eid' +desc 'eventId to import from' +once +f
  __brazil_complete_action_opt $compile versionset import 'name' +desc 'Name of resulting VFI to display in Apollo' +once +f

  __brazil_complete_arg_vars $compile versionset legacymerge --eventId --to --versionset -vs --from --package -p
  __brazil_complete_action_opt $compile versionset legacymerge 'eventId' +desc 'eventId from which to merge' +once +f
  __brazil_complete_action_opt $compile versionset legacymerge 'fullMerge' +desc 'Replace packages with versions from parent including new dependencies' +once +f +ex --noFullMerge
  __brazil_complete_action_opt $compile versionset legacymerge 'noFullMerge' +desc 'Merge new versions for only existing packages' +once +f +ex --fullMerge
  __brazil_complete_action_opt $compile versionset legacymerge 'overwriteExistingVersions' +desc 'Resolve conflicts by replacing with version from parent' +once +f +ex --noOverwriteExistingVersions
  __brazil_complete_action_opt $compile versionset legacymerge 'noOverwriteExistingVersions' +desc "Don't overwrite existing package versions" +once +f +ex --overwriteExistingVersions
  __brazil_complete $compile -c brazil -f -n '__brazil_uc versionset legacymerge; and __brazil_ex --to -versionset -vs' -l 'to' -o 'versionset' -o 'vs' --description 'Name of target version set'
  __brazil_complete_action_opt $compile versionset legacymerge 'markAsTarget' +desc 'Mark the version set as a target' +once +f +ex --noMarkAsTarget
  __brazil_complete_action_opt $compile versionset legacymerge 'noMarkAsTarget' +desc 'Do not mark the version set as a target' +once +f +ex --markAsTarget
  __brazil_complete_action_opt $compile versionset legacymerge 'keepExistingVersions' +desc 'Resolve conflicts by keeping existing versions' +once +f +ex --noKeepExistingVersions
  __brazil_complete_action_opt $compile versionset legacymerge 'noKeepExistingVersions' +desc "Don't keep conflicted existing versions" +once +f +ex --keepExistingVersions
  __brazil_complete_action_opt $compile versionset legacymerge 'from' +desc 'Name of source version set' +once +f
  __brazil_complete_action_opt $compile versionset legacymerge 'force' +short 'f' +desc "Don't ask for confirmation" +once +f
  __brazil_complete_action_opt $compile versionset legacymerge 'package' +short 'p' +desc 'Package to merge from the source version set' +once +f
  __brazil_complete_action_opt_packages $compile versionset legacymerge +lastany --package -p

  __brazil_complete_arg_vars $compile versionset merge --eventId --source --destination --addNewPackage
  __brazil_complete_action_opt $compile versionset merge 'eventId' +desc 'Event ID to merge from source version set' +once +f
  __brazil_complete_action_opt $compile versionset merge 'source' +desc 'Name of source version set' +once +f
  __brazil_complete_action_opt_versionsets $compile versionset merge +lastonly --source
  __brazil_complete_action_opt $compile versionset merge 'destination' +desc 'Name of destination version set' +once +f
  __brazil_complete_action_opt_versionsets $compile versionset merge +lastonly --destination
  __brazil_complete_action_opt $compile versionset merge 'dryRun' +desc 'Do not release into the version set' +once +f +ex --noDryRun
  __brazil_complete_action_opt $compile versionset merge 'noDryRun' +desc 'Release into the version set' +once +f +ex --dryRun
  __brazil_complete_action_opt $compile versionset merge 'addNewPackage' +desc 'Add new major versions' +once +f #:packages:_complete_packages_with_interfaces

  __brazil_complete_arg_vars $compile versionset print -ts -eid -vs -f --timestamp --eventId --versionset
  __brazil_complete_action_opt $compile versionset print 'timestamp' +short 'ts' +desc 'Timestamp at which to print' +once +f +ex -eid --eventId
  __brazil_complete_action_opt $compile versionset print 'eventId' +short 'eid' +desc 'eventId at which to print' +once +f +ex -ts --timestamp
  __brazil_complete_action_opt $compile versionset print 'asFile' +desc 'Print as file instead of pretty printing' +once +f
  __brazil_complete_action_opt $compile versionset print 'versionset' +short 'vs' +desc 'Version set name' +once +f
  __brazil_complete_action_opt_versionsets $compile versionset print +lastany --versionset -vs
  __brazil_complete_action_opt $compile versionset print 'file' +short 'f' +desc 'Print to the specified file path' +once +f

  __brazil_complete_arg_vars $compile versionset printdependencies --revision -rev --timestamp -ts --versionset -vs --packages -t --eventId -eic --sort -s
  __brazil_complete_action_opt $compile versionset printdependencies 'versionset' +short 'vs' +desc 'Version set name' +once +f
  __brazil_complete_action_opt_versionsets $compile versionset printdependencies +lastany --versionset -vs
  __brazil_complete_action_opt $compile versionset printdependencies 'packages' +short 't' +desc 'Packages for which to get dependencies' +once +f #:packages:_complete_packages_with_interfaces
  __brazil_complete_action_opt $compile versionset printdependencies 'all' +desc 'Include all dependencies' +once +f
  __brazil_complete_action_opt $compile versionset printdependencies 'quiet' +desc 'Only show the data' +once +f
  __brazil_complete_action_opt $compile versionset printdependencies 'direct' +short 'dd' +desc 'Only show direct dependencies' +once +f
  __brazil_complete_action_opt $compile versionset printdependencies 'showversions' +short 'sv' +desc 'Show full versions of packages' +once +f
  __brazil_complete_action_opt $compile versionset printdependencies 'sort' +short 's' +desc 'Sort type for dependencies' +once +f
  __brazil_complete_action_opt $compile versionset printdependencies +a "$all_sorts" +desc 'Sort type' +lastany --sort -s +f
  __brazil_complete $compile -c brazil -f -n '__brazil_uc versionset printdependencies; and __brazil_ex --consumers -c -upstreams -u' -l 'consumers' -o 'c' -o 'upstreams' -o 'u' \
      --description 'Show only consumers'
  __brazil_complete $compile -c brazil -f -n '__brazil_uc versionset printdependencies; and __brazil_ex --dependencies -downstreams -d' -l 'dependencies' -o 'downstreams' -o 'd' \
      --description 'Show only dependencies'
  __brazil_complete $compile -c brazil -f -n '__brazil_uc versionset printdependencies; and __brazil_ex --minimalconsumers -minimalupstreams -min' -l 'minimalconsumers' -o 'minimalupstreams' -o 'min' \
      --description 'List $compile minimal set of consumers for packages'
  __brazil_complete_action_opt $compile versionset printdependencies 'timestamp' +short 'ts' +desc 'Timestamp at which to print' +once +f +ex --eventId --revision
  __brazil_complete_action_opt $compile versionset printdependencies 'revision' +short 'rev' +desc 'Revision at which to print' +once +f +ex --eventId --timestamp
  __brazil_complete_action_opt $compile versionset printdependencies 'eventId' +short 'eid' +desc 'eventId at which to print' +once +f +ex --timestamp --revision

  __brazil_complete_arg_vars_skipfirst $compile versionset rebuild --dryrun --versionset -vs
  __brazil_complete_action_opt $compile versionset rebuild 'versionset' +short 'vs' +desc 'Version set name' +once +f
  __brazil_complete_action_opt $compile versionset rebuild 'dryrun' +desc 'Submit as a dry-run build' +once +f

  __brazil_complete_arg_vars $compile versionset recreate --versionset -vs --from
  __brazil_complete_action_opt $compile versionset recreate 'versionset' +short 'vs' +desc 'Version set name' +once +f
  __brazil_complete_action_opt_versionsets $compile versionset recreate +lastany --versionset -vs
  __brazil_complete_action_opt $compile versionset recreate 'from' +desc 'New parent for recreation' +once +f
  __brazil_complete_action_opt_versionsets $compile versionset recreate +lastonly --from
  __brazil_complete_action_opt $compile versionset recreate 'force' +short 'f' +desc "Don't ask for confirmation" +once +f

  __brazil_complete_arg_vars $compile versionset removeflavors --flavors -f --versionset -vs
  __brazil_complete_action_opt $compile versionset removeflavors 'flavors' +short 'f' +once +f +desc 'Comma-separated list of flavors to remove'
  __brazil_complete_action_opt $compile versionset removeflavors +a "$all_flavors" +desc 'Flavor' +lastany --flavors -f +f
  __brazil_complete_action_opt $compile versionset removeflavors 'versionset' +short 'vs' +desc 'Version set name' +once +f
  __brazil_complete_action_opt_versionsets $compile versionset removeflavors +lastany --versionset -vs

  __brazil_complete_arg_vars $compile versionset removeplatforms --platforms -p --versionset -vs
  __brazil_complete_action_opt $compile versionset removeplatforms 'platforms' +short 'p' +once +f +desc 'Comma-separated list of platforms to remove'
  __brazil_complete_action_opt $compile versionset removeplatforms +a "$all_platforms" +desc 'Platform' +lastany --platforms -p +f
  __brazil_complete_action_opt $compile versionset removeplatforms 'versionset' +short 'vs' +desc 'Version set name' +once +f
  __brazil_complete_action_opt_versionsets $compile versionset removeplatforms +lastany --versionset -vs

  __brazil_complete_arg_vars $compile versionset removetargets --packages -p --versionset -vs
  __brazil_complete_action_opt $compile versionset removetargets 'packages' +short 'p' +once +f +desc 'Comma-separated list of packages to remove as targets' #:Brazil package version:_complete_package_versions
  __brazil_complete_action_opt $compile versionset removetargets 'versionset' +short 'vs' +desc 'Version set name' +once +f
  __brazil_complete_action_opt_versionsets $compile versionset removetargets +lastany --versionset -vs

  __brazil_complete_arg_vars_single $compile versionset removeunusedpackages --versionset -vs
  __brazil_complete_action_opt $compile versionset removeunusedpackages 'versionset' +short 'vs' +desc 'Version set name' +once +f
  __brazil_complete_action_opt_versionsets $compile versionset removeunusedpackages +lastany --versionset -vs

  __brazil_complete_arg_vars $compile versionset removetargets --versionset -vs --timestamp -ts --revision -rev --eventId -eid
  __brazil_complete_action_opt $compile versionset removetargets 'versionset' +short 'vs' +desc 'Version set name' +once +f
  __brazil_complete_action_opt_versionsets $compile versionset removetargets +lastany --versionset -vs
  __brazil_complete_action_opt $compile versionset removetargets 'timestamp' +short 'ts' +desc 'Timestamp of revision to revert to' +once +f +ex --eventId --revision
  __brazil_complete_action_opt $compile versionset removetargets 'revision' +short 'rev' +desc 'Revision to revert to' +once +f +ex --eventId --timestamp #:Version Set revisions: 
  __brazil_complete_action_opt $compile versionset removetargets 'eventId' +short 'eid' +desc 'VS event id to revert to' +once +f +ex --timestamp --revision

  __brazil_complete_arg_vars_single $compile versionset revive --versionset -vs
  __brazil_complete_action_opt $compile versionset revive 'versionset' +short 'vs' +desc 'Version set name' +once +f
  __brazil_complete_action_opt_versionsets $compile versionset revive +lastany --versionset -vs

  __brazil_complete_arg_vars $compile versionset setvfidependencytype --versionset -vs --type -t
  __brazil_complete_action_opt $compile versionset setvfidependencytype 'versionset' +short 'vs' +desc 'Version set name' +once +f
  __brazil_complete_action_opt_versionsets $compile versionset setvfidependencytype +lastany --versionset -vs
  __brazil_complete_action_opt $compile versionset setvfidependencytype 'type' +short 't' +desc 'VFI dependency type to use' +once +f
  __brazil_complete_action_opt $compile versionset setvfidependencytype +a "$all_deptypes" +desc 'Dependency type' +lastany --type -t +f

  __brazil_complete_arg_vars $compile s3Binary upload --key -k --file -f
  __brazil_complete_action_opt $compile s3Binary upload 'key' +short 'k' +desc 'S3 destination key' +once +f
  __brazil_complete_action_opt $compile s3Binary upload 'file' +short 'f' +desc 'File to upload' +once +f #:file:_files
  __brazil_complete_action_opt $compile s3Binary upload 'force' +desc 'Create new keys without prompting' +once +f

  __brazil_complete_arg_vars $compile s3Binary download --key -k --file -f --revision -r
  __brazil_complete_action_opt $compile s3Binary download 'key' +short 'k' +desc 'S3 key to download' +once +f
  __brazil_complete_action_opt $compile s3Binary download 'file' +short 'f' +desc 'Destination filename' +once +f #:file:_files
  __brazil_complete_action_opt $compile s3Binary download 'revision' +short 'r' +desc 'Revision to download' +once +f
  __brazil_complete_action_opt $compile s3Binary download 'force' +desc 'Overwrite existing files without prompting' +once +f

  __brazil_complete_arg_vars_single $compile s3Binary history --key -k
  __brazil_complete_action_opt $compile s3Binary history 'key' +short 'k' +desc 'S3 key to query' +once +f

  # Don't forget to re-add the commands that you added that were missing to the parent command completions

  __brazil_complete_arg_vars_skipfirst $compile branch list --includeDeprecated --package -p
  __brazil_complete_action_opt $compile branch list 'package' +short 'p' +desc 'Package name' +once +f
  __brazil_complete_action_opt_packages $compile branch list +lastany --package -p
  __brazil_complete_action_opt $compile branch list 'includeDeprecated' +desc 'List deprecated branches' +once +f +ex --noIncludeDeprecated
  __brazil_complete_action_opt $compile branch list 'noIncludeDeprecated' +desc "Don't list deprecated branches" +once +f +ex --includeDeprecated

  __brazil_complete_arg_vars $compile packagebuilder build --versionset -vs --notify --package -pkg --releaseNotes -desc --majorVersion -mv --changeId -cln --branch --impact --platforms
  __brazil_complete_action_opt $compile packagebuilder build 'versionset' +short 'vs' +desc 'Version set name' +once +f
  __brazil_complete_action_opt $compile packagebuilder build 'dryrun' +desc 'Submit as a dry-run build' +once +f
  __brazil_complete_action_opt $compile packagebuilder build 'cleanupOnFailure' +desc 'Release locks immediately on failure' +once +f +ex --noCleanupOnFailure
  __brazil_complete_action_opt $compile packagebuilder build 'noCleanupOnFailure' +desc "Don't release locks on failure" +once +f +ex --cleanupOnFailure
  __brazil_complete_action_opt $compile packagebuilder build 'notify' +desc 'Comma-separated list of emails to notify' +once +f
  __brazil_complete_action_opt $compile packagebuilder build 'waitForCompletion' +desc 'Wait for the build to complete' +once +f
  __brazil_complete_action_opt $compile packagebuilder build 'importVFI' +desc 'Import version set revision into Apollo' +once +f
  # These below here need a LOT of work to get the internal option dependencies working.
  __brazil_complete_action_opt $compile packagebuilder build 'package' +short 'pkg' +desc 'Name of package to build' +f
  __brazil_complete_action_opt_packages $compile packagebuilder build +lastany --package -pkg
  __brazil_complete_action_opt $compile packagebuilder build 'releaseNotes' +short 'desc' +desc 'Per-package description of changes being built' +f +onceper --package -pkg
  __brazil_complete_action_opt $compile packagebuilder build 'majorVersion' +short 'mv' +desc 'Per-package major version to build' +f +onceper --package -pkg
  __brazil_complete_action_opt $compile packagebuilder build 'changeId' +short 'cln' +desc 'Per-package specific branch revision to build' +f +onceper --package -pkg ex:--useLatestChange
  __brazil_complete_action_opt $compile packagebuilder build 'branch' +desc 'Per-package specific branch to build' +f +onceper --package -pkg
  __brazil_complete_action_opt $compile packagebuilder build 'impact' +desc 'Per-package impact specification' +f +onceper --package -pkg
  __brazil_complete_action_opt $compile packagebuilder build +a 'Z' +desc 'Rebuild only this package' +lastonly --impact +f
  __brazil_complete_action_opt $compile packagebuilder build +a 'Y' +desc 'Rebuild this package and all transitive consumers' +lastonly --impact +f
  __brazil_complete_action_opt $compile packagebuilder build 'useLatestChange' +desc 'Per-package option to use most recent change on branch' +f +onceper --package -pkg ex:--useCurrentRelease ex:--changeId ex:-cln
  __brazil_complete_action_opt $compile packagebuilder build 'useCurrentRelease' +desc 'Per-package option to use revision of current major version' +f +onceper --package -pkg ex:--useLatestChange
  __brazil_complete_action_opt $compile packagebuilder build 'platforms' +desc 'Per-package comma-separated list of platforms for which to build' +f +onceper --package -pkg
  __brazil_complete_action_opt $compile packagebuilder build 'import' +desc 'Per-package option to import package version into Apollo' +f +onceper --package -pkg

  __brazil_complete_arg_vars_single $compile packagebuilder delete --request -r
  __brazil_complete_action_opt $compile packagebuilder delete 'request' +short 'r' +desc 'Build request ID to delete' +once +f

  __brazil_complete_arg_vars_skipfirst $compile packagebuilder view --status --request -r
  __brazil_complete_action_opt $compile packagebuilder view 'request' +short 'r' +desc 'Build request ID to view' +once +f
  __brazil_complete_action_opt $compile packagebuilder view 'status' +short 's' +desc 'Show only the request status' +once +f +ex --versions
  __brazil_complete_action_opt $compile packagebuilder view 'versions' +short 'v' +desc 'Show only package versions' +once +f +ex --status

  __brazil_complete_arg_vars $compile majorversion removefromlive --reason -r --majorVersion -mv
  __brazil_complete_action_opt $compile majorversion removefromlive 'reason' +short 'r' +desc 'Reason for removal' +once +f
  __brazil_complete_action_opt $compile majorversion removefromlive 'majorVersion' +short 'mv' +desc 'Major version to remove' +once +f
  __brazil_complete_action_opt $compile majorversion removefromlive 'force' +short 'f' +desc 'Remove from live without prompting' +once +f

  __brazil_complete_arg_vars $compile majorversion setmasterversionset --versionset -vs --majorVersion -mv
  __brazil_complete_action_opt $compile majorversion setmasterversionset 'versionset' +short 'vs' +desc 'Version set name' +once +f
  __brazil_complete_action_opt $compile majorversion setmasterversionset 'majorVersion' +short 'mv' +desc 'Major version of package' +once +f
end

__brazil_completions
