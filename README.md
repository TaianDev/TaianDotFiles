# 🌌 CachyOS Dynamic Rice: Matugen Integration

This repository contains my personal dotfiles for **CachyOS**, focused on a deep, automated integration between **Matugen** and my core workflow. The goal is to achieve a consistent, dynamic, and clean aesthetic that adapts to any wallpaper.

---

## 🎨 Theming Philosophy: Dynamic Glassmorphism

Everything is driven by **Material Design 3** color extraction. I've moved away from static themes to a system where **Matugen** dictates the colors, and my custom templates handle the transparency and layout.

### 🖼️ Core Components
* **Wallpapers:** Updated collection of high-resolution assets optimized for vibrant color extraction.
* **Fastfetch:** Stripped down to a minimalist layout. Only essential system data is displayed to maintain a clean terminal fetch.
* **Kitty + NvChad:** Terminal transparency has been fine-tuned to work seamlessly with **NvChad**, allowing the background blur to be visible without compromising code legibility.

---

## 🛠️ Implementation Details

### 1. Application Templates (Matugen)
Custom templates ensure that my most-used CLI and GUI tools stay in sync:
* **Yazi & Btop:** Dynamic color injection for the file manager and system monitor.
* **Hyprwave:** Audio visualization that respects the system's generated palette.
* **GTK 3/4:** A complete overhaul of the native CSS templates:
    * **60% Opacity:** Applied via native GTK `alpha()` functions for a consistent glass look.
    * **Fixes:** Resolved "black block" issues in lists and treeviews (Blueman/Thunar).
    * **Clean Switches:** Custom CSS for switches to remove white borders, ghosting, and default blue accents.

### 2. Hyprland Layer Rules
To ensure the interface feels cohesive, I’ve implemented specific rules for system layers:
| Component | Layer Rule | Purpose |
| :--- | :--- | :--- |
| **SwayNC** | `ignorealpha 0.6` | Fixes blur rendering behind the notification center. |
| **Rofi** | `ignorealpha 0.6` | Ensures the launcher has a smooth, glassy background. |
| **GTK Apps** | `windowrulev2` | Protects the 60% transparency from being overwritten by the compositor. |

---

## ⚙️ Key Fixes Included
* **Popup Synergy:** Menus and popovers now have 95% opacity and accent borders to remain legible over transparent windows.
* **SwayNC Controls:** Adjusted the notification center toggle buttons to match the global Material You accents.
* **XDG Portals:** Standardized floating rules for GTK file pickers and dialogs.

---

## 🚀 How it Works
1. Set a new wallpaper using your preferred method.
2. **Matugen** triggers and generates the new CSS and config files.
3. GTK applications, Kitty, and the Hyprland compositor reload the new values instantly.
