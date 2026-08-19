# dotfiles

Personal Fedora and Sway configuration layered over
[Colloid GTK](https://github.com/vinceliuice/Colloid-gtk-theme) and
[Colloid KDE](https://github.com/vinceliuice/Colloid-kde) by Vince Liuice.

This is not a standalone theme and does not claim authorship over Colloid. GTK
supports cascading CSS, so the GTK part of this repository contains only a
small override. Kvantum cannot inherit another theme in the same way, so the Qt
variant is produced locally by applying AI-assisted color patches to an
installed copy of `ColloidNordDark`. The resulting files are modified Colloid
works and remain subject to Colloid's GPL-3.0 license.

The original files in this repository are published without a license.

## Layout

```text
dotfiles/   GNU Stow package containing authored configuration
manifest/   Fedora package checklist
patches/    Deltas applied to Fedora Sway and installed Colloid assets
```

Executable helpers live under `dotfiles/.local/bin`. They keep shell logic out
of Sway bindings and are installed through the same Stow package.

`manifest/colloid-revisions.env` pins the upstream revisions against which the
GTK override and Kvantum patches were tested. These were the upstream `HEAD`
revisions on 2026-08-19. A newer checkout is an intentional upgrade, not a
reproducible restoration target.

Sway is composed from independent modules:

```text
~/.config/sway/config
├── conf.d/settings.conf
├── generated/base.conf      patched from /etc/sway/config
├── conf.d/input.conf
├── conf.d/keybinds.conf
├── conf.d/windows.conf
├── conf.d/theme.conf
└── conf.d/extensions.conf
```

The repository contains no wallpaper, swaylock configuration, full replacement
Sway config, or copied Colloid SVG.

## Fresh Fedora installation

### 1. Install dependencies

```sh
sudo dnf install sway waybar foot fuzzel mako gtklock stow patch git fontconfig \
  sassc gtk-murrine-engine xdg-utils grim slurp brightnessctl playerctl \
  wl-clipboard cliphist pavucontrol NetworkManager-connection-editor libnotify
sudo dnf copr enable lihaohong/yazi
sudo dnf install yazi
```

Clone this repository, then fetch and install the pinned Colloid inputs:

```sh
mkdir -p ~/.local/src
git clone https://github.com/topsinoty/dotfiles.git ~/.local/src/dotfiles
cd ~/.local/src/dotfiles

. ./manifest/colloid-revisions.env

git clone https://github.com/vinceliuice/Colloid-gtk-theme.git \
  ~/.local/src/Colloid-gtk-theme
git -C ~/.local/src/Colloid-gtk-theme checkout --detach \
  "$COLLOID_GTK_REV"
(
  cd ~/.local/src/Colloid-gtk-theme
  ./install.sh --color dark
)

git clone https://github.com/vinceliuice/Colloid-kde.git \
  ~/.local/src/Colloid-kde
git -C ~/.local/src/Colloid-kde checkout --detach \
  "$COLLOID_KDE_REV"
mkdir -p ~/.config/Kvantum/ColloidNord
cp ~/.local/src/Colloid-kde/Kvantum/ColloidNord/ColloidNordDark.kvconfig \
  ~/.config/Kvantum/ColloidNord/
cp ~/.local/src/Colloid-kde/Kvantum/ColloidNord/ColloidNordDark.svg \
  ~/.config/Kvantum/ColloidNord/
```

Only the two required Kvantum inputs are copied from Colloid KDE; its wallpaper
and other desktop packages are not installed.

Install `JetBrainsMono Nerd Font Mono` system-wide using the normal font
installation method for the machine. The family name must match exactly.

### 2. Back up conflicting files

Stow will not overwrite existing application configs. Back up any existing
configuration before moving conflicting files out of the Stow target:

```sh
mkdir -p ~/.local/state/dotfiles/manual-backup
cp -a ~/.config/sway ~/.config/gtk-3.0 ~/.config/gtk-4.0 \
  ~/.config/Kvantum ~/.local/state/dotfiles/manual-backup/ 2>/dev/null || true
```

### 3. Stow authored files

From the repository root:

```sh
stow --no-folding --target="$HOME" dotfiles
```

`--no-folding` is required so generated files cannot be written through a
directory symlink into the repository.

### 4. Build the stock Sway base

The checked-in Sway config is only an include graph. Build its base from the
currently installed Fedora config and apply the small patch:

```sh
mkdir -p ~/.config/sway/generated
cp /etc/sway/config ~/.config/sway/generated/base.conf
patch ~/.config/sway/generated/base.conf < patches/sway-stock.patch
```

The patch removes exactly three stock declarations that local modules replace:
the launcher variable, wallpaper, and built-in swaybar. Fedora's remaining
settings and keybindings stay unchanged.

### 5. Load the GTK override

Colloid remains the complete GTK foundation. Add this line once at the end of
both `~/.config/gtk-3.0/gtk.css` and `~/.config/gtk-4.0/gtk.css`:

```css
@import url("../dotfiles/gtk.css");
```

If either file does not exist, create it with only that import.

### 6. Build the local Kvantum variant

Copy the installed Colloid files, then apply only the recorded deltas:

```sh
mkdir -p ~/.config/Kvantum/PersonalColloid
cp ~/.config/Kvantum/ColloidNord/ColloidNordDark.kvconfig \
  ~/.config/Kvantum/PersonalColloid/PersonalColloid.kvconfig
cp ~/.config/Kvantum/ColloidNord/ColloidNordDark.svg \
  ~/.config/Kvantum/PersonalColloid/PersonalColloid.svg
patch ~/.config/Kvantum/PersonalColloid/PersonalColloid.kvconfig \
  < patches/kvantum-config.patch
patch ~/.config/Kvantum/PersonalColloid/PersonalColloid.svg \
  < patches/kvantum-svg.patch
printf '[General]\ntheme=PersonalColloid\n' \
  > ~/.config/Kvantum/kvantum.kvconfig
```

These generated files are intentionally outside Git.

### 7. Validate and reload

```sh
foot --check-config --config="$HOME/.config/foot/foot.ini"
fuzzel --check-config --config="$HOME/.config/fuzzel/fuzzel.ini"
python3 -m json.tool ~/.config/waybar/config.jsonc >/dev/null
yazi --debug >/dev/null
sway -C -c ~/.config/sway/config
swaymsg reload
```

## Updating after Fedora or Colloid changes

Re-copy `/etc/sway/config` or the installed Colloid assets and reapply the
corresponding patch. If `patch` rejects a hunk, inspect the upstream change and
refresh that patch instead of forcing it. When adopting a new Colloid release,
update `manifest/colloid-revisions.env` in the same commit as the reviewed
patches. Do not move the pins merely because upstream has advanced.

## Reverting

Restore the manual backup, or remove the generated Sway and Kvantum files and
then unstow the authored files:

```sh
stow --delete --no-folding --target="$HOME" dotfiles
```

## Migrating the earlier local setup

Before Stowing:

1. Restore the complete Colloid GTK stylesheet as the GTK foundation.
2. Remove the previous copied theme directory and its GTK import.
3. Remove the previous wallpaper reference and swaylock configuration.
4. Back up and remove standalone Foot, Fuzzel, Mako, Waybar, Yazi, and gtklock
   files that would conflict with Stow.
5. Follow the Sway, GTK, and Kvantum patch steps above.

The final repository contains only authored configs and reviewable patches;
generated output stays in `~/.config`.
