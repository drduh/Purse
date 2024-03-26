#!/usr/bin/env bash
# https://github.com/drduh/Purse/blob/master/purse.sh
#set -x  # uncomment to debug
set -o errtrace
set -o nounset
set -o pipefail
umask 077
export LC_ALL="C"

now="$(date +%s)"
today="$(date +%F)"
copy="$(command -v xclip || command -v pbcopy)"
gpg="$(command -v gpg || command -v gpg2)"
gpg_conf="${GNUPGHOME}/gpg.conf"
pass_chars="[:alnum:]!?@#$%^&*();:+="

clip_dest="${PURSE_DEST:=clipboard}"   # set to 'screen' to print to stdout
clip_timeout="${PURSE_TIME:=10}"       # seconds to clear clipboard/screen
comment="${PURSE_COMMENT:=}"           # *unencrypted* comment in files
daily_backup="${PURSE_DAILY:=}"        # daily backup archive on write
pass_copy="${PURSE_COPY:=}"            # copy password before write
pass_len="${PURSE_LEN:=14}"            # default password length
safe_dir="${PURSE_SAFE:=safe}"         # safe directory name
safe_ix="${PURSE_INDEX:=purse.index}"  # index file name
safe_backup="${PURSE_BACKUP:=purse.$(hostname).${today}.tar}"

trap cleanup EXIT INT TERM
cleanup () {
  # "Lock" files on trapped exits.

  ret=$?
  chmod -R 0000 \
    "${safe_dir}" "${safe_ix}" 2>/dev/null
  exit ${ret}
}

fail () {
  # Print an error in red and exit.

  tput setaf 1 ; printf "\nERROR: %s\n" "${1}" ; tput sgr0
  exit 1
}

warn () {
  # Print a warning in yellow.

  tput setaf 3 ; printf "\nWARNING: %s\n" "${1}" ; tput sgr0
}

get_pass () {
  # Prompt for a password.

  prompt="  ${1}"
  printf "\n"

  while IFS= read -p "${prompt}" -r -s -n 1 char ; do
    if [[ ${char} == $'\0' ]] ; then break
    elif [[ ${char} == $'\177' ]] ; then
      if [[ -z "${password}" ]] ; then prompt=""
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

  cat "${1}" | \
    ${gpg} --armor --batch --decrypt 2>/dev/null
}

encrypt () {
  # Encrypt to a group of hidden recipients.

  ${gpg} --encrypt --armor --batch --yes \
    --hidden-recipient "purse_keygroup" \
    --throw-keyids --comment "${comment}" \
    --output "${1}" "${2}" 2>/dev/null
}

read_pass () {
  # Read a password from safe.

  if [[ ! -s "${safe_ix}" ]] ; then fail "${safe_ix} not found" ; fi

  while [[ -z "${username}" ]] ; do
    if [[ -z "${2+x}" ]] ; then read -r -p "
  Username: " username
    else username="${2}" ; fi
  done

  if [[ -n "${encrypt_index}" ]] ; then prompt_key "index"
    spath=$(decrypt "${safe_ix}" | \
      grep -F "${username}" | tail -1 | cut -d ":" -f2) || \
        fail "Secret not available"
  else spath=$(grep -F "${username}" "${safe_ix}" | \
    tail -1 | cut -d ":" -f2)
  fi

  prompt_key "password"
  if [[ -s "${spath}" ]] ; then
    clip <(decrypt "${spath}" | head -1) || \
      fail "Failed to decrypt ${spath}"
  else fail "Secret not available"
  fi
}

prompt_key () {
  # Print a message if safe file exists.

  if [[ -f "${safe_ix}" ]] ; then
    printf "\n  Touch key to access %s ...\n" "${1}"
  fi
}

gen_pass () {
  # Generate a password from urandom.

  if [[ -z "${3+x}" ]] ; then read -r -p "
  Password length (default: ${pass_len}): " length
  else length="${3}" ; fi

  if [[ "${length}" =~ ^[0-9]+$ ]] ; then
    pass_len="${length}"
  fi

  tr -dc "${pass_chars}" < /dev/urandom | \
    fold -w "${pass_len}" | head -1
}

write_pass () {
  # Write a password and update the index.

  spath="${safe_dir}/$(tr -dc "[:lower:]" < /dev/urandom | \
    fold -w10 | head -1)"

  if [[ -n "${pass_copy}" ]] ; then
    clip <(printf '%s' "${userpass}")
  fi

  printf '%s\n' "${userpass}" | \
    encrypt "${spath}" - || \
      fail "Failed saving ${spath}"

  if [[ -n "${encrypt_index}" ]] ; then
    prompt_key "index"

    ( if [[ -f "${safe_ix}" ]] ; then
        decrypt "${safe_ix}" || return ; fi
      printf "%s@%s:%s\n" "${username}" "${now}" "${spath}") | \
      encrypt "${safe_ix}.${now}" - && \
        mv "${safe_ix}.${now}" "${safe_ix}" || \
          fail "Failed saving ${safe_ix}.${now}"
  else
    printf "%s@%s:%s\n" \
      "${username}" "${now}" "${spath}" >> "${safe_ix}"
  fi
}

list_entry () {
  # Decrypt the index to list entries.

  if [[ ! -s "${safe_ix}" ]] ; then fail "${safe_ix} not found" ; fi

  if [[ -n "${encrypt_index}" ]] ; then prompt_key "index"
    decrypt "${safe_ix}" || fail "${safe_ix} not available"
  else printf "\n" ; cat "${safe_ix}"
  fi
}

