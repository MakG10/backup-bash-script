#!/bin/bash

set -e

veracrypt_volume=""
veracrypt_volume_password=""

kwallet_name="kdewallet"
kwallet_entry="veracrypt_backup"

target_path=""
include_paths=(
)
exclude_paths=(
)

usage="$(basename "$0") [-h] [-V volume] [-o output_path] [-k kwallet_name] [-p kwallet_entry] [-i included_paths] [-e excluded_paths]
Script automatically mounting veracrypt volume and backing up specified paths using rsync

Password to veracrypt volume is obtained from:
- local variable \$veracrypt_volume_password
- or environment variable \$VERACRYPT_PASSWORD
- or kwallet

Options:
  -h, --help                show this help text
  -V, --veracrypt-volume    path to the VeraCrypt volume
  -o, --output              mouting point for veracrypt volume
  -k, --kwallet-name        kwallet name (default: kdewallet)
  -p, --kwallet-entry       kwallet entry name (default: veracrypt_backup)
  -i, --include             path to the file containing paths that should be backed up
  -e, --exclude             path to the file containing paths/names that should be excluded"

isKwalletInstalled() {
    hash kwallet-query

    return $?
}

getPasswordFromKwallet() {
    password=$(kwallet-query -r ${kwallet_entry} ${kwallet_name})

    echo $password
}

fetchVeracryptPassword() {
    if [[ -n "$veracrypt_volume_password" ]]; then
        echo $veracrypt_volume_password
        return 0
    fi

    if [[ -n "$VERACRYPT_PASSWORD" ]]; then
        echo $VERACRYPT_PASSWORD
        return 0
    fi

    if isKwalletInstalled; then
        echo $(getPasswordFromKwallet)
        return 0
    fi


    echo "Veracrypt volume password is not set." 1>&2
    exit 1
}

mountVeracryptVolume() {
    password=$(fetchVeracryptPassword)
    echo "$password" | sudo veracrypt -t --non-interactive -m timestamp ${veracrypt_volume} ${target_path} --stdin
    return $?
}

unmountVeracryptVolume() {
    veracrypt -t --non-interactive -d ${veracrypt_volume}
}

backup() {
    # Included paths
    for item in "${include_paths[@]}"
    do
      include_args="${include_args} ${item}"
    done

    # Excluded paths
    for item in "${exclude_paths[@]}"
    do
      exclude_flags="${exclude_flags} --exclude=${item}"
    done

    # rsync - backup files
    set +e
    rsync -avR ${exclude_flags} ${include_args} ${target_path}
    set -e
}


# Parse options
while [[ "$1" =~ ^- && ! "$1" == "--" ]]; do case $1 in
  -h | --help)
    echo "$usage"
    exit 0
    ;;
  -V | --veracrypt-volume )
    shift; veracrypt_volume=$1
    ;;
  -o | --output )
    shift; target_path=$1
    ;;
  -k | --kwallet-name )
    shift; kwallet_name=$1
    ;;
  -p | --kwallet-entry )
    shift; kwallet_entry=$1
    ;;
  -i | --include )
    shift; mapfile -t include_paths < $1
    ;;
  -e | --exclude )
    shift; mapfile -t exclude_paths < $1
    ;;

esac; shift; done
if [[ "$1" == '--' ]]; then shift; fi

# Validate options
if [[ -z "$veracrypt_volume" ]]; then
    echo "Veracrypt volume not provided. Use --veracrypt-volume option."
    exit 2
fi

if [[ -z "$target_path" ]]; then
    echo "Mounting point is not specified. Use --output option."
    exit 2
fi


mountVeracryptVolume
mount_result=$?

if [[ "$mount_result" -ne "0" ]]; then
    echo "Failed to mount veracrypt volume" 1>&2
    exit 3
fi

backup
unmountVeracryptVolume
