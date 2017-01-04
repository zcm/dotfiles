function restart-horizonte --description "Quickly restart Horizonte without bouncing the environment."
  set -l horizonte "/apollo/env/HorizontePlatform"
  if [ "$argv[1]" != "" ]
    if contains "/" "$argv[1]"
      set horizonte $argv[1]
    else
      set horizonte "/apollo/env/$argv[1]"
    end
  end
  set -l horizonte_pid $horizonte/var/catalina.pid
  echo -n "Checking if Tomcat is running in $horizonte... "
  if not test -e $horizonte_pid
    echo "nope! (Couldn't find the PID file.)"
    echo "Reactivate Horizonte from Apollo before attempting to restart it."
  else
    set -l kill_me (cat $horizonte_pid)
    set -l horizonte_login (ps aux | grep java | grep $kill_me | cut -d " " -f 1)
    if [ "$horizonte_login" != "" ]
      echo "yep, it sure is. (PID=$kill_me)"
      echo -n "Checking user privileges... "
      set -l is_elevated 0
      set -l current_user (whoami)
      if [ $current_user != $horizonte_login ]
        echo "elevation required. (You are not user '$horizonte_login'.)"
        if [ $horizonte_login != "nobody" ]
          echo "Hey! You probably know what you're doing, but RunAsUser is typically 'nobody'."
        end
        if sudo -u $horizonte_login true
          echo "Elevation succeeded."
          set is_elevated 1
        else
          echo "Could not elevate. Check your privilege and try again."
        end
      else
        set is_elevated 1
      end
      if [ $is_elevated -eq 1 ]
        echo -n "Stopping Horizonte... "
        if sudo -u $horizonte_login kill -9 $kill_me
          echo "done."
          echo -n "Restarting Horizonte... "
          set -l success 0
          set -l file ""
          set -l script '
BEGIN {
    FS = " ";
    tc = 0;
}
/Tomcat/ {
    if (tc == 0) tc = 1;
}
/started/ {
    if (tc != 1) tc = 0;
    if (tc == 1) tc = 2;
}
{
    for (i = 1; i <= NF; i = i + 1) {
        print $i;
        fflush();
    };
    if (tc == 2) exit;
}
'
          sudo -u $horizonte_login $horizonte/ApolloCmd/Activate/500StartTomcatServer ^ /dev/null | awk $script | while read char
            if [ $char = "" ]
              continue
            end
            if echo $char | grep -c -E -e "^-" > /dev/null
              continue
            end
            set file "$file $char"
            if echo $file | grep -c -E -e "Tomcat started" > /dev/null
              set success 1
              break
            end
            if echo $char | grep -c -E -e "[.:/+=-]" > /dev/null
              set file ""
            end
          end
          if [ $success -eq 1 ]
            echo "done!"
            echo "Horizonte server is running."
          else
            echo "OH NO!"
            echo "Couldn't start Horizonte. The Apollo startup script failed."
            echo "(Your environment is probably misconfigured. Check your configuration.)"
            echo "You can still bounce and activate from Apollo. That should restart the process."
          end
        else
          echo "OH NO!"
          echo "Couldn't stop Horizonte. The kill signal failed."
          echo "(It might already have been stopped by something else.)"
          echo "You can still bounce and activate from Apollo. That should restart the process."
        end
      end
    else
      echo "OH NO! (PID $kill_me is not alive.)"
      echo "Horizonte isn't running. Activate Horizonte from Apollo."
    end
  end
end
