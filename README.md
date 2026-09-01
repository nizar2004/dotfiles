<div align="center">

# Nizar's Dotfiles & System Restore

*السيستم ديال لينكس ديالي مبني باش يبان مزيان ويسرّح الخدمة، مُقاد بـ Chezmoi على Arch Linux.*

[![OS](https://img.shields.io/badge/OS-Arch_Linux-blue?logo=archlinux)](https://archlinux.org)
[![Desktop](https://img.shields.io/badge/Desktop-KDE_Plasma_6-navy?logo=kde)](https://kde.org/plasma-desktop/)
[![Shell](https://img.shields.io/badge/Shell-Fish-33BF2A?logo=fish)](https://fishshell.com/)
[![Manager](https://img.shields.io/badge/Dotfiles-Chezmoi-111111?logo=chezmoi)](https://www.chezmoi.io/)

</div>

---

## 📋 المختصر

This repo is a complete backup of my system — from terminal configs down to wallpapers and shortcuts — fully managed by Chezmoi. The idea is that whenever you set up Linux on a new PC or a Virtual Machine, you just run one command and your system gets set up exactly the way you like it.



## ⚡ انسطالاسيون بكوموند وحدة
```bash
sh -c "$(curl -fsLS https://raw.githubusercontent.com/nizar2004/dotfiles/main/install.sh)"
```
## 🧱 شنو اللي لازم يكون عندك قبل ما تبدأ؟

هاد الدوتفايلز كايخدمو غير فالتالي:


| Thing | Version / Details |
|---|---|
| **Operating System** | Arch Linux (or any Arch-based distro like CachyOS) |
| **Desktop** | KDE Plasma 6 |


## 🛠️ شنو كيدور هاد السكريبت؟

السكريبت كيمشي على هاد المراحل بالترتيب:

### 1. 📦 البرامج الأساسية
- `Discord`
- `Asusctl`
### 2. 🧩 ويدجيتس KDE Plasma
- `Papirus-icon-theme`
- `Vertical Clock`
- `Separator`
### 3. 🔧 أدوات النظام (من السورس)
كيكمبايلي ويحط **`kdotool`** — هاد الأداة مهمة باش تحكم فـ النوافذ من الترمينال (بحال `xdotool` ولا كن KDE).

### 4. 📂 الدوتفايلز (Chezmoi)
كيجيب الكونفيغ من الغيتهوب ويطبّقه مباشرة:
- إعدادات **Fish** (الپرومپت، الألياسات، الفانكسيونات)
- إعدادات **KDE** (شورتكطات، پانيل، ويندو رولز)
- إعدادات التطبيقات الأخرى

### 5. ⌨️ الأختصارات والسكريبتات
- كيربط سكريبت **toggle-discord.sh** باش يخدم/يطفى ديسكورد بـ شورتكط `Meta+Shift+D`

### 6. 🖼️ الخلفيات
فـ الآخر كيسولك واش بغيتي تكلاوني الخلفيات ديال **Catppuccin Mocha** لـ `~/Pictures/wallpapers` — غير كتكتب `y` ولا `n`.
