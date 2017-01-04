function crux --description "CRUX code review system."
  if check_ticket
    /apollo/env/RubyEnv/ruby2.1.x/bin/ruby ~/bin/cr-upgrade --quiet
    /apollo/env/RubyEnv/ruby2.1.x/bin/ruby ~/bin/cr-lib/main.rb $argv
  else
    echo "Failed to check Kerberos authorization status."
  end
end

