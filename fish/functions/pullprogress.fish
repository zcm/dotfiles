function pullprogress
  cat (ls -t /apollo/var/logs/apollo-update.root.log.*)[2] (ls -t /apollo/var/logs/apollo-update.root.log.*)[1] | grep -c "pullPackage .*: Operation completed"
end
