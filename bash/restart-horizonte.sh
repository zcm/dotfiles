#!/usr/bin/env bash

horizonte=/apollo/env/HorizontePlatform
horizonte_pid=$horizonte/var/catalina.pid

echo -n "Checking if Horizonte is running... "

if [ ! -e $horizonte_pid ]; then
    echo "nope! (Couldn't find the PID file.)"
    echo "Reactivate Horizonte from Apollo before attempting to restart it."
else
    kill_me=$(cat $horizonte_pid)
    horizonte_login=$(ps aux | grep java | grep $kill_me | cut -d " " -f 1)
    if [ "$horizonte_login" != "" ]; then
        echo "yep, it sure is. (PID=$kill_me)"
        echo -n "Checking user privileges... "
        is_elevated=0
        current_user=$(whoami)
        if [ "$current_user" != "$horizonte_login" ]; then
            echo "elevation required. (You are not user '$horizonte_login'.)"
            if [ "$horizonte_login" != "nobody" ]; then
                echo "Hey! You probably know what you're doing, but RunAsUser is typically 'nobody'."
            fi
            if sudo -u $horizonte_login true; then
                echo "Elevation succeeded."
                is_elevated=1
            else
                echo "Could not elevate. Check your privilege and try again."
            fi
        else
            is_elevated=1
        fi
        if [[ $is_elevated -eq 1 ]]; then
            echo -n "Stopping Horizonte... "
            if sudo -u $horizonte_login kill -9 $kill_me; then
                file=
                echo "done."
                echo -n "Restarting Horizonte... "
                read -r -d '' script <<'EOF'
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
EOF
                sudo -u $horizonte_login $horizonte/ApolloCmd/Activate/500StartTomcatServer 2> /dev/null | awk "$script" | {
                    success=0
                    while read char; do
                        if [ "$char" = "" ]; then
                            continue
                        fi
                        if echo $char | grep -c -E -e "^-" > /dev/null; then
                            continue
                        fi
                        file="$file $char"
                        if echo $file | grep -c -E -e "Tomcat started" > /dev/null; then
                            success=1
                            break
                        fi
                        if echo $char | grep -c -E -e "[.:/+=-]" > /dev/null; then
                            file=
                        fi
                    done
                    if [[ $success -eq 1 ]]; then
                        echo "done!"
                        echo "Horizonte server is running."
                    else
                        echo "OH NO!"
                        echo "Couldn't start Horizonte. The Apollo startup script failed."
                        echo "(Your environment is probably misconfigured. Check your configuration.)"
                        echo "You can still bounce and activate from Apollo. That should restart the process."
                    fi
                }
            else
                echo "OH NO!"
                echo "Couldn't stop Horizonte. The kill signal failed."
                echo "(It might already have been stopped by something else.)"
                echo "You can still bounce and activate from Apollo. That should restart the process."
            fi
        fi
    else
        echo "OH NO! (PID $kill_me is not alive.)"
        echo "Horizonte isn't running. Activate Horizonte from Apollo."
    fi
fi

