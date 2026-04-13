#!/bin/zsh
# Монтує всі ext2/ext3/ext4 розділи з Linux-диска
# Автовизначення зовнішнього фізичного диска (MBR або GPT, без Apple_APFS)
LINUX_DISK=""
for disk in $(diskutil list | grep -A2 'external, physical' | grep -E 'FDisk_partition_scheme|GUID_partition_scheme' | grep -oE 'disk[0-9]+'); do
  if ! diskutil list "$disk" | grep -q 'Apple_APFS'; then
    LINUX_DISK="$disk"
    break
  fi
done
if [[ -z "$LINUX_DISK" ]]; then
  echo "✗ Linux-диск не знайдено"
  exit 1
fi
echo "ℹ️  Знайдено Linux-диск: /dev/$LINUX_DISK"
echo ""

# Відомі мітки для розділів (за бажанням додайте нові)
declare -A LABELS=(
  [s1]="s1_ext2"
  [s3]="s3_OLD_DATA"
  [s6]="s6_ext3"
  [s7]="s7_CLDG"
  [s8]="s8_ext4"
  [s9]="s9_ext4"
  [s10]="s10_ext4"
  [s11]="s11_ext2"
  [s12]="s12_ext4"
)

# Непідтримувані ФС (розділи, які не слід монтувати через ext4fuse)
declare -A SKIP_PARTS=(
  [s4]="JFS2 (IBM)"
  [s5]="GRUB (завантажувач)"
  [s13]="XFS (немає драйвера для macOS)"
)

mounted=0
skipped=()
failed=()

# Автовиявлення всіх розділів на диску
for part in $(diskutil list "$LINUX_DISK" | grep -oE "${LINUX_DISK}s[0-9]+"); do
  slice="${part#$LINUX_DISK}"

  # Пропустити EFI
  if diskutil info "$part" 2>/dev/null | grep -qi 'EFI'; then
    continue
  fi

  # Пропустити відомі непідтримувані ФС
  if [[ -n "${SKIP_PARTS[$slice]}" ]]; then
    skipped+=("   $part → ${SKIP_PARTS[$slice]}")
    continue
  fi

  # Перевірити наявність пристрою
  if [[ ! -e "/dev/$part" ]]; then
    skipped+=("   $part → пристрій не знайдено (розділ всередині extended)")
    continue
  fi

  # Визначити мітку
  label="${LABELS[$slice]:-$slice}"
  mountpoint="/Volumes/$label"

  # Перевірити чи вже змонтовано
  if mount | grep -q "$mountpoint"; then
    echo "⏩ $mountpoint вже змонтовано"
    ((mounted++))
    continue
  fi

  echo "→ Монтування /dev/$part → $mountpoint"
  sudo mkdir -p "$mountpoint"
  if sudo ext4fuse "/dev/$part" "$mountpoint" -o allow_other 2>&1; then
    echo "  ✓ OK"
    ((mounted++))
  else
    echo "  ✗ Помилка"
    failed+=("   $part ($label)")
  fi
done

echo ""
echo "✓ Змонтовано розділів: $mounted"

if (( ${#skipped[@]} > 0 )); then
  echo ""
  echo "⚠️  Пропущено (непідтримувані ФС):"
  printf '%s\n' "${skipped[@]}"
fi

if (( ${#failed[@]} > 0 )); then
  echo ""
  echo "✗ Не вдалося змонтувати:"
  printf '%s\n' "${failed[@]}"
fi

echo ""
echo "Змонтовані томи:"
df -h | grep Volumes
