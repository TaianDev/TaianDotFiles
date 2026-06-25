#!/usr/bin/env python3
"""
hyprlang_to_lua.py
Hyprlang (.conf) → Lua (Hyprland 0.55+)
PLEASE DO BACKUP BEFORE TESTING, PLEASEEEE.

Use:
    python hyprlang_to_lua.py input.conf -o output.lua
    python hyprlang_to_lua.py input.conf # print to stdout
    python hyprlang_to_lua.py input.conf --dir ./dir  # try to convert recursibly (or whatever, currently not working)
"""

import re
import sys
import argparse
from pathlib import Path
from dataclasses import dataclass, field
from typing import Optional


@dataclass
class ParsedConf:
    variables: dict[str, str] = field(default_factory=dict)
    execs: list[tuple[str, str]] = field(default_factory=list)  # (type, cmd)
    envs: list[tuple[str, str]] = field(default_factory=list)
    monitors: list[str] = field(default_factory=list)
    gesture: list[str] = field(default_factory=list)
    binds: list[dict] = field(default_factory=list)
    window_rules: list[dict] = field(default_factory=list)
    config_blocks: dict = field(default_factory=dict)  # bloque → {k:v}
    sources: list[str] = field(default_factory=list)
    raw_lines: list[str] = field(default_factory=list)


# Utils


# try to expand $VAR and ${VAR} using var dics
def expand_vars(text: str, variables: dict[str, str]) -> str:
    for k, v in sorted(variables.items(), key=lambda x: -len(x[0])):
        text = text.replace(f"${k}", v).replace(f"${{{k}}}", v)
    return text


def lua_string(s: str) -> str:
    # surround values in quotes
    s = s.strip()
    # yes/no → true/false
    if s.lower() == "yes, please :)":
        return "true"
    if s.lower() == "yes":
        return "true"
    if s.lower() == "no":
        return "false"
    # try not to surround numbers, bools and other stuff
    if re.fullmatch(r"-?\d+(\.\d+)?", s):
        return s
    if s in ("true", "false"):
        return s
    if (
        s.startswith("{")
        or s.startswith("rgba(")
        or s.startswith("rgb(")
        or s.startswith("#")
        or s.startswith("0x")
    ):
        return f'"{s}"'
    return f'"{s}"'


def parse_color_value(s: str) -> str:
    """
    "rgba(33ccffee)"                          → '"rgba(33ccffee)"'
    "rgba(33ccffee) rgba(00ff99ee) 45deg"     → '{ colors = { "rgba(...)", "rgba(...)" }, angle = 45 }'
    "#fafc21"                                 → '"#fafc21"'
    "0xeeb3ff1a"                              → '"0xeeb3ff1a"'
    """
    s = s.strip()

    tokens = s.split()
    color_tokens = []
    angle = None

    for token in tokens:
        m_angle = re.match(r"^(-?\d+(?:\.\d+)?)deg$", token)
        if m_angle:
            angle = m_angle.group(1)
        elif re.match(r"^(rgba?\(|#|0x)", token):
            color_tokens.append(token)

    if len(color_tokens) > 1 or (len(color_tokens) >= 1 and angle is not None):
        colors_lua = "{ " + ", ".join(f'"{c}"' for c in color_tokens) + " }"
        if angle is not None:
            return f"{{ colors = {colors_lua}, angle = {angle} }}"
        return f"{{ colors = {colors_lua} }}"

    if color_tokens:
        return f'"{color_tokens[0]}"'

    return lua_string(s)

    # pad = "\t" * n
    # return "\n".join(pad + l if l.strip() else l for l in text.splitlines())


