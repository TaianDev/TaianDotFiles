# ─── ZINIT BOOTSTRAP ──────────────────────────────────────────
[[ -d ~/.local/share/zinit ]] || mkdir -p ~/.local/share/zinit
source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"

zinit light-mode for \
    zdharma-continuum/zinit-annex-as-monitor \
    zdharma-continuum/zinit-annex-bin-gem-node \
    zdharma-continuum/zinit-annex-patch-dl \
    zdharma-continuum/zinit-annex-rust

# ─── HISTORIAL PERSISTENTE ────────────────────────────────────
# Esto corrige la "amnesia" entre sesiones
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt HIST_IGNORE_DUPS       # No guarda duplicados consecutivos
setopt HIST_IGNORE_ALL_DUPS   # Elimina duplicados anteriores del historial
setopt HIST_IGNORE_SPACE      # No guarda comandos que empiezan con espacio
setopt HIST_SAVE_NO_DUPS
setopt SHARE_HISTORY          # Comparte historial entre terminales abiertas
setopt APPEND_HISTORY         # Añade al archivo en lugar de sobreescribir
setopt INC_APPEND_HISTORY     # Escribe al historial inmediatamente, no al cerrar

# ─── OH-MY-ZSH LIGHT ──────────────────────────────────────────
zinit snippet OMZL::git.zsh
zinit snippet OMZP::git

# ─── AUTOSUGGESTIONS: configurar ANTES de cargar el plugin ────
# color8 = on_surface_variant.dark — gris sutil, no compite con el texto real
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8,italic'
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20    # No sugiere en comandos muy largos
ZSH_AUTOSUGGEST_USE_ASYNC=true        # No bloquea mientras busca sugerencias

# ─── PLUGINS TURBO ────────────────────────────────────────────
zinit wait'0' lucid for \
    zsh-users/zsh-autosuggestions \
    zsh-users/zsh-history-substring-search \
    atload"_zsh_autosuggest_start" \
    zsh-users/zsh-syntax-highlighting

zinit wait'1' lucid for Aloxaf/fzf-tab

# ─── TECLADO ──────────────────────────────────────────────────
typeset -g -A key
key[Home]="${terminfo[khome]}"
key[End]="${terminfo[kend]}"
key[Insert]="${terminfo[kich1]}"
key[Delete]="${terminfo[kdch1]}"
key[Up]="${terminfo[kcuu1]}"
key[Down]="${terminfo[kcud1]}"

bindkey "^[[H" beginning-of-line
bindkey "^[OH" beginning-of-line
bindkey "^[[F" end-of-line
bindkey "^[OF" end-of-line

[[ -n "$key[Delete]" ]] && bindkey -- "$key[Delete]" delete-char
[[ -n "$key[Insert]" ]] && bindkey -- "$key[Insert]" overwrite-mode

# History substring search — terminfo primero, escape code como fallback
[[ -n "$key[Up]" ]]   && bindkey -- "$key[Up]"   history-substring-search-up
[[ -n "$key[Down]" ]] && bindkey -- "$key[Down]" history-substring-search-down
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
bindkey -M vicmd 'k' history-substring-search-up
bindkey -M vicmd 'j' history-substring-search-down

# Colores del match resaltado en history-substring-search
# color10 = on_primary_container.dark — verde brillante sobre fondo
HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_FOUND='fg=10,bold'
HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_NOT_FOUND='fg=9,bold'

# ─── FZF-TAB ──────────────────────────────────────────────────
zstyle ':completion:*:git-checkout:*' sort false
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
zstyle ':fzf-tab:complete:*:*' fzf-preview '
  if [ -d $realpath ]; then
     eza -1 --color=always --icons $realpath
  else
     bat --color=always --style=numbers --line-range=:500 $realpath 2>/dev/null || cat $realpath
  fi'

# Mapeado a colores kitty:
# bg+:0  = outline.dark (fondo selección)
# fg+:15 = on_surface.dark (texto selección) — máximo contraste
# hl:2   = primary.dark (match normal)
# hl+:10 = on_primary_container.dark (match seleccionado) — brillante
# pointer:10, prompt:10 — verde brillante
# info:11 = on_secondary_container.dark
# spinner:13 = tertiary.dark
# header:8 = on_surface_variant.dark
zstyle ':fzf-tab:*' fzf-flags \
  --color=bg+:0,fg+:15,hl:2,hl+:10,pointer:10,info:11,prompt:10,header:8,spinner:13,marker:13 \
  --bind=tab:accept
zstyle ':fzf-tab:*' switch-group '<' '>'

