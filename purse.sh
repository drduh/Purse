#!/usr/bin/env bash
# https://github.com/drduh/Purse/blob/master/purse.sh

set -o errtrace
set -o nounset
set -o pipefail

#set -x # uncomment to debug

umask 077

encrypt_index="false"
now=$(date +%s)
copy="$(command -v xclip || command -v pbcopy)"
gpg="$(command -v gpg || command -v gpg2)"
gpgconf="${HOME}/.gnupg/gpg.conf"
backuptar="${PURSE_BACKUP:=purse.$(hostname).$(date +%F).tar}"
safeix="${PURSE_INDEX:=purse.index}"
safedir="${PURSE_SAFE:=safe}"
script="$(basename $BASH_SOURCE)"
timeout=10

fail () {
  # Print an error message and exit.

  tput setaf 1 1 1 ; printf "\nError: %s\n" "${1}" ; tput sgr0
  exit 1
}

get_pass () {
  # Prompt for a password.

  password=""
  prompt="${1}"

  while IFS= read -p "${prompt}" -r -s -n 1 char ; do
    if [[ ${char} == $'\0' ]] ; then
      break
    elif [[ ${char} == $'\177' ]] ; then
      if [[ -z "${password}" ]] ; then
        prompt=""
      else
        prompt=$'\b \b'
        password="${password%?}"
      fi
    else
      prompt="*"
      password+="${char}"
    fi
  done
}

decrypt () {
  # Decrypt with GPG.

  cat "${1}" | ${gpg} --armor --batch --decrypt 2>/dev/null
}

encrypt () {
  # Encrypt to a group of hidden recipients.

  ${gpg} --encrypt --armor --batch --yes --throw-keyids \
    --hidden-recipient "purse_keygroup" \
    --output "${1}" "${2}"
}

read_pass () {
  # Read a password from safe.

  if [[ ! -s ${safeix} ]] ; then fail "${safeix} not found" ; fi

  username=""
  while [[ -z "${username}" ]] ; do
    if [[ -z "${2+x}" ]] ; then read -r -p "
  Username: " username
    else username="${2}" ; fi
  done

  if [[ "${encrypt_index}" = "true" ]] ; then
    prompt_key "index"

    spath=$(decrypt "${safeix}" | \
      grep -F "${username}" | tail -n1 | cut -d ":" -f2) || \
        fail "Decryption failed"
  else
    spath=$(grep -F "${username}" "${safeix}" | \
      tail -n1 | cut -d ":" -f2)
  fi

  prompt_key "password"

  clip <(decrypt "${spath}" | head -n1) || \
    fail "Decryption failed"
}

prompt_key () {
  # Print a message if safe file exists.

  if [[ -f "${safeix}" ]] ; then
    printf "\n  Touch key to access %s ...\n" "${1}"
  fi
}

gen_pass () {
  # Generate a password using GPG.

  len=20
  max=80

  if [[ -z "${3+x}" ]] ; then read -r -p "

  Password length (default: ${len}, max: ${max}): " length
  else length="${3}" ; fi

  if [[ ${length} =~ ^[0-9]+$ ]] ; then len=${length} ; fi

  # base64: 4 characters for every 3 bytes
  ${gpg} --armor --gen-random 0 "$((max * 3 / 4))" | cut -c -"${len}"
}

write_pass () {
  # Write a password and update index file.

  fpath=$(tr -dc "[:lower:]" < /dev/urandom | fold -w8 | head -n1)
  spath=${safedir}/${fpath}
  printf '%s\n' "${userpass}" | \
    encrypt "${spath}" - || \
      fail "Failed to put ${spath}"

  if [[ "${encrypt_index}" = "true" ]] ; then
    prompt_key "index"

    ( if [[ -f "${safeix}" ]] ; then
        decrypt "${safeix}" || return ; fi
      printf "%s@%s:%s\n" "${username}" "${now}" "${spath}") | \
      encrypt "${safeix}.${now}" - || \
        fail "Failed to put ${safeix}.${now}"
      mv "${safeix}.${now}" "${safeix}"
  else
    printf "%s@%s:%s\n" "${username}" "${now}" "${spath}" >> "${safeix}"
  fi

}

list_entry () {
  # Decrypt the index to list entries.

  if [[ ! -s ${safeix} ]] ; then fail "${safeix} not found" ; fi

  if [[ "${encrypt_index}" = "true" ]] ; then
    prompt_key "index"
    decrypt "${safeix}" || fail "Decryption failed"
  else
    cat "${safeix}"
  fi
}

