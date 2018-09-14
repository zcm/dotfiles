function check_ticket --description "Verify that there is a valid Kerberos ticket cached, and if there isn't, request one."
  if not klist -s
    echo "You don't have a recent Kerberos ticket. Please enter your password to refresh it now."
    set -l err_msg "Request for Kerberos ticket failed."
    if not kinit -f
      echo "$err_msg Try again. (Attempt #1.)"
      if not kinit -f
        echo "$err_msg Try again. (Attempt #2.)"
        if not kinit -f
          echo "$err_msg Sorry, this isn't working out. Fix your password and try again later. (Attempt #3.)"
          return 1
        end
      end
    end
  end
end