# Parser
def parse_conf(text: str) -> ParsedConf:
    result = ParsedConf()
    lines = text.splitlines()
    i = 0
    block_stack: list[tuple[str, dict]] = []

    def current_block_path() -> str:
        return ".".join(name for name, _ in block_stack)

    while i < len(lines):
        raw = lines[i]
        line = raw.strip()

        # yeah im just erasing away those, good luck tho 😂🤞
        if not line or line.startswith("#"):
            i += 1
            continue

        # same as before but leaving hexa colors alone
        line = re.sub(r'(?<!["\'\w])#(?![0-9a-fA-F]).*$', "", line).strip()
        if not line:
            i += 1
            continue

        if line.endswith("{"):
            block_name = line[:-1].strip()
            block_stack.append((block_name, {}))
            i += 1
            continue

        if line == "}":
            if block_stack:
                block_name, block_dict = block_stack.pop()
                if block_name == "windowrule":
                    result.window_rules.append(parse_windowrule_block(block_dict))
                else:
                    full_name = (current_block_path() + "." + block_name).lstrip(".")
                    _insert_nested(
                        result.config_blocks, full_name.split("."), block_dict
                    )
            i += 1
            continue

        # inside block
        if block_stack and "=" in line:
            key, _, val = line.partition("=")
            key = key.strip()
            val = val.strip()
            val = expand_vars(val, result.variables)
            # this is for col.inactive_borders for example, things with dots
            if "." in key:
                _insert_nested(block_stack[-1][1], key.split("."), val)
            else:
                block_stack[-1][1][key] = val
            i += 1
            continue

        # Vars $VAR = val
        m = re.match(r"^\$(\w+)\s*=\s*(.+)$", line)
        if m:
            result.variables[m.group(1)] = m.group(2).strip()
            i += 1
            continue

        # key = value
        if "=" in line:
            key, _, val = line.partition("=")
            key = key.strip()
            val = val.strip()
            val_expanded = expand_vars(val, result.variables)

            if key == "exec-once":
                result.execs.append(("once", val_expanded))
            elif key == "exec":
                result.execs.append(("always", val_expanded))
            elif key == "env":
                parts = val.split(",", 1)
                if len(parts) == 2:
                    result.envs.append((parts[0].strip(), parts[1].strip()))
            elif key == "monitor":
                result.monitors.append(val_expanded)
            elif key == "gesture":
                result.gesture.append(val_expanded)
            elif key == "source":
                result.sources.append(val_expanded)
            # why so much bind types omg
            elif key in ("bind", "bindel", "binde", "bindm", "bindl", "bindr"):
                result.binds.append(parse_bind(key, val_expanded))
            elif key == "windowrule":
                result.window_rules.append(parse_windowrule(val_expanded))
            elif key == "windowrulev2":
                result.window_rules.append(parse_windowrulev2(val_expanded))
            else:
                result.raw_lines.append(f"-- [failes migration] {raw}")

        i += 1

    return result


def _insert_nested(d: dict, keys: list[str], value):
    if len(keys) == 1:
        if keys[0] in d and isinstance(d[keys[0]], dict) and isinstance(value, dict):
            d[keys[0]].update(value)
        else:
            d[keys[0]] = value
    else:
        d.setdefault(keys[0], {})
        _insert_nested(d[keys[0]], keys[1:], value)


# Binds parser
BIND_LETTER_FLAG = {
    "l": "locked",
    "r": "release",
    "c": "click",
    "g": "drag",
    "o": "long_press",
    "e": "repeating",
    "n": "non_consuming",
    "m": "mouse",
    "t": "transparent",
    "i": "ignore_mods",
    "s": "separate",
    "d": "description",
    "p": "bypass",
    "u": "submap_universal",
}


def parse_bind(bind_type: str, val: str) -> dict:
    suffix = bind_type[4:]  # "bindel" → "el"
    flags = [BIND_LETTER_FLAG[c] for c in suffix if c in BIND_LETTER_FLAG]

    parts = [p.strip() for p in val.split(",")]
    mods = parts[0] if len(parts) > 0 else ""
    key = parts[1] if len(parts) > 1 else ""
    dispatcher = parts[2] if len(parts) > 2 else ""
    args = ",".join(parts[3:]) if len(parts) > 3 else ""
    return {
        "mods": mods,
        "key": key,
        "dispatcher": dispatcher.strip(),
        "args": args.strip(),
        "flags": flags,
    }


MATCH_FIELD_MAP = {
    "class": "class",
    "title": "title",
    "initialclass": "initial_class",
    "initialtitle": "initial_title",
    "xwayland": "xwayland",
    "floating": "float",
    "fullscreen": "fullscreen",
    "pinned": "pin",
    "focus": "focus",
    "group": "group",
    "modal": "modal",
    "tag": "tag",
    "workspace": "workspace",
    "content": "content",
    "xdg_tag": "xdg_tag",
}


