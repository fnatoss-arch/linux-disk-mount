#!/bin/zsh
# Розмонтовує всі ext4fuse томи з Linux-диска

unmounted=0
errors=()

for mp in /Volumes/s*; do
  [[ -d "$mp" ]] || continue

  if mount | grep -q "ext4fuse.*$mp"; then
    echo "→ Розмонтування $mp"
    if sudo umount "$mp" 2>&1; then
      sudo rmdir "$mp" 2>/dev/null
      echo "  ✓ OK"
      ((unmounted++))
    else
      echo "  ✗ Помилка"
      errors+=("   $mp")
    fi
  fi
done

if (( unmounted == 0 && ${#errors[@]} == 0 )); then
  echo "ℹ️  Немає змонтованих ext4fuse томів"
  exit 0
fi

echo ""
echo "✓ Розмонтовано томів: $unmounted"

if (( ${#errors[@]} > 0 )); then
  echo ""
  echo "✗ Не вдалося розмонтувати:"
  printf '%s\n' "${errors[@]}"
  exit 1
fi
