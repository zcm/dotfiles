function bb --description "Alias for 'brazil-build'."
  if check_ticket
    brazil-build $argv
  else
    echo "Failed to check Kerberos authorization status."
  end
end
