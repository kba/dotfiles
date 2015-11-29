kba's dotfiles setup
====================

![dotfile all the dotfiles](meme.png)

Why another dotfiles framework
------------------------------

I have to set up new accounts on servers, virtual machines and servers running
Linux or Mac OSX on a regular basis. Setting up a comfortable development
environment becomes tedious quickly.

And none of the existing ones I tried offered the flexibility,
simplicity and features [I](https://github.com/kba) wanted.

Design Goals
------------

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

How to use
----------
