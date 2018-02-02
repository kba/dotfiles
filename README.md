# kba's dotfiles setup

![dotfile all the dotfiles](doc/meme.png)

<!-- BEGIN-MARKDOWN-TOC -->
* [Why another dotfiles framework](#why-another-dotfiles-framework)
* [Design Goals](#design-goals)
	* [Written in Bash](#written-in-bash)
	* [Use Git repositories](#use-git-repositories)
	* [Use symbolic links](#use-symbolic-links)
	* [Backups included](#backups-included)
	* [Allow customization of setup](#allow-customization-of-setup)
	* [Make dotfiles fun to use](#make-dotfiles-fun-to-use)
* [Mechanics](#mechanics)
	* [Symlinks](#symlinks)
	* [Setup scripts](#setup-scripts)
* [CLI](#cli)

<!-- END-MARKDOWN-TOC -->

## Why another dotfiles framework

I have to set up new accounts on servers, virtual machines and servers running
Linux or Mac OSX on a regular basis. Setting up a comfortable development
environment becomes tedious quickly.

And none of the existing ones I tried offered the flexibility,
simplicity and features [I](https://github.com/kba) wanted.

## Design Goals

### Written in Bash

Bash is portable and available on virtually any UNIX-derived system nowadays.
Python, Perl, Ruby, zsh and others are more fun to write and maintain but Bash
is the baseline, so Bash it is

### Use Git repositories

Dotfiles belong in a version control system, Git is the most popular VCS,
Github is the most popular VCS host. Therefore: A dotfiles setup with (lots of) Git
repositories containing dotfiles hosted on Github.

Keeping all the dotfiles in a single repository will cause problems down the
road. On a server you don't want the configuration of your GUI tools. No need
for the full zsh-setup if your server has only bash available. Therefore:
Support a mix-and-match of repositories for different
tools/hosts/environemnts/etc. Using git submodules won't allow that flexiblity,
this framework does.

### Use symbolic links

Symbolic links that point to the Git-versioned dotfiles are the way to go. Use
clear conventions for doing that.

### Backups included

Every time a dotfiles repository is setup and files are about to be linked,
backups of existing files are created automatically and can be easily restored
if something breaks.

### Allow customization of setup

Every dotfiles repository can contain an `init.sh` script that can handle
more complex setup tasks beyond symlinking files.

### Make dotfiles fun to use

Using the dotfiles [CLI](./dotfiles.sh) should resemble using Git or other
subcommand-based tools. Using [colors](https://github.com/kba/shcolor),
documentation and online help should make the user experience as smooth as
possible.

## Mechanics

This repository lives somewhere in `$HOME`, I use `$HOME/dotfiles`, i.e.:

```sh
cd
git clone https://github.com/kba/dotfiles
```

Let's assume `$DOFILEDIR` holds this location (it [does](./dotfiles.sh#L41)).

Repos live in `$DOTFILEDIR/repo`.

### Symlinks

Every repo may contain directories with a leading dot and all-caps. The
name of this directory is interpreted as an environemnt variable that contains
an actual path.

Examples:

* `.HOME` => `$HOME` (i.e. `/home/<username>`)
* `.XDG_CONFIG_DIR` => `$XDG_CONFIG_DIR` (i.e. `$HOME/.config`)

These directories may contain **relative** symbolic links to a file in the
repository. These symbolic links will be dereferenced and recreated in the
appropriate directories pointing to the actual file.

For example

* `$DOTFILEDIR/repo/some-repo/.HOME/.mytoolrc -> '../mytoolrc'`

will be set up 

* `$HOME/.mytoolrc -> $DOTFILEDIR/repo/some-repo/mytoolrc`

### Setup script

Some tools will require additional steps beyond [setting up
symlinks](#symlinks). These steps can be done with a shell script in the root
of a repository.

It may be called either

* `init.sh`
* `setup.sh`

This script will be executed after every setup of a repository.

## CLI

<!-- BEGIN-EVAL -w '<pre>' '</pre>' -- bash dotfiles.sh -->
<pre>
dotfiles.sh  [options] <action> [repo...]

  Options:
    -f --force       Setup symlinks for the repo no matter what
    -a --all         Run command on all existing repos
    -i --interactive Ask for confirmation
    -y --noask       Assume defaults (i.e. don't ask but assume yes)
    -F --fetch       Fetch changes
    -r --recursive   Check for git repos recursively
    -d --debug       Show Debug output

  Actions:
    archive -r	Create an archive of current state
    bak-ls 	List all timestamped backups
    bak-rm -yi	Remove all timestamped backups
    clone -fyi	Clone repositories
    find -a	Find all dotfiles
    init 	Run the init script in each repo
    pull -r	Pull all repos
    push -ri	Push all repos
    select 	Interactively select repos
    status -Fr	Repo status
    usage -d	Show usage
</pre>

<!-- END-EVAL -->
