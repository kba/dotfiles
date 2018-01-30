export DOTFILEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DOTFILEDIR"

source "$DOTFILEDIR/shcolor.sh"
source "$DOTFILEDIR/profile.default.sh"

[[ ! -e "$DOTFILES_REPODIR"     ]] && mkdir "$DOTFILES_REPODIR"
[[ ! -e "$DOTFILES_BACKUPDIR"   ]] && mkdir "$DOTFILES_BACKUPDIR";
[[ -e "$DOTFILES_LOCAL_PROFILE" ]] && source "$DOTFILES_LOCAL_PROFILE"
