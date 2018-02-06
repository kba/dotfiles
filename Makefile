dotfiles.sh: src/cli.bash
	cat $< > $@
	SHLOG_TERM=info \
			   shinclude  -c pound  -i $@
	chmod a+x $@

hooks:
	ln -s ../../.githooks/pre-commit .git/hooks

lib/shcolor.sh:
	cd $(dir $@) && wget https://raw.githubusercontent.com/kba/shcolor/master/shcolor.sh
