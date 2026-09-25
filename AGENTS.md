# AGENTS.md — ultix repo notes

## Stack
- NixOS 26.05 flake, hosts: `fumonix-desktop`, `fumonix-laptop` (nixosConfigurations)
- home-manager release-26.05; user `fumoctl`, `home.stateVersion = "26.05"`
- Desktop: Hyprland + Noctalia shell (noctalia flake), nix-flatpak, impermanence, disko

## Hyprland Lua config (0.55+)
- Hyprland >= 0.55 replaced hyprlang with Lua (`hyprland.lua`). hyprlang is deprecated.
- home-manager `configType` defaults to `"lua"` for stateVersion >= 26.05.
- NEVER write hyprlang-style settings in `settings` (e.g. `"$mainMod" = "SUPER"`, `bind = "..."` strings):
  HM's Lua generator emits them verbatim -> `hyprland.lua:5: <name> expected near '$'` (HM issue #9468).
- HM Lua generator semantics (modules/services/window-managers/hyprland/lib.nix):
  - `{ _var = x }` -> `local name = x` (Lua local; name = attr name or `value.name`)
  - `{ _args = [a b c] }` -> multi-arg call `hl.<name>(a, b, c)`
  - `lib.generators.mkLuaInline "expr"` -> raw Lua expression
  - attrs -> `hl.<name>({ table })`, lists -> one call per item
  - `extraConfig` appended verbatim; `extraLuaFiles` for modules (attr name = Lua module name)
- Lua API: `hl.bind("MOD + KEY", hl.dsp...., { flags })`, `hl.config({...})`, `hl.curve(name, {type="bezier", points={{x,y},...}})`,
  `hl.animation({leaf=..., speed=..., bezier=...})`, `hl.monitor({output,mode,position,scale})`,
  `hl.on("hyprland.start", fn)`, `hl.window_rule/hl.layer_rule({ name?, match={...}, <effects> })`
- Dispatchers: `hl.dsp.exec_cmd(cmd)`, `hl.dsp.window.{close,float,fullscreen,pseudo,drag,resize,move}`,
  `hl.dsp.focus({direction|workspace})`, `hl.dsp.layout(msg)`. Bind key syntax: `mainMod .. " + Q"`.
- Layer rule effects: no_anim, blur, blur_popups, ignore_alpha (float), dim_around, xray, animation, order, above_lock, no_screen_share.
  Old hyprlang `ignorezero` -> `ignore_alpha = 0`.
- Colors in Lua: hex number `0xAARRGGBB` (shadow.color), gradients `{ colors = {"rgba(..)"}, angle = n }` for borders.
- `dwindle.pseudotile` was REMOVED in 0.55 ("unknown configkey"). Dwindle keys now: force_split, preserve_split, smart_split, smart_resizing,
  permanent_direction_override, special_scale_factor, split_width_multiplier, use_active_for_splits, default_split_ratio, split_bias, precise_mouse_move.
  Pseudo is per-window only: hl.dsp.window.pseudo() bind or windowrule effect `pseudo = true`.
- Every hl.animation() requires `bezier = "..."` OR `spring = "..."` (mutually exclusive). "default"/"linear" etc. are built-in curve names.
- Validation workflow: `nix eval --raw '.#nixosConfigurations.<host>.config.home-manager.users.fumoctl.xdg.configFile."hypr/hyprland.lua".text' > /tmp/x.lua && nix-shell -p lua --run "luac -p /tmp/x.lua"`

## Noctalia app theming (GTK/Qt)
- App theming = builtin template IDs in `settings.theme.templates.builtin_ids` (allowlist; applied only when listed).
  IDs from `assets/templates/builtin.toml`: gtk3, gtk4, qt, kcolorscheme, hyprland, niri, sway, ghostty, kitty, foot, alacritty, wezterm, starship, etc.
  - `gtk3`/`gtk4` -> `~/.config/gtk-{3,4}.0/noctalia.css`; apply.sh hook imports it into gtk.css, sets adw-gtk3(-dark) + color-scheme via gsettings/dconf (needs `adw-gtk3` + `glib`(gsettings) installed; adw theme found via $XDG_DATA_DIRS themes)
  - `kcolorscheme` -> KColorScheme files for KDE-style Qt theming; pairs with `qt.platformTheme.name = "kde"` + `home.sessionVariables.QT_QPA_PLATFORMTHEME = "kde"` (replaced the old qt5ct/qt6ct `qt` template approach; `kdePackages.qt6ct` still installed for the platform theme plugin). Old `qt` template (kept for reference): `~/.config/qt{5,6}ct/colors/noctalia.conf` + `qt.platformTheme.name = "qtct"` + `qt{5,6}ctSettings.Appearance = { custom_palette = true; color_scheme_path = ...; }`
- HM noctalia module validates config at build time (`noctalia config validate`) — build failure = invalid TOML settings.
- In impermanence: `.config/dconf`, `.config/noctalia`, `.local/state/noctalia` are persisted (noctalia settings.toml overrides live in state dir).

## Greeter
- Replaced greetd/tuigreet with ly: `services.displayManager.ly = { enable = ...; settings = { ... }; }` in hosts/common.nix (module is services.displayManager.ly, NOT services.ly).
- Ly picks up Hyprland from wayland-sessions automatically (programs.hyprland provides it); no explicit session cmd needed. Options live under settings (config.ini atoms), e.g. numlock = 1.

## Cursor theming
- Defined in home/noctalia.nix via `home.pointerCursor`: Bibata-Modern-Ice, size 24, with `gtk.enable` + `hyprcursor.enable`. This installs the package, links `~/.icons/default` + `$XDG_DATA_HOME/icons`, fills `gtk.cursorTheme`/dconf `cursor-theme`, and exports `XCURSOR_THEME/SIZE` + `HYPRCURSOR_THEME/SIZE` session vars.
- Belt-and-suspenders: explicit `env = [ { _args = [ "KEY" "VAL" ]; } ]` entries in hyprland.nix `settings` (XCURSOR_*/HYPRCURSOR_*) so the Hyprland session gets them even if ly doesn't source hm-session-vars.sh.
- nixpkgs `bibata-cursors` ships XCursor themes only (`share/icons/Bibata-*`); hyprcursor transparently falls back to XCursor themes — no separate hyprcursor package needed.
- GTK dconf cursor keys (cursor-theme/cursor-size under org/gnome/desktop/interface) are set by `home.pointerCursor`'s gtk backend, not by hand.

## Validation workflows (home-manager)
- Full HM config check: `nix build --no-link '.#nixosConfigurations.<host>.config.home-manager.users.fumoctl.home.activationPackage'` (camelCase `activationPackage`).
- Session vars: grep `<generation>/home-path/etc/profile.d/hm-session-vars.sh` (it's under `home-path/etc/`, not `etc/`).
- dconf values: the generation's `activate` script runs `dconf load / < <store-path>-hm-dconf.ini` — grep that `hm-dconf.ini` store path for final key/value pairs. `state/dconf-keys.json` only lists key paths, not values.
