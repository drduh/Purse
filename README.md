# Purse

![screencast gif](https://user-images.githubusercontent.com/12475110/40880505-3834ce1c-6667-11e8-89d0-6961886842c6.gif)

Purse is a fork of [drduh/pwd.sh](https://github.com/drduh/pwd.sh).

Both programs are shell scripts which use [GPG](https://www.gnupg.org/) to manage passwords in an encrypted text file. Purse uses asymmetric (public-key) encryption, while pwd.sh uses symmetric (password) encryption.

While both are reasonably secure by using a trusted crypto implementation (GPG) and safe handling of password input, Purse eliminates the need to remember and use a master password - just plug in a YubiKey, enter the PIN, then touch it to decrypt the password safe to stdout.

By using GPG keys and a hardware token like YubiKey, the risk of master password phishing or keylogging is eliminated; only physical possession of the hardware token AND knowledge of the PIN can unlock the password safe.

# Installation

This script requires an existing GPG key and is intended to be used with a YubiKey or similar hardware token for storing the private key. See [drduh/YubiKey-Guide](https://github.com/drduh/YubiKey-Guide) for instructions on setting one up.

To install the script:

```console
$ git clone https://github.com/drduh/Purse
```

Then modify it to use the preferred GPG key ID.

# Use

`cd Purse` and run the script interactively using `./purse.sh`

* Type `w` to write a password.
* Type `r` to read a password.
* Type `d` to delete a password.
* Type `h` to print the help text.

Examples:

Create 30-character password for `gmail`:

```console
$ ./purse.sh w gmail 30
```

Append `q` to create a password without displaying it.

Read password for `user@github`:

```console
$ ./purse.sh r user@github
```

Delete password for `reddit`:

```console
$ ./purse.sh d reddit
```

Copy password for `github` to clipboard (substitute `pbcopy` on macOS):

```console
$ ./purse.sh r github | cut -f 1 -d ' ' | awk 'NR==4{print $1}' | xclip
```

This script and encrypted `purse.enc` file can be publicly shared between trusted computers. For additional privacy, the recipient key ID is **not** included in GPG metadata.

See [drduh/config/gpg.conf](https://github.com/drduh/config/blob/master/gpg.conf) for additional GPG options.

# Similar software

* [drduh/pwd.sh](https://github.com/drduh/pwd.sh)
* [bndw/pick: command-line password manager for macOS and Linux](https://github.com/bndw/pick)
* [Pass: the standard unix password manager](https://www.passwordstore.org/)
* [anders/pwgen: generate passwords using OS X Security framework](https://github.com/anders/pwgen)
* [caodonnell/passman.sh: a pwd.sh fork](https://github.com/caodonnell/passman.sh)
