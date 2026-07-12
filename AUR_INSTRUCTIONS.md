# 📦 Arch Linux Packaging (AUR)

This guide explains how to make your project available via `yay -S anodemcu-git`.

## 1. Test Locally

Before submitting to the AUR, verify that the `PKGBUILD` works on your system.

```bash
# Navigate to project root
cd /home/dexter/Arduino/arduino-cli-manager

# Build and install locally (this will ask for sudo password to install dependencies)
makepkg -si
```

This will:

- Clone your GitHub repo.
- Package it for Arch.
- Install it to `/usr/bin/anodemcu`.
- Install dependencies like `arduino-cli`.

---

## 2. Submit to AUR (Arch User Repository)

### Step A: Setup AUR Account

1. Create an account at [aur.archlinux.org](https://aur.archlinux.org/).
2. Add your **SSH Public Key** to your AUR profile settings.

### Step B: Clone the (Empty) AUR Repository

On your terminal:

```bash
# Clone the (currently empty) AUR repo to a temp folder
git clone ssh://aur@aur.archlinux.org/anodemcu-git.git /tmp/anodemcu-aur
```

### Step C: Prepare and Push

```bash
# Copy your PKGBUILD to the AUR repo folder
cp /home/dexter/Arduino/arduino-cli-manager/PKGBUILD /tmp/anodemcu-aur/

# Navigate to the AUR repo folder
cd /tmp/anodemcu-aur

# Generate .SRCINFO (REQUIRED for AUR)
makepkg --printsrcinfo > .SRCINFO

# Commit and Push
git add PKGBUILD .SRCINFO
git commit -m "Initial AUR submission"
git push origin master
```

---

## 3. Important: Updating the Package

Whenever you push new code to your GitHub repository:

- You don't **need** to update the AUR package immediately (since it's a `-git` package, it automatically pulls the latest master when users install/update).
- However, if you change **dependencies** or the **description**, you must update the `PKGBUILD` in the AUR repo, regenerate `.SRCINFO`, and push again.

## 4. How users will install it

Once pushed, users can install it using:

```bash
yay -S anodemcu-git
```

(Since we added `provides=("anodemcu")`, they can also just use `yay -S anodemcu`).