backup () {
  # Create an archive for backup.

  if [[ -f "${safeix}" ]] ; then
    cp "${gpgconf}" "gpg.conf.${now}"
    tar cfv "${backuptar}" \
      "${safeix}" "${safedir}" "gpg.conf.${now}" "${script}"
    rm "gpg.conf.${now}"
  else fail "Nothing to archive" ; fi

  printf "\nArchived %s \n" "${backuptar}"
}

clip () {
  # Use clipboard and clear after timeout.

  ${copy} < "${1}"

  printf "\n"
  shift
  while [ $timeout -gt 0 ] ; do
    printf "\r\033[KPassword on clipboard! Clearing in %.d" $((timeout--))
    sleep 1
  done

  printf "" | ${copy}
}


setup_keygroup() {
  # Configure GPG keygroup setting.

  purse_keygroup="group purse_keygroup ="
  keyid=""
  recommend="$(${gpg} -K | grep "sec#" | \
    awk -F "/" '{print $2}' | cut -c-18 | tr "\n" " ")"

  printf "\n  Setting up GPG key group ...

  Found key IDs: %s

  Enter backup key IDs first, preferred key IDs last.
  " "${recommend}"

  while [[ -z "${keyid}" ]] ; do
    read -r -p "
  Key ID or Enter to continue: " keyid
    if [[ -z "${keyid}" ]] ; then
      printf "%s\n" "$purse_keygroup" >> "${gpgconf}"
      break
    fi
    purse_keygroup="${purse_keygroup} ${keyid}"
    keyid=""
  done
}

new_entry () {
  # Prompt for new username and/or password.

  username=""
  while [[ -z "${username}" ]] ; do
    if [[ -z "${2+x}" ]] ; then read -r -p "
  Username: " username
    else username="${2}" ; fi
  done

  if [[ -z "${3+x}" ]] ; then get_pass "
  Password for \"${username}\" (Enter to generate): "
    userpass="${password}"
  fi

  if [[ -z "${password}" ]] ; then userpass=$(gen_pass "$@") ; fi
}

print_help () {
  # Print help text.

  printf """
  Purse is a Bash shell script to manage passwords with GnuPG asymmetric encryption. It is designed and recommended to be used with Yubikey as the secret key storage.

  Purse can be used interactively or by passing one of the following options:

    * 'w' to write a password
    * 'r' to read a password
    * 'l' to list passwords
    * 'b' to create an archive for backup

  Example usage:

    * Generate a 30 character password for 'userName':
        ./purse.sh w userName 30

    * Copy the password for 'userName' to clipboard:
        ./purse.sh r userName

    * List stored passwords and copy a previous version:
        ./purse.sh l
        ./purse.sh r userName@1574723625

    * Create an archive for backup:
        ./purse.sh b

    * Restore an archive from backup:
        tar xvf purse*tar"""
}

if [[ -z ${gpg} && ! -x ${gpg} ]] ; then fail "GnuPG is not available" ; fi

if [[ ! -f ${gpgconf} ]] ; then fail "GnuPG config is not available" ; fi

if [[ -z ${copy} && ! -x ${copy} ]] ; then fail "Clipboard is not available" ; fi

if [[ ! -d ${safedir} ]] ; then mkdir -p ${safedir} ; fi

chmod -R 0600 ${safeix}  2>/dev/null
chmod -R 0700 ${safedir} 2>/dev/null

password=""
action=""
if [[ -n "${1+x}" ]] ; then action="${1}" ; fi

while [[ -z "${action}" ]] ; do
  read -n 1 -p "
  Read or Write (or Help for more options): " action
  printf "\n"
done

if [[ "${action}" =~ ^([hH])$ ]] ; then
  print_help

elif [[ "${action}" =~ ^([bB])$ ]] ; then
  backup

elif [[ "${action}" =~ ^([lL])$ ]] ; then
  list_entry

elif [[ "${action}" =~ ^([wW])$ ]] ; then
  purse_keygroup=$(grep "group purse_keygroup" "${gpgconf}")
  if [[ -z "${purse_keygroup}" ]] ; then
    setup_keygroup
  fi
  printf "\n  %s\n" "${purse_keygroup}"

  new_entry "$@"
  write_pass

else read_pass "$@" ; fi

chmod -R 0400 ${safeix} ${safedir} 2>/dev/null

tput setaf 2 2 2 ; printf "\nDone\n" ; tput sgr0
