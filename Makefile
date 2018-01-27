dotfiles.sh: src/cli.sh
	cat $< > $@
	SHLOG_TERM=info \
			   shinclude  -c vimfold  -i $@
	chmod a+x $@