def parse_windowrule(val: str) -> dict:
    """
    v1 clasico:   windowrule = float, ^(pavucontrol)$
                  → first EFECCT, then regex
    match: explicit: windowrule = match:class my-window, border_size 10
    """
    parts = [p.strip() for p in val.split(",")]
    match = {}
    effects = {}
    has_explicit_match = any(p.startswith("match:") for p in parts)

    if has_explicit_match:
        for part in parts:
            m = re.match(r"^\s*match:(\w+)\s+(.+)$", part)
            if m:
                field = MATCH_FIELD_MAP.get(m.group(1).lower(), m.group(1))
                match[field] = m.group(2).strip()
                continue
            m = re.match(r"^\s*(\w+)\s+(.+)$", part)
            if m:
                effects[m.group(1)] = m.group(2).strip()
            elif part:
                effects[part] = "true"
    else:
        # EFECCT, REGEX
        if len(parts) >= 2:
            effect_str = parts[0]
            class_regex = parts[1]
        elif parts:
            effect_str = parts[0]
            class_regex = ".*"
        else:
            return {"name": None, "match": {}, "effects": {}}

        match = {"class": class_regex}
        m = re.match(r"^\s*(\w+)\s+(.+)$", effect_str)
        if m:
            effects[m.group(1)] = m.group(2).strip()
        else:
            effects[effect_str] = "true"

    return {"name": None, "match": match, "effects": effects}


def parse_windowrulev2(val: str) -> dict:
    """windowrulev2 = effect, field:value[, field:value...]"""
    parts = [p.strip() for p in val.split(",")]
    effect_str = parts[0]
    match = {}
    for part in parts[1:]:
        if ":" in part:
            field, _, regex = part.partition(":")
            lua_field = MATCH_FIELD_MAP.get(field.strip().lower(), field.strip())
            match[lua_field] = regex.strip()
    effects = {}
    m = re.match(r"""^\s*(\w+)\s+(.+)$""", effect_str)
    if m:
        effects[m.group(1)] = m.group(2).strip()
    else:
        effects[effect_str.strip()] = "true"
    return {"name": None, "match": match, "effects": effects}


def parse_windowrule_block(block_dict: dict) -> dict:
    """
    pars block as a dict
    match:field are separed from other effects
    """
    name = block_dict.get("name")
    match = {}
    effects = {}
    for k, v in block_dict.items():
        if k == "name":
            continue
        if k.startswith("match:"):
            field = k[len("match:") :]
            lua_field = MATCH_FIELD_MAP.get(field.lower(), field)
            match[lua_field] = v
        else:
            effects[k] = v
    return {"name": name, "match": match, "effects": effects}


