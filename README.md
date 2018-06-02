# Purse

![screencast gif](https://user-images.githubusercontent.com/12475110/40880505-3834ce1c-6667-11e8-89d0-6961886842c6.gif)

Purse is a fork of [pwd.sh](https://github.com/drduh/pwd.sh/).

Both programs are shell scripts which use GPG to manage passwords in an encrypted file. Purse uses asymmetric (public-key) encryption, while pwd.sh uses a symmetric (password) scheme.

While both are reasonably secure by using a trusted crypto implementation (GPG) and safe handling of password input, Purse eliminates the need to remember or use a master password to unlock. Just plug in the key, enter the PIN to unlock it, then touch to decrypt Purse passwords.

By using GPG keys and a hardware token like YubiKey, the risk of master password phishing or keylogging is eliminated; only physical possession of the hardware token AND knowledge of its PIN code may unlock private material.

# Installation

This script requires an existing GPG key and is intended to be used with a YubiKey or other hardware token for storing the private key.

See [YubiKey Guide](https://github.com/drduh/YubiKey-Guide/) for instructions on setting one up.

To install the script:

```
git clone https://github.com/drduh/purse
```

Then modify it to use the preferred GPG key ID.

# Use

`cd purse` and run the script interactively using `./purse.sh`

* Type `w` to write a password.

* Type `r` to read a password.

* Type `d` to delete a password.

Options can also be passed on the command line.

Create password with length of 30 characters for `gmail`:

    ./purse.sh w gmail 30

Append `<space>q` to suppress generated password output.

Read password for `user@github`:

    ./purse.sh r user@github

Delete password for `reddit`:

    ./purse.sh d reddit

Copy password for `github` to clipboard on macOS:

    ./purse.sh r github | cut -f 1 -d ' ' | awk 'NR==4{print $1}' | pbcopy

The script and encrypted `.purse` ciphertext file can be publicly shared between computers.

A recommended `~/.gnupg/gpg.conf` configuration file can be found at [drduh/config/gpg.conf](https://github.com/drduh/config/blob/master/gpg.conf).

# Similar software

[pwd.sh](https://github.com/drduh/pwd.sh/)

[Pass: the standard unix password manager](http://www.passwordstore.org/)

[caodonnell/passman.sh: a pwd.sh fork](https://github.com/caodonnell/passman.sh)

[bndw/pick: a minimal password manager for OS X and Linux](https://github.com/bndw/pick)

[anders/pwgen: generate passwords using OS X Security framework](https://github.com/anders/pwgen)
