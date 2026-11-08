# forget-wifi

Forget the Wi-Fi networks your laptop has saved before you go to a conference, airport or hotel.

## Why

Your laptop remembers every network you have ever joined: the café, the hotel, the airport lounge, a friend's hotspot. When it sees one of those names again, it **joins automatically, without asking**.

Anyone can broadcast a Wi-Fi network with any name. At a tech conference someone only has to set up "Starbucks", "Hotel_Guest" or "Airport Free WiFi", and every laptop that has ever used a network with that name connects to them. This is called an *evil twin* or *karma* attack. It's cheap, it's common at large events, and you won't notice it happening.

The fix is to have your laptop remember nothing except the networks you trust. This script does that in one command.

## Use

It always shows you the list and asks before deleting anything. Start with a dry run.

**macOS / Linux**

```bash
curl -O https://raw.githubusercontent.com/majdabiali/forget-wifi/main/forget-wifi.sh
chmod +x forget-wifi.sh

./forget-wifi.sh -n                                   # dry run: just list them
sudo ./forget-wifi.sh -k "Home WiFi" -k "My iPhone"   # forget all except these
```

**Windows** (open PowerShell **as Administrator**)

```powershell
Invoke-WebRequest https://raw.githubusercontent.com/majdabiali/forget-wifi/main/forget-wifi.ps1 -OutFile forget-wifi.ps1
powershell -ExecutionPolicy Bypass -File .\forget-wifi.ps1 -DryRun
powershell -ExecutionPolicy Bypass -File .\forget-wifi.ps1 -Keep "Home WiFi","My iPhone"
```

| Option | macOS / Linux | Windows |
|---|---|---|
| Dry run, change nothing | `-n` | `-DryRun` |
| Keep a network (repeatable) | `-k "Name"` | `-Keep "Name1","Name2"` |
| Skip the confirmation | `-y` | `-Yes` |

The network you are connected to right now is kept automatically. The exception is recent macOS versions, which hide the current network's name from scripts. There, the script tells you to add it with `-k`.

You'll need the password again the next time you join any network you forgot.

## Your phone too

The script covers laptops. Clear your phone by hand. It takes a minute.

- **iPhone:** Settings → Wi-Fi → **Edit** (top right) → remove the ones you don't need. Then set **Ask to Join Networks** and **Auto-Join Hotspot** to **Ask**.
- **Android:** Settings → Network & internet → Internet → **Saved networks** → remove them.

On macOS, networks removed on the Mac are also removed from your iPhone and iPad if iCloud Keychain is on.

## At the conference

Forgetting networks closes the auto-join hole. A few habits cover the rest:

- **Use your phone's hotspot rather than conference Wi-Fi** when you can.
- **Use a VPN on any shared Wi-Fi**: a commercial one, your company's, or your own (Tailscale or WireGuard back to home). If you join a login-page network, log in first, then turn the VPN on.
- **Never accept a prompt to install a certificate or "profile"** from a Wi-Fi login page.
- Turn off AirDrop or Nearby Share, or set it to contacts only. Turn off Bluetooth when you're not using it.
- Charge from your own plug, not a USB port in a charging station.

## Requirements

- **macOS:** built-in `networksetup`. Needs `sudo` to delete.
- **Linux:** NetworkManager (`nmcli`), the default on Ubuntu, Fedora, Debian desktop, Mint and Pop!_OS. Systems using `iwd` or `wpa_supplicant` directly aren't supported.
- **Windows:** built-in `netsh`. Run from an Administrator PowerShell. Networks pushed by your employer's Group Policy can't be removed and aren't touched.

## Status

Tested on macOS and on Linux with NetworkManager. The Windows script's parsing was tested against English and German `netsh` output, but it hasn't yet been run on a Windows machine. Please open an issue if anything misbehaves.

## License

MIT
