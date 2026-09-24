### 🚀 Welcome to Obtainium+ 1.7.0!

This milestone release brings major ergonomic improvements, Material 3 Expressive theming, refined navigation docks, extensive tile customization, and critical stability fixes.

#### 📱 Samsung OneUI Reachability Header
- **Fluid Pull-Down Reachability**: Pull down on your app list to smoothly shift the title into the center and bring interactive content within easy thumb reach.
- **Contextual Status Subtitle**: Live `"18 apps · 3 updates"` status text that fades gracefully with header expansion.

#### 🎨 Material 3 Expressive Theming
- **Dynamic Scheme Variants**: Android 16/M3 Expressive color schemes (Tonal Spot, Expressive, Fruit Salad, Rainbow, Vibrant, Fidelity, and Monochrome).
- **Curated Palette Presets & Scale Transitions**: Handcrafted themes designed for high-contrast OLED dark modes with fluid spring curves.

#### 🏝️ Floating Navigation Dock & Action Capsule
- **Floating Island Dock**: Optional frosted pill-shaped navigation dock (`plusFloatingNavBar`) with rounded corners and ambient shadow.
- **Floating Action Capsule**: Frosted install and update capsule on App Detail pages.

#### ✨ Granular Card & Tile Styling
- **Pinned App Highlight Borders**: Distinctive accented borders for pinned apps.
- **Category Accent Ribbons**: Vertical color ribbons indicating assigned categories.
- **Expressive Version Update Pills**: Tonal version pills (`↓ 2.4.0`) replacing classic download buttons.
- **Icon Rim Borders**: Outlines ensuring transparent or white icons remain crisp on all backgrounds.
- **Stadium Pill Filter Chips**: Fully rounded chips on tag and category filter bars.

#### ⚡ Shizuku / ShizukuPlus Turbo Engine
- **Fast IPC & Auto Fallback**: High-throughput binder buffering for unattended installs with graceful fallback to the package installer.
- **Device Tuning Hub**: Built-in optimization shortcuts for Samsung, Xiaomi, OnePlus, Vivo, Huawei, Nothing OS, and Transsion.

#### 🛡️ Key Bug Fixes & Stability
- Fixed PageStorage type collision crash in Settings Apps section.
- Fixed back-press null assertion crash in navigation handler.
- Fixed latent infinite loop in tab switching.
- Restored repository moved warnings in modern tiles.
- Fixed GitHub source badge visibility on dark theme cards.
- Eliminated icon cache thrashing and controller memory leaks.
