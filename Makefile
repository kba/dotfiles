dotfiles.sh: src/cli.bash
	cat $< > $@
	SHLOG_TERM=info \
			   shinclude  -c vimfold  -i $@
	chmod a+x $@

hooks:
	ln -s ../../.githooks/pre-commit .git/hooks
