# Purse

Purse is a fork of [drduh/pwd.sh](https://github.com/drduh/pwd.sh).

Both programs are Bash shell scripts which use [GPG](https://www.gnupg.org/) to manage passwords and other secrets in encrypted text files. Purse uses asymmetric (public-key) authentication, while pwd.sh uses symmetric (password-based) authentication.

While both scripts use a trusted crypto implementation (GPG) and safely handle passwords (never saving plaintext to disk), Purse eliminates the need to remember and use a master password - just plug in a YubiKey, enter the PIN, then touch it to decrypt a password to clipboard.

By using Purse with YubiKey, the risk of master password theft or keylogging is eliminated - only physical possession of the Yubikey AND knowledge of the PIN can unlock the encrypted index and password files.

# Release notes

## Version 1 (2018)

The original release which has been available for general use and review since June 2018 (forked from pwd.sh which dates to 2015). There are no known bugs nor security vulnerabilities identified in this stable version of purse.sh.  Compatible on Linux, OpenBSD, macOS.

## Version 2b (2019)

The second release of purse.sh features several security and reliability improvements, and is an optional upgrade. Currently in beta testing. Compatible on Linux, OpenBSD, macOS.

Known issues:
* Read actions now require two Yubikey touches, if touch to decrypt is enabled - once for the index and twice for the encrypted password file.

Changelist:
* Passwords are now encrypted as individual files, rather than all encrypted as a single flat file.
* Individual password filenames are random, mapped to usernames in an encrypted index file.
* Index and password files are now "immutable" using chmod while purse.sh is not running.
* Read passwords are now copied to clipboard and cleared after a timeout, instead of printed to stdout.
* Use printf instead of echo for improved portability.
* New option: list passwords in the index.
* New option: create tar archive for backup.
* Removed option: delete password; the index is now a permanent ledger.
* Removed option: read all passwords; no use case for having a single command.
* Removed option: suppress generated password output; should be read from safe to verify save.

# Use

This script requires a GPG identity - see [drduh/YubiKey-Guide](https://github.com/drduh/YubiKey-Guide) to set one up.

```console
$ git clone https://github.com/drduh/Purse
```

Set your GPG key ID with `export PURSE_KEYID=0xFF3E7D88647EBCDB` or by editing `purse.sh`.

`cd purse.sh` and run the script interactively using `./purse.sh` or symlink to a directory in `PATH`:

* Type `w` to write a password
* Type `r` to read a password
* Type `l` to list passwords
* Type `b` to create an archive for backup
* Type `h` to print the help text

Options can also be passed on the command line.

Example usage:

Create a 30-character password for `userName`:

```console
$ ./purse.sh w userName 30
```

Read password for `userName`:

```console
$ ./purse.sh r userName
```

Passwords are stored with a timestamp for revision control. The most recent version is copied to clipboard on read. To list all passwords or read a previous version of a password:

```console
$ ./purse.sh l

$ ./purse.sh r userName@1574723600
```

Create an archive for backup:

```console
$ ./purse.sh b
```

Restore an archive from backup:

```console
$ tar xvf purse*tar
```

The backup contains only encrypted files and can be publicly shared for use on trusted computers. For additional privacy, the recipient key ID is **not** included in GPG metadata (`throw-keyids` option).

See [drduh/config/gpg.conf](https://github.com/drduh/config/blob/master/gpg.conf) for additional GPG configuration options.

# Similar software

* [drduh/pwd.sh](https://github.com/drduh/pwd.sh)
* [zx2c4/password-store](https://github.com/zx2c4/password-store)
* [caodonnell/passman.sh: a pwd.sh fork](https://github.com/caodonnell/passman.sh)
* [bndw/pick: command-line password manager for macOS and Linux](https://github.com/bndw/pick)
* [anders/pwgen: generate passwords using OS X Security framework](https://github.com/anders/pwgen)
