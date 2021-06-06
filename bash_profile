[[ $- =~ i ]] || return 0 # -*-sh-*-

trap "date >> $HISTFILE; history -a" HUP INT QUIT KILL TERM

set -C -b
shopt -s extglob

umask 0022

# purge the env
complete -r
unalias -a
unset -f $(compgen -A function) &>/dev/null

# maybe legacy because LXDE uses vte.  is there a better check?
[[ $PROMPT_COMMAND =~ __vte ]] && PROMPT_COMMAND= || :

# start building the env. start with base_init and aliases
declare -rx ENVDIR=$(cd ~/Env/$ENVTAG &>/dev/null; pwd -P)
source $ENVDIR/base_init # mainly var defs etc.
source $ENVDIR/prime.rc
export -f load # needed for make files
[[ -e ~/.no_agentprep ]] && echo not loading agentprep || source $ENVDIR/sshAgentPrep
configEd vim
stp reset
