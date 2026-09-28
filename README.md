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

This repository restores my saved KDE Plasma configuration and helper tools with Chezmoi, and installs the packages and widgets used by that setup.



## ⚡ انسطالاسيون بكوموند وحدة
```bash
bash -o pipefail -c 'curl -fsSL https://raw.githubusercontent.com/nizar2004/dotfiles/main/install.sh | bash'
```
## 🧱 شنو اللي لازم يكون عندك قبل ما تبدأ؟

هاد الدوتفايلز كايخدمو غير فالتالي:


| Thing | Version / Details |
|---|---|
| **Operating System** | Arch Linux (or any Arch-based distro like CachyOS) |
| **Desktop** | KDE Plasma 6 |
| **Session** | Run from a logged-in Plasma 6 desktop as a regular user with `sudo` access |


## شنو كيدير السكريبت؟
- كيدير تحديث للنظام وكيثبّت `Discord`، `Asusctl`، `KDE Connect`، `Materia KDE`، `Papirus`، وملحقات Plasma وأدوات البناء.
- كيثبّت ويدجت Vertical Clock وPlasma Gnome Pager، وكيسترجع إعدادات Plasma والـ Advanced Separator من ملفات Chezmoi.
- كيبني `kdotool` إلا ما كانش مثبت.
- كيطّبق إعدادات الاختصارات والـ Discord helper، وكيجهّز أمر `backup`.

شغّل السكريبت من جلسة Plasma 6 مفتوحة. تحديث إعدادات Plasma كيعيد تشغيل `plasmashell`؛ إذا ما بانش الاختصار مباشرة، سجّل الخروج ثم الدخول.


## Achno nawi ndir mn ba3d 
- 1 : bari ndir wa7ad list ta3 apps li bari n2instalihom dima , b7al `ROG Controle Center`...
- 2 : bari mn ba3d ndir wa7ad select ta3 lapps bach nab9a nselecti lapps li barihom 
- 3 : clone llist ta3 wallpapers li ikono fnafs repo dyali , machi frepo akhra