DISPATCHER_MAP = {
    # window related, please add more, some of the args gonna be implemented later :D
    "killactive": lambda args: "hl.dsp.window.close()",
    "forcekillactive": lambda args: "hl.dsp.window.kill()",
    "closewindow": lambda args: f'hl.dsp.window.close("{args}")',
    "killwindow": lambda args: f'hl.dsp.window.kill("{args}")',
    "togglefloating": lambda args: 'hl.dsp.window.float({ action = "toggle" })',
    "setfloating": lambda args: 'hl.dsp.window.float({ action = "set" })',
    "settiled": lambda args: 'hl.dsp.window.float({ action = "unset" })',
    "fullscreen": lambda args: _fullscreen(args),
    "pseudo": lambda args: 'hl.dsp.window.pseudo({ action = "toggle" })',
    "pin": lambda args: "hl.dsp.window.pin()",
    "centerwindow": lambda args: "hl.dsp.window.center()",
    "movewindow": lambda args: _movewindow(args),
    "swapwindow": lambda args: f'hl.dsp.window.swap({{ direction = "{args}" }})',
    "resizewindow": lambda args: "hl.dsp.window.resize()",
    "resizeactive": lambda args: (
        "hl.dsp.window.resize()"
        if not args.strip()
        else f"hl.dsp.window.resize({{ x = {_parse_resize(args)[0]}, y = {_parse_resize(args)[1]} }})"
    ),
    "moveactive": lambda args: (
        f"hl.dsp.window.move({{ x = {_parse_resize(args)[0]}, y = {_parse_resize(args)[1]}, relative = true }})"
    ),
    "cyclenext": lambda args: (
        f"hl.dsp.window.cycle({{ {'prev = true' if 'prev' in args else 'next = true'} }})"
    ),
    "swapnext": lambda args: (
        f"hl.dsp.window.swap({{ {'prev = true' if 'prev' in args else 'next = true'} }})"
    ),
    "focuswindow": lambda args: f'hl.dsp.focus({{ window = "{args}" }})',
    "bringactivetotop": lambda args: 'hl.dsp.window.alterzorder({ zheight = "top" })',
    "togglegroup": lambda args: "hl.dsp.window.toggle_group()",
    "changegroupactive": lambda args: (
        f'hl.dsp.window.change_group_active({{ direction = "{args}" }})'
    ),
    "moveintogroup": lambda args: f'hl.dsp.window.move({{ into_group = "{args}" }})',
    "moveoutofgroup": lambda args: "hl.dsp.window.move({ out_of_group = true })",
    "movetoworkspace": lambda args: _movetoworkspace(args, follow=True),
    "movetoworkspacesilent": lambda args: _movetoworkspace(args, follow=False),
    # focus / general
    "workspace": lambda args: f'hl.dsp.focus({{ workspace = "{args}" }})',
    "movefocus": lambda args: f'hl.dsp.focus({{ direction = "{args}" }})',
    "focusmonitor": lambda args: f'hl.dsp.focus({{ monitor = "{args}" }})',
    "focusurgentorlast": lambda args: "hl.dsp.focus({ urgent_or_last = true })",
    "focuscurrentorlast": lambda args: "hl.dsp.focus({ last = true })",
    "movecurrentworkspacetomonitor": lambda args: (
        f'hl.dsp.window.move({{ monitor = "{args}" }})'
    ),
    "moveworkspacetomonitor": lambda args: _movewstomonitor(args),
    "swapactiveworkspaces": lambda args: f'hl.dsp.swap_active_workspaces("{args}")',
    "focusworkspaceoncurrentmonitor": lambda args: (
        f'hl.dsp.focus({{ workspace = "{args}", on_current_monitor = true }})'
    ),
    # exec
    "exec": lambda args: f'hl.dsp.exec_cmd("{args}")',
    "execr": lambda args: f'hl.dsp.exec_raw("{args}")',
    # misc
    "exit": lambda args: "hl.dsp.exit()",
    "dpms": lambda args: _dpms(args),
    "pass": lambda args: f'hl.dsp.pass({{ window = "{args}" }})',
    "submap": lambda args: f'hl.dsp.submap("{args}")',
    "togglespecialworkspace": lambda args: (
        f'hl.dsp.focus({{ workspace = "special:{args}" }})'
        if args
        else 'hl.dsp.focus({ workspace = "special" })'
    ),
    "renameworkspace": lambda args: f'hl.dsp.rename_workspace("{args}")',
    "movecursortocorner": lambda args: f"hl.dsp.move_cursor_to_corner({args})",
    "movecursor": lambda args: f"hl.dsp.move_cursor({args})",
    "layoutmsg": lambda args: f'hl.dsp.layout("{args}")',
    "lockgroups": lambda args: f'hl.dsp.window.lock_groups({{ action = "{args}" }})',
    "lockactivegroup": lambda args: (
        f'hl.dsp.window.lock_active_group({{ action = "{args}" }})'
    ),
}


def _fullscreen(args: str) -> str:
    parts = args.split() if args else []
    mode = parts[0] if parts else "0"
    action = parts[1] if len(parts) > 1 else "toggle"
    lua_mode = '"fullscreen"' if mode == "0" else '"maximized"'
    return f'hl.dsp.window.fullscreen({{ mode = {lua_mode}, action = "{action}" }})'


def _movewindow(args: str) -> str:
    if args.startswith("mon:"):
        mon = args[4:].strip()
        return f'hl.dsp.window.move({{ monitor = "{mon}" }})'
    return f'hl.dsp.window.move({{ direction = "{args}" }})'


def _movetoworkspace(args: str, follow: bool) -> str:
    parts = args.split(",", 1)
    ws = parts[0].strip()
    win = parts[1].strip() if len(parts) > 1 else None
    follow_str = "true" if follow else "false"
    if win:
        return f'hl.dsp.window.move({{ workspace = "{ws}", follow = {follow_str}, window = "{win}" }})'
    return f'hl.dsp.window.move({{ workspace = "{ws}", follow = {follow_str} }})'


