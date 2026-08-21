# dotfiles

Reproducible personal Fedora Wayland configuration for Sway, Niri, or both.

## Requirements

- Fedora 44 Everything installed with automatic Btrfs partitioning.
- A working graphical environment, browser, and network connection.
- A user allowed to run `sudo`.
- Run the installation sections in order from the same terminal.

If a browser is not already installed, install one. For example, choose Firefox:

```sh
sudo dnf install firefox
```

Or install Google Chrome Stable from its signed RPM:

```sh
sudo dnf install \
  https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm
```

The browser is only used to read this guide and is not managed by the repository.

## Repository layout

```text
home/       GNU Stow package mirroring the user's home directory
etc/        Reviewed files installed under /etc
usr/        Reviewed files installed under /usr
manifest/   Fedora packages and pinned external revisions
patches/    Deltas applied to Fedora compositor and Colloid assets
profiles/   Optional filesystem-shaped hardware overlays
```

## Installation

### 1. Install Git and clone

Git and the DNF COPR command are the only bootstrap requirements:

```sh
sudo dnf install git dnf5-plugins

git clone https://github.com/topsinoty/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
```

All remaining relative paths assume the repository root is the current
directory.

### 2. Enable package sources and install packages

```sh
cd ~/.dotfiles

sudo dnf copr enable atim/starship
sudo dnf copr enable jdxcode/mise
sudo dnf copr enable lihaohong/yazi
sudo dnf copr enable alternateved/keyd

sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc &&
echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\nautorefresh=1\ntype=rpm-md\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" |
  sudo tee /etc/yum.repos.d/vscode.repo >/dev/null

dnf check-update || test $? -eq 100
xargs sudo dnf install < manifest/fedora-packages.txt
```

