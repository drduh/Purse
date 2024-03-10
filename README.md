# Purse

Purse is a fork of [drduh/pwd.sh](https://github.com/drduh/pwd.sh).

Both programs are Bash shell scripts which use [GnuPG](https://www.gnupg.org/) to manage passwords and other secrets in encrypted text files. Purse is based on asymmetric (public-key) authentication, while pwd.sh is based on symmetric (password-based) authentication.

While both scripts use a trusted crypto implementation (GnuPG) and safely handle passwords (never saving plaintext to disk, only using shell built-ins to handle passwords), Purse eliminates the need to remember a master password - just plug in a YubiKey, enter the PIN, then touch it to decrypt a password to clipboard.

# Release notes

See [Releases](https://github.com/drduh/Purse/releases)

# Use

This script requires a GnuPG identity - see [drduh/YubiKey-Guide](https://github.com/drduh/YubiKey-Guide) to set one up. Multiple identities stored on several YubiKeys are recommended for improved durability and reliability.

Clone the repository:

```console
git clone https://github.com/drduh/Purse
```

Or download the script directly:

```console
wget https://github.com/drduh/Purse/blob/master/purse.sh
```

Run the script interactively using `./purse.sh` or symlink to a directory in `PATH`:

* Type `w` to write a password
* Type `r` to read a password
* Type `l` to list passwords
* Type `b` to create an archive for backup
* Type `h` to print the help text

Options can also be passed on the command line.

Example usage:

Create a 20-character password for `userName`:

```console
./purse.sh w userName 20
```

Read password for `userName`:

```console
./purse.sh r userName
```

Passwords are stored with a timestamp for revision control. The most recent version is copied to clipboard on read. To list all passwords or read a specific version of a password:

```console
./purse.sh l

./purse.sh r userName@1574723600
```

Create an archive for backup:

```console
./purse.sh b
```

Restore an archive from backup:

```console
tar xvf purse*tar
```

**Note** For additional privacy, the recipient key ID is **not** included in metadata (`throw-keyids` option).

The password index file can also be encrypted by changing the `encrypt_index` variable to `true` in the script, although two touches will be required for two separate decryption operations.

See [config/gpg.conf](https://github.com/drduh/config/blob/master/gpg.conf) for additional configuration options.
