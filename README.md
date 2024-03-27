Purse is a fork of [drduh/pwd.sh](https://github.com/drduh/pwd.sh).

Both programs are Bash shell scripts which use [GnuPG](https://www.gnupg.org/) to manage passwords and other secrets in encrypted text files. Purse is based on asymmetric (public-key) authentication, while pwd.sh is based on symmetric (password-based) authentication.

While both scripts use a trusted crypto implementation (GnuPG) and safely handle passwords (never saving plaintext to disk, only using shell built-ins), Purse eliminates the need to remember a main passphrase - just plug in a YubiKey, enter the PIN, then touch it to decrypt a password to clipboard.

# Install

This script requires a GnuPG identity - see [drduh/YubiKey-Guide](https://github.com/drduh/YubiKey-Guide) to set one up.

For the latest version, clone the repository or download the script directly:

```console
git clone https://github.com/drduh/Purse

wget https://github.com/drduh/Purse/blob/master/purse.sh
```

Versioned [Releases](https://github.com/drduh/Purse/releases) are also available.

# Use

Run the script interactively using `./purse.sh` or symlink to a directory in `PATH`:

- `w` to write a password
- `r` to read a password
- `l` to list passwords
- `b` to create an archive for backup
- `h` to print the help text

Options can also be passed on the command line.

Create a 20-character password for `userName`:

```console
./purse.sh w userName 20
```

Read password for `userName`:

```console
./purse.sh r userName
```

Passwords are stored with an epoch timestamp for revision control. The most recent version is copied to clipboard on read. To list all passwords or read a specific version of a password:

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

# Configure

Several customizable options and features are also available, and can be configured with environment variables, for example in the [shell rc](https://github.com/drduh/config/blob/master/zshrc) file:

Variable | Description | Default | Values
-|-|-|-
`PURSE_TIME` | seconds to clear password from clipboard/screen | `10` | any valid integer
`PURSE_LEN` | default generated password length | `14` | any valid integer
`PURSE_COPY` | copy password to clipboard before write | unset (disabled) | `1` or `true` to enable
`PURSE_DAILY` | create daily backup archive on write | unset (disabled) | `1` or `true` to enable
`PURSE_ENCIX` | encrypt index for additional privacy; 2 YubiKey touches will be required for separate decryption operations | unset (disabled) | `1` or `true` to enable
`PURSE_COMMENT` | **unencrypted** comment to include in index and safe files | unset | any valid string
`PURSE_CHARS` | character set for passwords | `[:alnum:]!?@#$%^&*();:+=` | any valid characters
`PURSE_DEST` | password output destination, will set to `screen` without clipboard | `clipboard` | `clipboard` or `screen`
`PURSE_ECHO` | character used to echo password input | `*` | any valid character
`PURSE_SAFE` | safe directory name | `safe` | any valid string
`PURSE_INDEX` | index file name | `purse.index` | any valid string
`PURSE_BACKUP` | backup archive file name | `purse.$hostname.$today.tar` | any valid string

**Note** For additional privacy, the recipient key ID is **not** included in metadata (GnuPG `throw-keyids` option).



See [config/gpg.conf](https://github.com/drduh/config/blob/master/gpg.conf) for additional GnuPG options.