Starship, Mise, Yazi, and keyd use the listed Fedora COPRs. Visual Studio Code
uses Microsoft's signed RPM repository.
[nwg-displays](https://github.com/nwg-piotr/nwg-displays) is authored upstream
by nwg-piotr. It is installed separately from a pinned revision in the
[personal fork](https://github.com/topsinoty/nwg-displays), which provides the
required Niri support.

Install one or both compositor package sets:

```sh
# Sway
cd ~/.dotfiles
xargs sudo dnf install < manifest/sway-packages.txt
```

```sh
# Niri
cd ~/.dotfiles
xargs sudo dnf install < manifest/niri-packages.txt
```

### 3. Back up conflicting files on an existing home

A fresh Fedora home has no conflicts and can skip this section. Stow does not
overwrite existing application configuration, so move conflicting files out
of its target before installing external inputs or Stowing the package:

```sh
backup=$HOME/.local/state/dotfiles/manual-backup
mkdir -p "$backup/.config"

for directory in \
  dotfiles fastfetch foot fuzzel gtklock mako mpv niri sway swayidle waybar yazi \
  gtk-3.0 gtk-4.0 Kvantum; do
  source=$HOME/.config/$directory
  [ ! -e "$source" ] || mv "$source" "$backup/$directory"
done

for file in .bashrc .zshrc .gitconfig .nanorc; do
  source=$HOME/$file
  [ ! -e "$source" ] || mv "$source" "$backup/$file"
done

dconf dump /org/gnome/desktop/interface/ \
  > "$backup/gnome-interface.dconf"

[ ! -e "$HOME/.config/starship.toml" ] || \
  mv "$HOME/.config/starship.toml" "$backup/.config/starship.toml"
```

### 4. Install pinned external inputs

Load the pinned source revisions:

```sh
cd ~/.dotfiles

. ./manifest/colloid-revisions.env
. ./manifest/external-revisions.env
```

Install the exact [Nerd Fonts](https://github.com/ryanoasis/nerd-fonts)
JetBrainsMono release used by Foot, Fuzzel, Waybar, GTK, and Sway:

```sh
font_work=$(mktemp -d)
font_archive=$font_work/JetBrainsMono.tar.xz
emoji_font=$font_work/NotoColorEmoji.ttf

curl --fail --location --show-error \
  --output "$font_archive" \
  "https://github.com/ryanoasis/nerd-fonts/releases/download/v$NERD_FONTS_VERSION/JetBrainsMono.tar.xz"

printf '%s  %s\n' \
  "$NERD_FONTS_JETBRAINS_MONO_SHA256" \
  "$font_archive" | sha256sum --check

curl --fail --location --show-error \
  --output "$emoji_font" \
  "https://raw.githubusercontent.com/googlefonts/noto-emoji/$NOTO_EMOJI_REV/fonts/NotoColorEmoji.ttf"

printf '%s  %s\n' \
  "$NOTO_COLOR_EMOJI_SHA256" \
  "$emoji_font" | sha256sum --check

tar --extract --xz --file "$font_archive" --directory "$font_work"
sudo install -d /usr/local/share/fonts/JetBrainsMonoNerdFont
sudo install -m0644 "$font_work"/JetBrainsMono*.ttf \
  /usr/local/share/fonts/JetBrainsMonoNerdFont/
sudo install -Dm0644 "$emoji_font" \
  /usr/local/share/fonts/NotoColorEmoji/NotoColorEmoji.ttf
sudo fc-cache --force
rm -rf "$font_work"

fc-match 'JetBrainsMono Nerd Font Mono' \
  --format '%{family}\n%{file}\n'
```

Fetch the pinned Colloid foundations and install only the GTK dark variant and
the two Kvantum source files used by the local patch:

```sh
git clone https://github.com/topsinoty/Colloid-gtk-theme.git \
  ~/.local/src/Colloid-gtk-theme
git -C ~/.local/src/Colloid-gtk-theme checkout --detach \
  "$COLLOID_GTK_REV"
(
  cd ~/.local/src/Colloid-gtk-theme
  ./install.sh --color dark
)

git clone https://github.com/topsinoty/Colloid-kde.git \
  ~/.local/src/Colloid-kde
git -C ~/.local/src/Colloid-kde checkout --detach \
  "$COLLOID_KDE_REV"

mkdir -p ~/.config/Kvantum/ColloidNord
cp ~/.local/src/Colloid-kde/Kvantum/ColloidNord/ColloidNordDark.kvconfig \
  ~/.config/Kvantum/ColloidNord/
cp ~/.local/src/Colloid-kde/Kvantum/ColloidNord/ColloidNordDark.svg \
  ~/.config/Kvantum/ColloidNord/
```

Install the pinned `nwg-displays` source after reviewing its short installer:

```sh
git clone https://github.com/topsinoty/nwg-displays.git \
  ~/.local/src/nwg-displays
git -C ~/.local/src/nwg-displays checkout --detach \
  "$NWG_DISPLAYS_REV"

sed -n '1,240p' ~/.local/src/nwg-displays/install.sh
(
  cd ~/.local/src/nwg-displays
  sudo ./install.sh
)

nwg-displays --version
```

Fetch the pinned GPL-3.0
[Argon GRUB theme](https://github.com/stuarthayhurst/argon-grub-theme) source
from its [personal fork](https://github.com/topsinoty/argon-grub-theme). Only
the upstream installer and its 1080p `grey` design are used:

```sh
git clone https://github.com/topsinoty/argon-grub-theme.git \
  ~/.local/src/argon-grub-theme
git -C ~/.local/src/argon-grub-theme checkout --detach \
  "$ARGON_GRUB_REV"
```

The forks preserve the pinned source but do not replace attribution to the
original projects. Colloid wallpapers and desktop packages are not installed,
and no third-party assets are copied into this repository. Yazi and its
official `mount.yazi` plugin continue to use their normal upstream package
sources rather than personal forks.

Make Zsh the login shell:

```sh
chsh -s "$(command -v zsh)"
```

Both shell startup files activate Starship, Zoxide, Fzf, and Mise. Zsh also
loads autosuggestions and syntax highlighting. Bash and Zsh retain 100,000
commands in persistent history, which backs Fzf's `Ctrl+R` search across
sessions.

### 5. Install system integration

Install the system-level Ctrl-Alt-Delete fallback, then start keyd:

```sh
cd ~/.dotfiles

sudo install -Dm0755 usr/local/libexec/dotfiles-session-rescue \
  /usr/local/libexec/dotfiles-session-rescue
sudo install -Dm0644 etc/keyd/dotfiles-emergency.conf \
  /etc/keyd/dotfiles-emergency.conf
sudo keyd check /etc/keyd/dotfiles-emergency.conf
sudo systemctl enable --now keyd
```

keyd receives the chord independently of the compositor. The helper asks a
responsive Sway or Niri instance to start Wlogout inside the active graphical
session. If neither supported compositor responds, it asks logind to terminate
only that session. It discovers the seat, session, user, runtime directory, and
compositor socket at runtime.

Inspect rescue decisions with `sudo journalctl -t dotfiles-session-rescue`.

Install the DNF and greetd files:

```sh
cd ~/.dotfiles

if sudo test -e /etc/greetd/config.toml && \
  ! sudo test -e /etc/greetd/config.toml.before-dotfiles; then
  sudo cp -a /etc/greetd/config.toml \
    /etc/greetd/config.toml.before-dotfiles
fi

sudo install -Dm0644 etc/dnf/libdnf5.conf.d/80-dotfiles.conf \
  /etc/dnf/libdnf5.conf.d/80-dotfiles.conf
sudo install -Dm0644 etc/greetd/config.toml /etc/greetd/config.toml
sudo install -Dm0644 etc/environment.d/80-dotfiles.conf \
  /etc/environment.d/80-dotfiles.conf

sudo localectl set-x11-keymap 'us,ee' '' '' 'grp:alt_shift_toggle'
sudo systemctl enable --now NetworkManager bluetooth power-profiles-daemon
```

The DNF drop-in changes only the default prompt answer and parallel download
count. Tuigreet discovers the installed session desktop files and remembers the
last session per user. Fedora's greetd PAM policy already contains the GNOME
Keyring hooks; the manifest supplies `gnome-keyring-pam` so the login password
can unlock the Default keyring with the session.

Before enabling greetd, disable the machine's current display manager, then
enable greetd for the next boot:

```sh
sudo systemctl enable greetd
sudo systemctl set-default graphical.target
```

Do not stop the active display manager from inside the graphical session.

### 6. Configure recovery and boot presentation

These recovery commands require separate Btrfs subvolumes for `/` and `/home`,
as created by Fedora's automatic Btrfs partitioning. Snapper protects against
bad upgrades and accidental file changes, while a monthly scrub detects
damaged data. Local snapshots are recovery points, not backups against drive
loss.

The package manifest installs Snapper, Btrfs Maintenance, Btrfs Assistant, and
Fedora's upstream Plymouth spinner.

Create each Snapper configuration once, then apply bounded retention:

```sh
sudo snapper -c root create-config /
sudo snapper -c home create-config /home

for config in root home; do
  sudo snapper -c "$config" set-config \
    'TIMELINE_CREATE=yes' \
    'TIMELINE_CLEANUP=yes' \
    'NUMBER_CLEANUP=yes' \
    'NUMBER_LIMIT=10' \
    'NUMBER_LIMIT_IMPORTANT=5' \
    'TIMELINE_LIMIT_HOURLY=6' \
    'TIMELINE_LIMIT_DAILY=7' \
    'TIMELINE_LIMIT_WEEKLY=4' \
    'TIMELINE_LIMIT_MONTHLY=3' \
    'TIMELINE_LIMIT_YEARLY=0' \
    'SPACE_LIMIT=0.2' \
    'FREE_LIMIT=0.2'
done

sudo systemctl enable --now snapper-timeline.timer snapper-cleanup.timer
sudo systemctl enable --now btrfs-scrub.timer
```

Confirm the configurations, timers, and current filesystem usage:

```sh
sudo snapper list-configs
sudo snapper -c root list
sudo snapper -c home list
systemctl status \
  snapper-timeline.timer \
  snapper-cleanup.timer \
  btrfs-scrub.timer
sudo btrfs filesystem usage /
```

Create an important recovery point before a risky manual change:

```sh
sudo snapper -c root create \
  --description 'before manual system change' \
  --cleanup-algorithm number \
  --userdata important=yes
```

The repository does not add snapshot entries to GRUB. Fedora's rescue kernel
remains independent, and snapshots can be inspected or restored with Snapper,
Btrfs Assistant, or a Fedora live USB without making the bootloader depend on
the snapshot tool.

Install the complete pinned Argon Grey theme with its upstream icons, selection
graphics, font, spacing, and countdown. Argon's installer writes a GRUB drop-in
that Fedora does not read, so remove that inert file and apply the narrow Fedora
patch after saving `/etc/default/grub`. Then select Fedora's stock Plymouth
spinner and regenerate the derived files:

```sh
cd ~/.dotfiles

if sudo test -e /boot/grub2/splash0.png && \
  ! sudo test -e /boot/grub2/splash0.png.before-dotfiles; then
  sudo cp --archive /boot/grub2/splash0.png \
    /boot/grub2/splash0.png.before-dotfiles
fi

(
  cd ~/.local/src/argon-grub-theme
  sudo ./install.sh \
    --install \
    --boot \
    --background grey \
    --resolution 1080p \
    --icons coloured \
    --font /usr/local/share/fonts/JetBrainsMonoNerdFont/JetBrainsMonoNerdFontMono-Regular.ttf \
    --fontcolour '#D7E0E7,#030609,#647582' \
    --fontsize 24 \
    --help-label \
    --auto
)

sudo rm -f /etc/default/grub.d/argon.cfg

if ! sudo test -e /etc/default/grub.before-dotfiles; then
  sudo cp --archive /etc/default/grub \
    /etc/default/grub.before-dotfiles
fi
sudo patch /etc/default/grub < patches/fedora-grub.patch
sudo grub2-mkconfig -o /boot/grub2/grub.cfg
sudo plymouth-set-default-theme -R spinner
```

Validate the generated boot configuration and selected Plymouth theme:

```sh
sudo grub2-script-check /boot/grub2/grub.cfg
sudo grep -F '/boot/grub2/themes/argon/theme.txt' \
  /boot/grub2/grub.cfg
sudo test -e /boot/grub2/themes/argon/icons/fedora.png
test "$(plymouth-set-default-theme)" = spinner
```

The GRUB patch selects the unmodified Argon theme, requests recovery-mode
entries, and keeps Fedora's flat menu so older kernels and the Fedora rescue
image remain directly visible. Argon's help label documents `E` for editing a
boot entry and `C` for opening the GRUB terminal. Fedora's BLS, saved default,
timeout, and kernel command line stay intact. Plymouth remains an unmodified
Fedora package.

### 7. Stow authored files

From the repository root:

```sh
cd ~/.dotfiles

stow --no-folding --target="$HOME" home
dotfiles-vscode-setup apply
ya pkg install
```

`--no-folding` is required so generated files cannot be written through a
directory symlink into the repository.

The VS Code helper recursively merges the small authored settings layer into
the existing user settings instead of replacing them. The layer follows the
desktop's dark-mode preference, shares the GTK, Foot, Sway, and Niri palette,
and selects the pinned JetBrainsMono Nerd Font. The helper keeps a one-time copy
of the pre-merge settings under `~/.local/state/dotfiles/vscode` for reversal;
profiles, extensions, and transient state remain owned by VS Code.

Yazi installs the pinned official `mount.yazi` package into its generated local
plugin directory. Press `M` in Yazi to mount, unmount, or eject through UDisks.
PCManFM uses the same UDisks/GVfs state for graphical device, Trash, MTP,
camera, and network-location management. Neither file manager starts a separate
automount daemon.

### 8. Build the compositor bases

Complete the subsection for every installed compositor. The laptop profile is
for the built-in `eDP-1` display at scale 1; skip its `install` command on other
hardware and let `nwg-displays` generate the local output configuration.

#### Sway

```sh
cd ~/.dotfiles

mkdir -p ~/.config/dotfiles/hardware.d
install -Dm0644 profiles/laptop/home/.config/sway/outputs \
  ~/.config/sway/outputs
touch ~/.config/sway/workspaces ~/.config/dotfiles/hardware.d/sway.conf
mkdir -p ~/.config/sway/generated
cp /etc/sway/config ~/.config/sway/generated/base.conf
patch ~/.config/sway/generated/base.conf < patches/sway-stock.patch
```

The patch removes exactly three stock declarations that local modules replace:
the launcher variable, wallpaper, and built-in swaybar. Fedora's remaining
settings and keybindings stay unchanged.

`nwg-displays` writes hardware-specific output files locally. Sway includes its
generated `~/.config/sway/outputs` and `~/.config/sway/workspaces` files; Niri
uses `~/.config/niri/monitor.kdl` and adds its native include itself. Generate
them only when the display layout needs changing. They are not repository
inputs.

#### Niri

```sh
cd ~/.dotfiles

install -Dm0644 profiles/laptop/home/.config/niri/dotfiles-hardware.kdl \
  ~/.config/niri/dotfiles-hardware.kdl
cp /usr/share/doc/niri/default-config.kdl ~/.config/niri/config.kdl
patch ~/.config/niri/config.kdl < patches/niri-stock.patch
```

The patch removes duplicate stock bindings, the stock Swaylock binding, and
stock Waybar startup. It includes the dotfiles graph last so its fragments can
override the remaining base. Local hardware includes stay outside Git.

### 9. Select Colloid and load the GTK override

Select the installed Colloid GTK 3 theme and the existing system icon and
cursor themes:

```sh
gsettings set org.gnome.desktop.interface gtk-theme 'Colloid-Dark'
gsettings set org.gnome.desktop.interface icon-theme 'Adwaita'
gsettings set org.gnome.desktop.interface cursor-theme 'Adwaita'
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
gsettings set org.gnome.desktop.interface font-name 'Noto Sans 11'
```

GTK 4 does not select named GTK themes. Generate its Colloid foundation from
the installed theme, remove the three colors owned by the override, then load
the small authored layer:

```sh
cp ~/.themes/Colloid-Dark/gtk-4.0/gtk.css \
  ~/.config/gtk-4.0/gtk-colloid.css
sed -i \
  -e '/^@define-color accent_bg_color /d' \
  -e '/^@define-color accent_fg_color /d' \
  -e '/^@define-color accent_color /d' \
  ~/.config/gtk-4.0/gtk-colloid.css
```

The GTK 3 theme provides the complete foundation through theme selection. GTK
4's generated `gtk-colloid.css` remains local. The tracked GTK import files load
the shared authored override.

### 10. Build the local Kvantum variant

Copy the installed Colloid files, then apply only the recorded deltas:

```sh
cd ~/.dotfiles

mkdir -p ~/.config/Kvantum/ColloidNordDark-dotfiles
cp ~/.config/Kvantum/ColloidNord/ColloidNordDark.kvconfig \
  ~/.config/Kvantum/ColloidNordDark-dotfiles/ColloidNordDark-dotfiles.kvconfig
cp ~/.config/Kvantum/ColloidNord/ColloidNordDark.svg \
  ~/.config/Kvantum/ColloidNordDark-dotfiles/ColloidNordDark-dotfiles.svg
patch ~/.config/Kvantum/ColloidNordDark-dotfiles/ColloidNordDark-dotfiles.kvconfig \
  < patches/kvantum-config.patch
patch ~/.config/Kvantum/ColloidNordDark-dotfiles/ColloidNordDark-dotfiles.svg \
  < patches/kvantum-svg.patch
```

These generated files are intentionally outside Git.

### 11. Configure optional user choices

Optionally reapply the browser already selected by the desktop to web content:

```sh
dotfiles-mime-setup
```

Optionally configure location-dependent night light:

```sh
dotfiles-location-setup
```

The location command performs one bounded IP lookup, asks for confirmation,
supports manual fallback, and stores only coordinates in the local untracked
`~/.config/dotfiles/location.env`. Wlsunset remains off when that file is absent.

Sway and Niri start Mako, Swayidle, playerctld, clipboard watchers, Blueman, the
MATE Polkit authentication agent, and optional Wlsunset directly. Their idle
files differ only where each compositor's native display-power command differs.
Waybar configurations share presentation and ordinary modules while retaining
native workspace, window, and language modules.

## Static validation

```sh
cd ~/.dotfiles

xargs rpm -q < manifest/fedora-packages.txt
if command -v sway >/dev/null; then
  xargs rpm -q < manifest/sway-packages.txt
fi
if command -v niri >/dev/null; then
  xargs rpm -q < manifest/niri-packages.txt
fi
test "$(fc-match 'JetBrainsMono Nerd Font Mono' --format '%{family[0]}')" = \
  'JetBrainsMono Nerd Font Mono'
test -n "$(xdg-settings get default-web-browser)"
test "$(gsettings get org.gnome.desktop.interface gtk-theme)" = \
  "'Colloid-Dark'"
test "$(gsettings get org.gnome.desktop.interface font-name)" = \
  "'Noto Sans 11'"
grep -qxF 'QT_STYLE_OVERRIDE=kvantum' /etc/environment.d/80-dotfiles.conf
python3 -m json.tool ~/.config/dotfiles/vscode-settings.json >/dev/null
python3 -m json.tool ~/.config/Code/User/settings.json >/dev/null

foot --check-config --config="$HOME/.config/foot/foot.ini"
fuzzel --check-config --config="$HOME/.config/fuzzel/fuzzel.ini"
python3 -m json.tool ~/.config/waybar/common.jsonc >/dev/null
python3 -m json.tool ~/.config/waybar/sway.jsonc >/dev/null
python3 -m json.tool ~/.config/waybar/niri.jsonc >/dev/null
python3 -c 'import pathlib, tomllib; tomllib.loads(pathlib.Path.home().joinpath(".config/starship.toml").read_text())'
bash -n ~/.bashrc
zsh -n ~/.zshrc
nano --rcfile ~/.nanorc --version >/dev/null
yazi --debug >/dev/null
if command -v niri >/dev/null; then
  niri validate
fi
dnf --dump-main-config | grep -E '^(defaultyes|max_parallel_downloads) ='
sudo keyd check /etc/keyd/dotfiles-emergency.conf
systemctl is-enabled \
  greetd \
  keyd \
  bluetooth \
  power-profiles-daemon \
  snapper-timeline.timer \
  snapper-cleanup.timer \
  btrfs-scrub.timer
```

Inspect desktop helper decisions with:

```sh
journalctl -t dotfiles-microphone \
  -t dotfiles-wlsunset
```

Fastfetch is configured but never runs automatically. MPV is Yazi's explicit
audio/video opener and has no forced starting volume. PCManFM is available from
Fuzzel as a Colloid-styled GUI alternative but never manages the desktop or
wallpaper.

Reboot after all static checks pass:

```sh
sudo reboot
```

## First login validation

Log into an installed compositor from Tuigreet, then confirm the shared desktop
services:

```sh
systemctl --user is-active \
  xdg-desktop-portal.service \
  xdg-desktop-portal-gtk.service

pgrep -af \
  'mako|swayidle|playerctld|blueman-applet|polkit-mate-authentication-agent-1'
```

Under Sway, validate and reload its active configuration:

```sh
systemctl --user is-active xdg-desktop-portal-wlr.service
swaymsg -t get_version
sway -C -c ~/.config/sway/config
swaymsg reload
```

Under Niri, confirm that its IPC is available:

```sh
systemctl --user is-active xdg-desktop-portal-gnome.service
niri msg version
```

The location file is optional and machine-specific. `nwg-displays` is also
on-demand: run it only when output layout needs configuring, then validate the
generated file with `sway -C` or `niri validate`.

## Maintenance

### Updating Fedora or Colloid inputs

Re-copy the packaged Sway or Niri base, or the installed Colloid assets, and
reapply the corresponding patch. If `patch` rejects a hunk, inspect the upstream
change and refresh the patch instead of forcing it. Update a revision manifest
only after reviewing its source and the affected patch or checksum.

### Migrating an existing configuration

Before Stowing:

1. Restore the complete Colloid GTK stylesheet as the GTK foundation.
2. Remove copied theme directories and their GTK imports.
3. Remove wallpaper references and swaylock configuration.
4. Back up and remove standalone Foot, Fuzzel, Mako, Waybar, Yazi, and gtklock
   files that would conflict with Stow.
5. Follow the relevant compositor, GTK, and Kvantum patch steps above.

Keep generated output in `~/.config`; the repository contains only authored
configuration and reviewable patches.

## Reverting

Remove the generated package and integration state before unstowing:

```sh
cd ~/.dotfiles

ya pkg delete yazi-rs/plugins:mount
dotfiles-vscode-setup restore

rm -f ~/.config/sway/generated/base.conf \
  ~/.config/sway/outputs \
  ~/.config/sway/workspaces \
  ~/.config/dotfiles/hardware.d/sway.conf \
  ~/.config/niri/config.kdl \
  ~/.config/niri/dotfiles-hardware.kdl \
  ~/.config/niri/monitor.kdl \
  ~/.config/gtk-4.0/gtk-colloid.css \
  ~/.config/dotfiles/location.env

rm -f ~/.config/Kvantum/ColloidNordDark-dotfiles/ColloidNordDark-dotfiles.kvconfig \
  ~/.config/Kvantum/ColloidNordDark-dotfiles/ColloidNordDark-dotfiles.svg
rmdir ~/.config/Kvantum/ColloidNordDark-dotfiles

stow --delete --no-folding --target="$HOME" home
```

Stow may leave empty directories created by `--no-folding`; they contain no
managed files. Restore any files saved from an existing home:

```sh
backup=$HOME/.local/state/dotfiles/manual-backup

for directory in \
  dotfiles fastfetch foot fuzzel gtklock mako mpv niri sway swayidle waybar yazi \
  gtk-3.0 gtk-4.0 Kvantum; do
  [ ! -e "$backup/$directory" ] || \
    cp -a "$backup/$directory" ~/.config/
done

for file in .bashrc .zshrc .gitconfig .nanorc; do
  [ ! -e "$backup/$file" ] || cp -a "$backup/$file" "$HOME/$file"
done

[ ! -e "$backup/.config/starship.toml" ] || \
  cp -a "$backup/.config/starship.toml" ~/.config/starship.toml

[ ! -s "$backup/gnome-interface.dconf" ] || \
  dconf load /org/gnome/desktop/interface/ \
    < "$backup/gnome-interface.dconf"
```

Restoring the Kvantum directory also restores its previous selected theme.

Before disabling greetd, enable the display manager that should handle the next
login. Then remove the system-owned additions:

```sh
sudo systemctl disable greetd keyd
sudo systemctl disable --now \
  snapper-timeline.timer snapper-cleanup.timer btrfs-scrub.timer

sudo rm /etc/dnf/libdnf5.conf.d/80-dotfiles.conf \
  /etc/keyd/dotfiles-emergency.conf \
  /usr/local/libexec/dotfiles-session-rescue \
  /etc/environment.d/80-dotfiles.conf

sudo rm -rf /boot/grub2/themes/argon

if sudo test -e /boot/grub2/splash0.png.before-dotfiles; then
  sudo mv /boot/grub2/splash0.png.before-dotfiles \
    /boot/grub2/splash0.png
else
  sudo rm -f /boot/grub2/splash0.png
fi

sudo mv /etc/default/grub.before-dotfiles /etc/default/grub

sudo grub2-mkconfig -o /boot/grub2/grub.cfg
sudo plymouth-set-default-theme --reset -R

sudo localectl set-x11-keymap us

if sudo test -e /etc/greetd/config.toml.before-dotfiles; then
  sudo mv /etc/greetd/config.toml.before-dotfiles /etc/greetd/config.toml
else
  sudo rm /etc/greetd/config.toml
fi
```

Remove the source-installed display utility and system-wide fonts only when
they are not used by another configuration:

```sh
if [ -d ~/.local/src/nwg-displays ]; then
  (
    cd ~/.local/src/nwg-displays
    sudo ./uninstall.sh
  )
fi

sudo rm -f \
  /usr/bin/nwg-displays-apply \
  /usr/bin/nwg-displays-toggle-wallpapers \
  /usr/share/applications/nwg-displays.desktop \
  /usr/share/pixmaps/nwg-displays.svg
sudo rm -rf \
  /usr/share/doc/nwg-displays \
  /usr/share/licenses/nwg-displays \
  /usr/local/share/fonts/JetBrainsMonoNerdFont \
  /usr/local/share/fonts/NotoColorEmoji
sudo fc-cache --force
```

Delete the `root` or `home` Snapper configuration only after reviewing and
removing any snapshots that are still needed. Removing the repository does not
silently destroy recovery points.

Disable `bluetooth` or `power-profiles-daemon` only if this setup enabled them
on a machine where they were previously disabled.

## Design notes and attribution

The desktop theme is layered over
[Colloid GTK](https://github.com/vinceliuice/Colloid-gtk-theme) and
[Colloid KDE](https://github.com/vinceliuice/Colloid-kde) by Vince Liuice.
Personal GitHub forks keep the pinned sources available independently of the
upstream repositories.

This repository is not a standalone theme and does not claim authorship over
Colloid. GTK supports cascading CSS, so the GTK files contain a small override.
Kvantum cannot inherit another theme in the same way, so its local variant is
created by applying the recorded patches to `ColloidNordDark`. The resulting
files remain subject to Colloid's GPL-3.0 license. Original files in this
repository are published without a license.

Small helpers under `home/.local/bin` cover actions that cannot be expressed
cleanly in application configuration. Compositors start normal session programs
directly; there is no custom service manager or portability framework.

The Stow package also owns shell startup files, Git, Starship, and Nano
configuration. Revision manifests pin external fonts, the `nwg-displays` fork,
Colloid foundations, and Argon artwork for reproducible restoration.

Sway uses a tracked include graph around a generated base patched from Fedora's
packaged config. The repository intentionally contains no wallpaper, swaylock
configuration, full replacement Sway base, or copied Colloid SVG assets.