def _movewstomonitor(args: str) -> str:
    parts = args.split(None, 1)
    ws = parts[0] if parts else ""
    mon = parts[1] if len(parts) > 1 else ""
    return (
        f'hl.dsp.move_workspace_to_monitor({{ workspace = "{ws}", monitor = "{mon}" }})'
    )


def _dpms(args: str) -> str:
    parts = args.split(None, 1)
    action = parts[0] if parts else "toggle"
    mon = parts[1] if len(parts) > 1 else None
    if mon:
        return f'hl.dsp.dpms({{ action = "{action}", monitor = "{mon}" }})'
    return f'hl.dsp.dpms({{ action = "{action}" }})'


def _parse_resize(args: str) -> tuple[str, str]:
    parts = args.split()
    x = parts[0] if parts else "0"
    y = parts[1] if len(parts) > 1 else "0"
    return x, y


def dispatcher_to_lua(dispatcher: str, args: str) -> str:
    fn = DISPATCHER_MAP.get(dispatcher.lower())
    if fn:
        return fn(args)
    # Fallback
    if args:
        return f'hl.dispatch(hl.dsp.{dispatcher}("{args}"))'
    return f"hl.dispatch(hl.dsp.{dispatcher}())"


def bind_to_lua(b: dict) -> str:
    mods = b["mods"].strip()
    key = b["key"].strip()

    if mods:
        mod_parts = [m.strip() for m in re.split(r"[\s,]+", mods) if m.strip()]
        # SUPER/ALT/CTRL/SHIFT, right variants might need differents name, like CONTROL instead of CTRL
        mod_str = " + ".join(mod_parts) + " + " + key
    else:
        mod_str = key

    dispatcher = b["dispatcher"]
    args = b["args"]

    lua_dsp = dispatcher_to_lua(dispatcher, args)

    flags = b.get("flags", [])
    if flags:
        # "flag" → "flag = true"
        fields = ", ".join(f"{f} = true" for f in flags)
        flags_str = f", {{ {fields} }}"
    else:
        flags_str = ""

    return f'hl.bind("{mod_str}", {lua_dsp}{flags_str})'


def effect_to_lua_field(effect: str) -> Optional[str]:
    """
    returns None if cant map.
    """
    simple_map = {
        "opacity": 'opacity = "1 1"',
        "float": "float = true",
        "tile": "tile = true",
        "fullscreen": 'fullscreen = { mode = "fullscreen", action = "set" }',
        "maximize": 'fullscreen = { mode = "maximized", action = "set" }',
        "nofullscreenrequest": 'suppress_event = "fullscreen"',
        "noblur": "no_blur = true",
        "noshadow": "no_shadow = true",
        "noborder": "no_border = true",
        "nodim": "no_dim = true",
        "noanim": "no_anim = true",
        "nofocus": "no_focus = true",
        "noinitialfocus": "no_initial_focus = true",
        "pin": "pin = true",
        "stayfocused": "stay_focused = true",
        "forceinput": "force_input = true",
        "dimaround": "dim_around = true",
        "keepaspectratio": "keep_aspect_ratio = true",
        "xray": "xray = true",
        "immediate": "immediate = true",
        "nearestneighbor": "nearest_neighbor = true",
        "decorate": "decorate = true",
    }
    leffect = effect.lower()
    if leffect in simple_map:
        return simple_map[leffect]

    m = re.match(r"opacity\s+([\d.]+)(?:\s+([\d.]+))?", leffect)
    if m:
        active = m.group(1)
        inactive = m.group(2) or active
        return f"opacity = {{ active = {active}, inactive = {inactive} }}"

    m = re.match(r"size\s+(\S+)\s+(\S+)", leffect)
    if m:
        return f"size = {{ width = {m.group(1)}, height = {m.group(2)} }}"

    m = re.match(r"move\s+(\S+)\s+(\S+)", leffect)
    if m:
        return f'move = "{m.group(1)} {m.group(2)}"'

    m = re.match(r"workspace\s+(\S+)", leffect)
    if m:
        return f'workspace = "{m.group(1)}"'

    m = re.match(r"monitor\s+(\S+)", leffect)
    if m:
        return f'monitor = "{m.group(1)}"'

    m = re.match(r"bordercolor\s+(.+)", leffect)
    if m:
        return f'col = {{ active_border = "{m.group(1).strip()}" }}'

    m = re.match(r"bordersize\s+(\d+)", leffect)
    if m:
        return f"border_size = {m.group(1)}"

    m = re.match(r"rounding\s+(\d+)", leffect)
    if m:
        return f"rounding = {m.group(1)}"

    m = re.match(r"tag\s+(.+)", leffect)
    if m:
        return f'tag = "{m.group(1).strip()}"'

    return None


