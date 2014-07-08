# .bash_profile

# Get the aliases and functions
if [ -f ~/.bashrc ]; then
  . ~/.bashrc
fi

# Source the machine-specific profile, if it exists
if [ -f ~/.local_bash_profile ]; then
  . ~/.local_bash_profile
fi
