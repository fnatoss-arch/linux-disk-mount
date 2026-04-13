# Linux Disk Mount for macOS

Автоматичне монтування ext2/ext3/ext4 розділів з Linux-диска на macOS через `ext4fuse`.

## Вимоги

- macOS
- [ext4fuse](https://github.com/gerard/ext4fuse) (встановлюється через `brew install ext4fuse` або [macFUSE](https://osxfuse.github.io/) + ext4fuse)
- Права `sudo`

## Як працює

Скрипт автоматично:

1. Знаходить зовнішній фізичний диск з `GUID_partition_scheme`, який **не** містить `Apple_APFS` розділів
2. Пропускає EFI-розділи та відомі непідтримувані ФС (JFS2, GRUB, XFS)
3. Монтує всі інші розділи через `ext4fuse` у `/Volumes/<мітка>`

## Використання

```zsh
# Підключіть Linux-диск, потім:
./mount_linux_disk.sh
```

## Налаштування

### Мітки розділів

Відредагуйте масив `LABELS` у скрипті, щоб задати власні імена точок монтування:

```zsh
declare -A LABELS=(
  [s1]="s1_ext2"
  [s3]="s3_OLD_DATA"
  [s6]="s6_ext3"
  # ...додайте нові
)
```

Розділи без мітки монтуються з іменем slice (наприклад, `/Volumes/s2`).

### Непідтримувані ФС

Додайте розділи, які не потрібно монтувати, до масиву `SKIP_PARTS`:

```zsh
declare -A SKIP_PARTS=(
  [s4]="JFS2 (IBM)"
  [s5]="GRUB (завантажувач)"
  [s13]="XFS (немає драйвера для macOS)"
)
```

## Розмонтування

```zsh
# Розмонтувати всі ext4fuse томи:
mount | grep ext4fuse | awk '{print $3}' | while read mp; do sudo umount "$mp"; done
```
