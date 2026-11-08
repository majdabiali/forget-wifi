#!/usr/bin/env bash
# forget-wifi.sh - forget saved Wi-Fi networks before a conference or trip.
#
# Your laptop silently auto-joins any network that broadcasts a name it has
# saved ("Starbucks", "Hotel_Guest", "Airport Free WiFi"...). An attacker at a
# conference only needs to guess one of them to get you onto their network.
# This forgets every saved network except the ones you choose to keep.
#
# Works on macOS and Linux (NetworkManager). SPDX-License-Identifier: MIT
#
# Usage:  sudo ./forget-wifi.sh [-n] [-y] [-k "Network name"]...
#   -n   dry run: only list what would be forgotten
#   -y   don't ask for confirmation
#   -k   keep this network (repeat for more, e.g. home Wi-Fi, phone hotspot)
# The network you're connected to is kept automatically when it can be detected.

dry='' yes='' keep=()
while getopts "nyk:h" o; do
  case $o in
    n) dry=1 ;;
    y) yes=1 ;;
    k) keep+=("$OPTARG") ;;
    *) sed -n '2,16p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
  esac
done

case $(uname) in
  Darwin)
    IF=$(networksetup -listallhardwareports | awk '/Wi-Fi|AirPort/{getline; print $2; exit}')
    [[ -n $IF ]] || { echo "No Wi-Fi interface found." >&2; exit 1; }
    # Each line: <id> TAB <name>. On macOS the id is the name.
    list()    { networksetup -listpreferredwirelessnetworks "$IF" | tail -n +2 | sed 's/^[[:space:]]*//' | awk '{print $0 "\t" $0}'; }
    current() { ipconfig getsummary "$IF" 2>/dev/null | awk -F' SSID : ' '/ SSID : /{print $2; exit}'; }
    forget()  { networksetup -removepreferredwirelessnetwork "$IF" "$1" >/dev/null; }
    need_root=1
    ;;
  Linux)
    command -v nmcli >/dev/null || { echo "This needs NetworkManager (nmcli)." >&2; exit 1; }
    # nmcli -t escapes ':' in names as '\:'; UUID and TYPE never contain ':'.
    list()    { nmcli -t -f UUID,TYPE,NAME con show | awk '{u=$0; sub(/:.*/,"",u); r=substr($0,length(u)+2)} r ~ /^802-11-wireless:/ {sub(/^[^:]*:/,"",r); gsub(/\\:/,":",r); print u "\t" r}'; }
    current() { nmcli -t -f TYPE,NAME con show --active | awk '/^802-11-wireless:/{sub(/^[^:]*:/,""); gsub(/\\:/,":"); print; exit}'; }
    forget()  { nmcli con delete uuid "$1" >/dev/null; }
    need_root=''
    ;;
  *) echo "Unsupported OS: $(uname). Windows: run 'netsh wlan show profiles' and 'netsh wlan delete profile name=\"NAME\"'." >&2; exit 1 ;;
esac

cur=$(current)
if [[ -n $cur && $cur != "<redacted>" ]]; then
  keep+=("$cur")
else
  cur=''
fi

ids=() names=()
while IFS=$'\t' read -r id name; do
  [[ -n $id ]] || continue
  for k in "${keep[@]}"; do [[ $name == "$k" ]] && continue 2; done
  ids+=("$id"); names+=("$name")
done < <(list)

if [[ ${#names[@]} -eq 0 ]]; then echo "Nothing to forget."; exit 0; fi
printf '  %s\n' "${names[@]}"
echo "${#names[@]} saved networks will be forgotten."
[[ ${#keep[@]} -gt 0 ]] && printf 'Keeping: %s\n' "${keep[@]}"
[[ -z $cur ]] && echo "Note: couldn't detect the network you're on. If it's listed above, re-run with -k \"its name\" to keep it."

[[ -n $dry ]] && { echo "(dry run, nothing changed)"; exit 0; }
if [[ -n $need_root && $EUID -ne 0 ]]; then echo "Run with sudo to forget networks." >&2; exit 1; fi
if [[ -z $yes ]]; then
  read -rp "Forget them? [y/N] " ok </dev/tty
  [[ $ok == [yY] ]] || { echo "Nothing changed."; exit 0; }
fi

fail=0
for i in "${!ids[@]}"; do
  if forget "${ids[$i]}"; then echo "forgot: ${names[$i]}"; else echo "FAILED: ${names[$i]}"; fail=1; fi
done
echo
echo "Done. Also clean your phone: iPhone Settings > Wi-Fi > Edit; Android Settings > Network > Saved networks."
[[ $(uname) == Darwin ]] && echo "macOS: removals sync to your other Apple devices through iCloud Keychain."
exit $fail