def match_val_to_lua(val: str) -> str:
    if val.lower() in ("0", "false"):
        return "false"
    if val.lower() in ("1", "true"):
        return "true"
    if val.isdigit():
        return val
    return f'"{val}"'


def windowrule_to_lua(wr: dict, idx: int) -> str:
    match = wr["match"]
    effects = wr.get("effects", {})
    name = wr.get("name") or f"rule-{idx:03d}"
    match_parts = [f"{k} = {match_val_to_lua(v)}" for k, v in match.items()]
    match_str = "{ " + ", ".join(match_parts) + " }"

    effect_lines = []
    for eff_key, eff_val in effects.items():
        raw = eff_key if eff_val == "true" else f"{eff_key} {eff_val}"
        mapped = effect_to_lua_field(raw)
        if mapped:
            effect_lines.append(f"\t{mapped},")
        else:
            # Fallback: just write the thing without complex parsing
            if eff_val == "true":
                effect_lines.append(f"\t{eff_key} = true,")
            else:
                effect_lines.append(f"\t{eff_key} = {lua_string(eff_val)},")

    if not effect_lines:
        effect_lines = ["\t-- [no effects]"]

    lines = (
        [
            "hl.window_rule({",
            f'\tname  = "{name}",',
            f"\tmatch = {match_str},",
        ]
        + effect_lines
        + ["})"]
    )

    return "\n".join(lines)


def config_dict_to_lua(d: dict, depth: int = 1) -> str:
    lines = []
    pad = "\t" * depth
    for k, v in d.items():
        if isinstance(v, dict):
            inner = config_dict_to_lua(v, depth + 1)
            lines.append(f"{pad}{k} = {{\n{inner}\n{pad}}},")
        else:
            sv = str(v).strip()
            if re.search(r"rgba?\(|#[0-9a-fA-F]|0x[0-9a-fA-F]", sv):
                lua_val = parse_color_value(sv)
            else:
                lua_val = lua_string(sv)
            lines.append(f"{pad}{k} = {lua_val},")
    return "\n".join(lines)


def source_to_require(src: str) -> str:
    # require("lua.keybindings") using lua/
    p = Path(src.replace("~/.config/hypr/", "").replace("$HOME/.config/hypr/", ""))
    stem = p.stem  # sin extensión
    parts = list(p.parts)
    if parts:
        parts[-1] = stem
    module = ".".join(parts)
    return f'require("lua.{module}")'


