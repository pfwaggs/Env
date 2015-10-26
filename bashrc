[ -z "$(echo $- | grep i)" ] && return 0
trap "unset HISTFILE" EXIT

set -C -b -o vi

#export color='00;36'
#PS1=$'\[\e[${color}m\]\h\$ \[\e[m\]'
HISTFILE=~/.bh-$(date "+%F").$$
#
#if [[ $TERM =~ xterm* ]]; then
#  n=$(tty)
#  n=$((${tty:(-3)}+0))
##  n=${n##*/}
#  host=${HOSTNAME%%.*}
#  export PROMPT_COMMAND='printf "]1;%s]2;%s" "$n:$host:$PWD" "$n:$PWD"'
#fi

#. ~/env/COMMON_env
. ~/envsync/env
PATH=$(vpurge $PATH)
