
PATH=/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export MANPATH=/usr/share/man:/usr/local/share/man
LANG=C
umask 0022

#. ~/.bash_profile-local
shopt -s extglob

PATH=~/bin:$PATH
#PATH=~/bin:$(brew --prefix coreutils)/libexec/gnubin:$PATH
export CDPATH=".:..:~"
pager=$(type -p less)
export PAGER=${pager:-$(type -p more)}
[ "${PAGER##*/}" = "less" ] && export LESS='-RCMqsu~'

editor=$(type -p vim)
export EDITOR=${editor:-$(type -p vi)}
export VISUAL=$EDITOR
PS1='\h:\w \u\$ '
[ "$TERM" = "linux" -a ${SSH_AGENT_PID:-0} -eq 0 ] && eval "$(ssh-agent)"

export BASH_ENV=~/.bashrc
. $BASH_ENV