# ─── SYNTAX HIGHLIGHTING ──────────────────────────────────────
# Referencia de colores (tema oscuro kitty con contrast 0.3):
# 0  = outline.dark          (gris oscuro)
# 1  = tertiary.dark         (acento)
# 2  = primary.dark          (verde base)
# 3  = secondary.dark        (amarillo/dorado base)
# 5  = on_tertiary_container (magenta/acento claro)
# 6  = on_secondary_container (cyan base)
# 8  = on_surface_variant    (gris medio) ← ideal para cosas sutiles
# 9  = on_tertiary_container (acento bright)
# 10 = on_primary_container  (verde brillante) ← máximo contraste verde
# 11 = on_secondary_container (amarillo brillante) ← máximo contraste amarillo
# 13 = tertiary.dark bright  (magenta brillante)
# 14 = secondary.dark bright (cyan brillante)
# 15 = on_surface.dark       (blanco) ← texto principal

typeset -A ZSH_HIGHLIGHT_STYLES

# ── Comandos ─────────────────────────────────────────────────
ZSH_HIGHLIGHT_STYLES[command]='fg=10,bold'           # verde brillante — lo más importante
ZSH_HIGHLIGHT_STYLES[builtin]='fg=10,bold'
ZSH_HIGHLIGHT_STYLES[function]='fg=11,bold'          # amarillo brillante
ZSH_HIGHLIGHT_STYLES[alias]='fg=14,bold'             # cyan brillante
ZSH_HIGHLIGHT_STYLES[hashed-command]='fg=10'
ZSH_HIGHLIGHT_STYLES[precommand]='fg=11,underline'   # sudo/env

# ── Strings y argumentos ─────────────────────────────────────
ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=13' # magenta brillante
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=13'
ZSH_HIGHLIGHT_STYLES[back-quoted-argument]='fg=9'    # acento bright
ZSH_HIGHLIGHT_STYLES[dollar-quoted-argument]='fg=9'
ZSH_HIGHLIGHT_STYLES[dollar-double-quoted-argument]='fg=9'
ZSH_HIGHLIGHT_STYLES[assign]='fg=14'                 # cyan brillante

# ── Paths ─────────────────────────────────────────────────────
ZSH_HIGHLIGHT_STYLES[path]='fg=15,underline'         # blanco puro — máximo contraste
ZSH_HIGHLIGHT_STYLES[path_prefix]='fg=7,underline'   # gris medio — path parcial/inexistente
ZSH_HIGHLIGHT_STYLES[globbing]='fg=9,bold'           # acento bright — * ? []

# ── Palabras reservadas ───────────────────────────────────────
ZSH_HIGHLIGHT_STYLES[reserved-word]='fg=11,bold'     # amarillo brillante — if/for/while
ZSH_HIGHLIGHT_STYLES[commandseparator]='fg=3'        # amarillo base — ; | &&
ZSH_HIGHLIGHT_STYLES[redirection]='fg=14,bold'       # cyan brillante — > >>
ZSH_HIGHLIGHT_STYLES[named-fd]='fg=6'

# ── Errores ───────────────────────────────────────────────────
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=1,bold'      # tertiary = rojo de error
ZSH_HIGHLIGHT_STYLES[comment]='fg=8,italic'          # gris sutil — comentarios #

# ── Flags ─────────────────────────────────────────────────────
ZSH_HIGHLIGHT_STYLES[single-hyphen-option]='fg=9'    # acento bright — -x
ZSH_HIGHLIGHT_STYLES[double-hyphen-option]='fg=9'    # acento bright — --flag

# ─── FUNCIONES Y ALIAS ────────────────────────────────────────
nvim() {
    if [[ "$TERMINAL" == "kitty" || "$TERM" == "xterm-kitty" ]]; then
        kitty @ set-spacing padding=1
        kitty @ set-background-opacity 0.7
        command nvim "$@"
        kitty @ set-spacing padding=2
        kitty @ set-background-opacity 0.5
    else
        command nvim "$@"
    fi
}

# ─── PATH ─────────────────────────────────────────────────────
typeset -U path
path=(
    $HOME/Personal_Scripts/Set_Target
    $HOME/.local/bin
    $HOME/.config/waybar/SCRIPTS
    $HOME/.spicetify
    $path
)
export PATH

# ─── PROMPT & ESTADO ──────────────────────────────────────────
nitch
eval "$(starship init zsh)"

autoload -Uz compinit && compinit
zinit cdreplay -q

export PATH=$PATH:/home/taianlux/.spicetify