backup () {
  # Archive index, safe and configuration.

  if [[ ! -f ${safe_backup} ]] ; then
    if [[ -f "${safe_ix}" && -d "${safe_dir}" ]] ; then
      cp "${gpg_conf}" "gpg.conf.${today}"
      tar cf "${safe_backup}" "${safe_dir}" "${safe_ix}" \
        "${BASH_SOURCE}" "gpg.conf.${today}" && \
          printf "\nArchived %s\n" "${safe_backup}"
      rm -f "gpg.conf.${today}"
    else fail "Nothing to archive" ; fi
  else warn "${safe_backup} exists, skipping archive" ; fi
}

clip () {
  # Use clipboard or stdout and clear after timeout.

  if [[ "${clip_dest}" = "screen" ]] ; then
    printf '\n%s\n' "$(cat ${1})"
  else "${copy}" < "${1}" ; fi

  printf "\n"
  while [[ "${clip_timeout}" -gt 0 ]] ; do
    printf "\r\033[K  Password on %s! Clearing in %.d" \
      "${clip_dest}" "$((clip_timeout--))" ; sleep 1
  done
  printf "\r\033[K  Clearing password from %s ..." "${clip_dest}"

  if [[ "${clip_dest}" = "screen" ]] ; then clear
  else printf "\n" ; printf "" | "${copy}" ; fi
}

setup_keygroup() {
  # Configure one or more recipients.

  purse_keygroup="group purse_keygroup ="
  keyid=""
  recommend="$(${gpg} -K | grep "sec#" | \
    awk -F "/" '{print $2}' | cut -c-18 | tr "\n" " ")"

  printf "\n  Setting up keygroup ...\n
  Found recommended key IDs: %s\n
  Enter one or more key IDs, preferred one last\n" "${recommend}"

  while [[ -z "${keyid}" ]] ; do read -r -p "
  Key ID or Enter to continue: " keyid
    if [[ -z "${keyid}" ]] ; then
      printf "%s\n" "${purse_keygroup}" >> "${gpg_conf}"
      break
    fi
    purse_keygroup="${purse_keygroup} ${keyid}"
    keyid=""
  done
}

new_entry () {
  # Prompt for username and password.

  while [[ -z "${username}" ]] ; do
    if [[ -z "${2+x}" ]] ; then read -r -p "
  Username: " username
    else username="${2}" ; fi
  done

  if [[ -z "${3+x}" ]] ; then
    get_pass "Password for \"${username}\" (Enter to generate): "
    userpass="${password}"
  fi

  printf "\n"
  if [[ -z "${password}" ]] ; then
    userpass=$(gen_pass "$@")
  fi
}

print_help () {
  # Print help text.

  printf """
  Purse is a Bash shell script to manage passwords with GnuPG asymmetric encryption. It is designed and recommended to be used with YubiKey as the secret key storage.\n
  Purse can be used interactively or by passing one of the following options:\n
    * 'w' to write a password
    * 'r' to read a password
    * 'l' to list passwords
    * 'b' to create an archive for backup\n
  Options can also be passed on the command line.\n
  * Create a 20-character password for userName:
    ./purse.sh w userName 20\n
  * Read password for userName:
    ./purse.sh r userName\n
  * Passwords are stored with an epoch timestamp for revision control. The most recent version is copied to clipboard on read. To list all passwords or read a specific version of a password:
    ./purse.sh l
    ./purse.sh r userName@1574723625\n
  * Create an archive for backup:
    ./purse.sh b\n
  * Restore an archive from backup:
    tar xvf purse*tar\n"""
}

if [[ -z "${gpg}" || ! -x "${gpg}" ]] ; then fail "GnuPG is not available" ; fi

if [[ ! -f "${gpg_conf}" ]] ; then fail "GnuPG config is not available" ; fi

if [[ ! -d "${safe_dir}" ]] ; then mkdir -p "${safe_dir}" ; fi

chmod -R 0700 "${safe_dir}" "${safe_ix}" 2>/dev/null

if [[ -z "${copy}" || ! -x "${copy}" ]] ; then
  warn "Clipboard not available, passwords will print to screen/stdout!"
  clip_dest="screen"
fi

username=""
password=""
action=""
encrypt_index=""

if [[ -n "${1+x}" ]] ; then action="${1}" ; fi

while [[ -z "${action}" ]] ; do read -r -n 1 -p "
  Read or Write (or Help for more options): " action
  printf "\n"
done

if [[ "${action}" =~ ^([rR])$ ]] ; then read_pass "$@"
elif [[ "${action}" =~ ^([wW])$ ]] ; then
  purse_keygroup="$(grep "group purse_keygroup" "${gpg_conf}")"
  if [[ -z "${purse_keygroup}" ]] ; then
    setup_keygroup
  fi
  printf "\n  %s\n" "${purse_keygroup}"
  new_entry "$@"
  write_pass
  if [[ -n "${daily_backup}" ]] ; then backup ; fi
elif [[ "${action}" =~ ^([lL])$ ]] ; then list_entry
elif [[ "${action}" =~ ^([bB])$ ]] ; then backup
else print_help ; fi

tput setaf 2 ; printf "\nDone\n" ; tput sgr0
