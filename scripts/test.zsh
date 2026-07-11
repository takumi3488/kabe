#!/usr/bin/env zsh
set -eu
setopt extended_glob null_glob

cd "${0:a:h}/.."

for f in kabe installer.sh **/*.zsh; do
  zsh -n "$f"
  print "SYNTAX OK: $f"
done
sh -n installer.sh
print 'SH SYNTAX OK: installer.sh'


for t in tests/*.zsh; do
  zsh "$t"
done
