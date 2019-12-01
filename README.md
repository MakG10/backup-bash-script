# Backup Bash Script

```
backup.sh [-h] [-V volume] [-o output_path] [-k kwallet_name] [-p kwallet_entry] [-i included_paths] [-e excluded_paths] [--rsync-options options]
Script automatically mounting veracrypt volume and backing up specified paths using rsync

Password to veracrypt volume is obtained from:
- local variable $veracrypt_volume_password
- or environment variable $VERACRYPT_PASSWORD
- or kwallet

Options:
  -h, --help                show this help text
  -V, --veracrypt-volume    path to the VeraCrypt volume
  -o, --output              mouting point for veracrypt volume
  -k, --kwallet-name        kwallet name (default: kdewallet)
  -p, --kwallet-entry       kwallet entry name (default: veracrypt_backup)
  -i, --include             path to the file containing paths that should be backed up
  -e, --exclude             path to the file containing paths/names that should be excluded
  --rsync-options           options passed to rsync (default: -avR)
```

Example usage:

```
backup.sh -V ~/Nextcloud/backup/backup.vc --kwallet-entry veracrypt_backup -i ~/backup_include.txt -e ~/backup_exclude.txt --output /mnt/veracrypt-backup
```

Example usage with already mounted VeraCrypt volume:

```
backup.sh -o /media/veracrypt2/backup -i ~/backup_include.txt -e ~/backup_exclude.txt --rsync-options "-avR --delete"
```
