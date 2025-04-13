Purse is a based on [drduh/pwd.sh](https://github.com/drduh/pwd.sh).

Both programs are Bash shell scripts which use [GnuPG](https://www.gnupg.org/) to manage secrets in encrypted text files. Purse is based on asymmetric (public-key) authentication, while [pwd.sh](https://github.com/drduh/pwd.sh) is based on symmetric (passphrase-based) authentication.

Purse eliminates the need to remember a passphrase: plug in the YubiKey, enter PIN and touch it to access secrets.

# Install

Purse requires a GnuPG identity - see [drduh/YubiKey-Guide](https://github.com/drduh/YubiKey-Guide) to set one up.

For the latest version, clone the repository or download the script directly:

```console
git clone https://github.com/drduh/Purse

wget https://github.com/drduh/Purse/blob/master/purse.sh
```

Versioned [Releases](https://github.com/drduh/Purse/releases) are also available.

# Use

Run the script interactively using `./purse.sh` or symlink to a directory in `PATH`:

- `w` to create a secret
- `r` to access a secret
- `l` to list all secrets
- `b` to create a backup archive
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

See [config/gpg.conf](https://github.com/drduh/config/blob/main/gpg.conf) for recommended GnuPG options.

Several customizable options and features are also available, and can be configured with environment variables, for example in the [shell rc](https://github.com/drduh/config/blob/main/zshrc) file:

Variable | Description | Default | Available options
---: | :---: | :---: | :---
`PURSE_CLIP` | clipboard to use | `xclip` | `pbcopy` on macOS
`PURSE_CLIP_ARGS` | arguments to pass to clipboard command | unset (disabled) | `-i -selection clipboard` to use primary (control-v) clipboard with xclip
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

> [!NOTE]
> For privacy, the recipient key ID is **not** included in metadata (using the GnuPG `throw-keyids` option).
