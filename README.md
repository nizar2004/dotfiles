<div align="center">

# Nizar's Dotfiles & System Restore

*السيستم ديال لينكس ديالي مقاد بطريقة احترافية باستخدام Chezmoi و Arch Linux.*

[![OS](https://img.shields.io/badge/OS-Arch_Linux-blue?logo=archlinux)](https://archlinux.org)
[![Desktop](https://img.shields.io/badge/Desktop-KDE_Plasma_6-navy?logo=kde)](https://kde.org/plasma-desktop/)
[![Shell](https://img.shields.io/badge/Shell-Fish-33BF2A?logo=fish)](https://fishshell.com/)
[![Manager](https://img.shields.io/badge/Dotfiles-Chezmoi-111111?logo=chezmoi)](https://www.chezmoi.io/)

</div>

---

## ⚡ تسطالاسيون فكوموند وحدة (One-Line Restore)

يلا بغيتي ترجع السيستم ديالك، البيكاز، الكونفيغراسيون، والشورتس فـ PC جديد ولا فـ Virtual Machine، دكّز على هاد الكوموند:

```bash
sh -c "$(curl -fsLS https://raw.githubusercontent.com/nizar2004/dotfiles/main/your-script-name.sh)"

```



---

## 🛠️ أش كيقاد هاد السكريبت؟

السكريبت كيدوز من هاد المراحل بالترتيب:

1. **البرامج الضرورية:** كيمسح وكيصاوب البرامج الأساسية بحال `discord`، `papirus-icon-theme`، `git`، و `cargo` عبر `pacman`.
2. **ويجيتات ديسكتوب (KDE Plasma):** كيستالاسيو الويجيت ديال **Advanced Separator**.
3. **أدوات النظام:** كيكومپيلي وكيحط أداة **`kdotool`** مباشرة من السورس.
4. **الدوتفايلز (Chezmoi):** كيجيب ويطبق إعدادات التشغيل ديالك بطريقة أوتوماتيكية.
5. **الكوارت والأختصار:** كيقاد السكريبتات ديال الديسكورد وكيفريزي الشورتكط `Meta+Shift+D`.
6. **الخلفيات (Wallpapers):** كيسولك فالاخير واش بغيتي كلوْن الخلفيات ديال **Catppuccin Mocha** لـ `~/Pictures/wallpapers`.

---

## 📁 مناش كيتكون هاد الريپو؟

```text
.
├── install.sh         # السكريبت الرئيسي ديال التسطالاسيون
├── toggle-discord.sh  # سكريبت مساعد باش تخدم/تطفى ديسكورد
└── dot_*              # الكونفيغراسيونات والملفات اللي مسيّرين بـ Chezmoi

```
