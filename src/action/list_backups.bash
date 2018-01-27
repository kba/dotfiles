action_list_backups() {
    for backup_tstamp in $DOTFILES_BACKUPDIR/*;do
        _log "$backup_tstamp"
        for backup in $backup_tstamp/.*;do
            if [[ -L $backup ]];then
                _log "    " "$(basename "$backup")"
            fi
        done
    done
}

