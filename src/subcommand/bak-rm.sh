subcommand::bak-rm::description () {
    echo "Remove all timestamped backups"
}

subcommand::bak-rm() {
    for backup_tstamp in $DOTFILES_BACKUPDIR/*;do
        _log "`C 2 b`$backup_tstamp"
        for backup in $backup_tstamp/.*;do
            local do_remove=false
            if [[ ! -L $backup ]];then
                _warn "Not removing, not a symbolic link: '$backup'"
                continue
            fi
            if [[ $DOTFILES_OPT_NOASK == true ]];then
                do_remove=true
            elif [[ $DOTFILES_OPT_INTERACTIVE == true ]];then
                _ask_yes_no "Remove backup?" && do_remove=true
            fi
            if [[ "$do_remove" == true ]];then
                _warn "DELETE '$backup'"
                rm "$backup"
            fi
        done
        if [[ -n "$(ls -A "$backup_tstamp")" ]];then
            rmdir "$backup_tstamp";
        fi
    done
}

