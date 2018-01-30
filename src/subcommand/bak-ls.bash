subcommand::bak-ls::description() {
    echo "List all timestamped backups"
}

subcommand::bak-ls() {
    for backup_tstamp in $DOTFILES_BACKUPDIR/*;do
        _log "$backup_tstamp"
        for backup in $backup_tstamp/.*;do
            if [[ -L $backup ]];then
                _log "    " "$(basename "$backup")"
            fi
        done
    done
}

