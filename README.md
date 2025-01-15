[![Install](https://github.com/tonytech83/powershell-profile/actions/workflows/main.yml/badge.svg)](https://github.com/tonytech83/powershell-profile/actions/workflows/main.yml)
# PowerShell Profile

Feels almost as good as a Linux terminal.

![pic](pic.png)

<hr>

### 1.  Clone repo
```powershell
git clone https://github.com/tonytech83/powershell-profile.git
```

### 2. Execute `setup.ps1` as **admin**. This will install:

  - JetBrainsMono nerd font
  - Oh My Posh
  - Terminal Icons module
  - fzf
  - zoxide

### 3. Execute `setprofile.ps1` to setup profile.
```powershell
.\setprofile.ps1
```

### 4.  If you want to use my theme `my_theme.omp.json`.
```powershell
cp .\my_theme.omp.json 'C:\Program Files (x86)\oh-my-posh\themes\'
```