def generate_lua(parsed: ParsedConf, source_file: str = "unknown.conf") -> str:
    sections = []

    sections.append(f"""\
-- gen by confToLua.py
-- Source: {source_file}
-- Some values might need MANUAL check. PLEASE DO BACKUP BEFORE TESTING, PLEASEEEE.
""")

    if parsed.variables:
        lines = ["-- Variables"]
        for k, v in parsed.variables.items():
            lua_val = lua_string(expand_vars(v, parsed.variables))
            lines.append(f"{k} = {lua_val}")
        sections.append("\n".join(lines))

    if parsed.envs:
        lines = ["-- Env vars"]
        for k, v in parsed.envs:
            lines.append(f'hl.env("{k}", "{v}")')
        sections.append("\n".join(lines))

    if parsed.gesture:
        lines = ["-- Gesture"]
        # gesture = fingers, direction, action, options
        # hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
        for m in parsed.gesture:
            parts = [p.strip() for p in m.split(",")]
            fingers = parts[0] if parts[0] else '""'
            direction = parts[1] if len(parts) > 1 else "preferred"
            action = parts[2] if len(parts) > 1 else "auto"
            if fingers and direction and action != '""':
                lines.append(
                    f'hl.gesture({{ fingers = {fingers}, direction = "{direction}", action = "{action}" }})'
                )
            else:
                lines.append("hl.monitor({{}})")
        sections.append("\n".join(lines))

    # monitor
    if parsed.monitors:
        lines = ["-- Monitors"]
        for m in parsed.monitors:
            parts = [p.strip() for p in m.split(",")]
            output = parts[0] if parts[0] else '""'
            res = parts[1] if len(parts) > 1 else "preferred"
            pos = parts[2] if len(parts) > 1 else "auto"
            scale = parts[3] if len(parts) > 1 else "1"
            if output and output != '""':
                lines.append(
                    f'hl.monitor({{ output = "{output}", mode = "{res}", position = "{pos}", scale = "{scale}" }})'
                )
            else:
                lines.append(
                    f'hl.monitor({{ output = "", mode = "{res}", position = "{pos}", scale = "{scale}" }})'
                )
        sections.append("\n".join(lines))

    # exec-once → hl.on("hyprland.start", ...)
    once_cmds = [cmd for typ, cmd in parsed.execs if typ == "once"]
    always_cmds = [cmd for typ, cmd in parsed.execs if typ == "always"]

    if once_cmds:
        lines = ['hl.on("hyprland.start", function()']
        for cmd in once_cmds:
            lines.append(f'\thl.exec_cmd("{cmd}")')
        lines.append("end)")
        sections.append("\n".join(lines))

    if always_cmds:
        lines = ["-- exec (on file reload)"]
        for cmd in always_cmds:
            lines.append(f'hl.exec_cmd("{cmd}")')
        sections.append("\n".join(lines))

    # hl.config()
    if parsed.config_blocks:
        inner = config_dict_to_lua(parsed.config_blocks, depth=1)
        block = f"hl.config({{\n{inner}\n}})"
        sections.append("-- General Config\n" + block)

    if parsed.binds:
        lines = ["-- Keybindings"]
        for b in parsed.binds:
            lines.append(bind_to_lua(b))
        sections.append("\n".join(lines))

    if parsed.window_rules:
        lines = ["-- Windowrules"]
        for idx, wr in enumerate(parsed.window_rules, 1):
            lines.append(windowrule_to_lua(wr, idx))
        sections.append("\n".join(lines))

    if parsed.sources:
        lines = ["-- Requires"]
        for src in parsed.sources:
            lines.append(source_to_require(src))
        sections.append("\n".join(lines))

    if parsed.raw_lines:
        lines = ["-- raw lines, pending review"]
        lines.extend(parsed.raw_lines)
        sections.append("\n".join(lines))

    return "\n\n".join(sections) + "\n"


# CLI


def main():
    parser = argparse.ArgumentParser(
        description="conf from Hyprlang to Lua, Hyprland 0.55+, PLEASE DO BACKUP BEFORE TESTING, PLEASEEEE."
    )
    parser.add_argument("input", help="file .conf")
    parser.add_argument("-o", "--output", help="file (default: stdout)")
    parser.add_argument(
        "--dir",
        help="placeholder for recursive parsing, WIP",
        default=None,
    )
    args = parser.parse_args()

    input_path = Path(args.input)
    if not input_path.exists():
        print(f"Error: {input_path} not found", file=sys.stderr)
        sys.exit(1)

    text = input_path.read_text(encoding="utf-8")
    parsed = parse_conf(text)
    lua_output = generate_lua(parsed, source_file=str(input_path))

    if args.output:
        out_path = Path(args.output)
        out_path.parent.mkdir(parents=True, exist_ok=True)
        out_path.write_text(lua_output, encoding="utf-8")
        print(f"Ready: {out_path}")

        if args.dir and parsed.sources:
            hypr_dir = Path(args.dir)
            for src in parsed.sources:
                src_path = Path(
                    src.replace("~", str(Path.home())).replace(
                        "$HOME", str(Path.home())
                    )
                )
                if src_path.exists():
                    sub_text = src_path.read_text(encoding="utf-8")
                    sub_parsed = parse_conf(sub_text)
                    sub_lua = generate_lua(sub_parsed, source_file=str(src_path))
                    rel = (
                        src_path.relative_to(hypr_dir)
                        if src_path.is_relative_to(hypr_dir)
                        else src_path.name
                    )
                    out_sub = out_path.parent / "lua" / Path(rel).with_suffix(".lua")
                    out_sub.parent.mkdir(parents=True, exist_ok=True)
                    out_sub.write_text(sub_lua, encoding="utf-8")
                    print(f"  Migr: {src_path} → {out_sub}")
                else:
                    print(f"  not found, skipping: {src_path}", file=sys.stderr)
    else:
        print(lua_output)


if __name__ == "__main__":
    main()
