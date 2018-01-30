subcommand::select::description() {
    echo "Interactively select repos"
}

subcommand::select() {
    cd "$DOTFILEDIR"
    local repos=($(cat REPOLIST.*|sort|uniq))
    if [[ -e REPOLIST ]];then
        echo "`C 1`WARNING`C` This will clobber your existing REPOLIST. Press Ctrl-C to cancel"
        read
    fi
    echo > REPOLIST
    for repo in ${repos[@]};do
        echo -n "[ ] $repo"
        read -n1 -p " [yN] > "  yesno;
        if [[ "$yesno" != "y" && "$yesno" != "n" ]];then
            yesno="y"
        fi
        if [[ "$yesno" = "y" ]];then
            echo -e "\r[x]"
        else
            echo -e "\r[ ]"
            echo -n "# " >> REPOLIST
        fi
        echo "$repo" >> REPOLIST
    done
    echo "Written to $DOTFILEDIR/REPOLIST"
}
