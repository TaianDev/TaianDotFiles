# ─── ZINIT BOOTSTRAP ──────────────────────────────────────────
# Aseguramos que las carpetas de Zinit existan
[[ -d ~/.local/share/zinit ]] || mkdir -p ~/.local/share/zinit

source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"

# Cargar anexos esenciales primero
zinit light-mode for \
    zdharma-continuum/zinit-annex-as-monitor \
    zdharma-continuum/zinit-annex-bin-gem-node \
    zdharma-continuum/zinit-annex-patch-dl \
    zdharma-continuum/zinit-annex-rust

# ─── OH-MY-ZSH LIGHT (Sin cargar todo el framework) ──────────
# En lugar de source oh-my-zsh.sh, cargamos solo la librería y el plugin git
zinit snippet OMZL::git.zsh
zinit snippet OMZP::git

# ─── PLUGINS CON TURBO MODE (Carga asíncrona) ─────────────────
# wait'0' hace que el shell cargue instantáneamente y los plugins un milisegundo después
zinit wait'0' lucid for \
    atinit"ZSH_AUTOSUGGEST_STRATEGY=(history completion)" \
    zsh-users/zsh-autosuggestions \
    zsh-users/zsh-history-substring-search \
    atload"_zsh_autosuggest_start" \
    zsh-users/zsh-syntax-highlighting

# fzf-tab debe cargarse después de compinit
zinit wait'1' lucid for Aloxaf/fzf-tab

# ─── CONFIGURACIÓN DE TECLADO ─────────────────────────────────
# Usamos terminfo para mapear teclas correctamente en cualquier terminal
typeset -g -A key

key[Home]="${terminfo[khome]}"
key[End]="${terminfo[kend]}"
key[Insert]="${terminfo[kich1]}"
key[Delete]="${terminfo[kdch1]}"
key[Up]="${terminfo[kcuu1]}"
key[Down]="${terminfo[kcud1]}"
key[Left]="${terminfo[kcub1]}"
key[Right]="${terminfo[kcuf1]}"

# Bindings para Inicio y Fin
bindkey "^[[H" beginning-of-line
bindkey "^[OH" beginning-of-line

# Fin (End)
bindkey "^[[F" end-of-line
bindkey "^[OF" end-of-line

# Bindings para Suprimir e Insertar
[[ -n "$key[Delete]" ]] && bindkey -- "$key[Delete]" delete-char
[[ -n "$key[Insert]" ]] && bindkey -- "$key[Insert]" overwrite-mode

# Bindings para History Substring Search (Flechas)
# Usamos las variables de terminfo para que sea más robusto
[[ -n "$key[Up]" ]]   && bindkey -- "$key[Up]" history-substring-search-up
[[ -n "$key[Down]" ]] && bindkey -- "$key[Down]" history-substring-search-down

# ─── CONFIGURACIÓN DE TECLADO ─────────────────────────────────
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
# También para modo Vi si lo usas:
bindkey -M vicmd 'k' history-substring-search-up
bindkey -M vicmd 'j' history-substring-search-down

# ─── FZF-TAB & COMPLETION ─────────────────────────────────────
#zstyle ':completion:*:git-checkout:*' sort false
#zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
#zstyle ':completion:*' menu no
#zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
#zstyle ':fzf-tab:complete:*:*' fzf-preview '
#  if [ -d $realpath ]; then 
#     eza -1 --color=always --icons $realpath
#  else 
#     bat --color=always --style=numbers --line-range=:500 $realpath 2>/dev/null || cat $realpath
#  fi'
#zstyle ':fzf-tab:*' fzf-flags --color=bg+:13,fg+:0,hl:3,hl+:3,pointer:4,info:2,prompt:4,header:4 --bind=tab:accept
#zstyle ':fzf-tab:*' switch-group '<' '>'

# ─── FZF-TAB & COMPLETION ─────────────────────────────────────
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
zstyle ':fzf-tab:*' fzf-flags \
  --color=bg+:0,fg+:15,hl:2,hl+:10,pointer:2,info:7,prompt:2,header:8,spinner:3,marker:3 \
  --bind=tab:accept
zstyle ':fzf-tab:*' switch-group '<' '>'

# ─── SYNTAX HIGHLIGHTING (Simplificado) ───────────────────────
# Se definen después de cargar el plugin
#typeset -A ZSH_HIGHLIGHT_STYLES
#ZSH_HIGHLIGHT_STYLES[command]='fg=4'
#ZSH_HIGHLIGHT_STYLES[builtin]='fg=4'
#ZSH_HIGHLIGHT_STYLES[function]='fg=6'
#ZSH_HIGHLIGHT_STYLES[alias]='fg=4'
#ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=9'
#ZSH_HIGHLIGHT_STYLES[reserved-word]='fg=9'
#ZSH_HIGHLIGHT_STYLES[precommand]='fg=3,underline'
#ZSH_HIGHLIGHT_STYLES[commandseparator]='fg=3'
#ZSH_HIGHLIGHT_STYLES[path]='fg=7'
#ZSH_HIGHLIGHT_STYLES[globbing]='fg=10'
#ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=9'
#ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=9'
#ZSH_HIGHLIGHT_STYLES[back-quoted-argument]='fg=15'
typeset -A ZSH_HIGHLIGHT_STYLES

# ── Comandos y funciones ──────────────────────────────────────
ZSH_HIGHLIGHT_STYLES[command]='fg=4,bold'           # primary.dark — comandos del sistema
ZSH_HIGHLIGHT_STYLES[builtin]='fg=12,bold'          # on_primary_container.dark — builtins zsh
ZSH_HIGHLIGHT_STYLES[function]='fg=6'               # on_secondary_container.dark — funciones
ZSH_HIGHLIGHT_STYLES[alias]='fg=14'                 # secondary.dark — aliases
ZSH_HIGHLIGHT_STYLES[hashed-command]='fg=4'         # primary.dark

# ── Argumentos y parámetros ───────────────────────────────────
ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=2' # primary.dark — strings
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=2'
ZSH_HIGHLIGHT_STYLES[back-quoted-argument]='fg=10'  # on_primary_container.dark
ZSH_HIGHLIGHT_STYLES[dollar-quoted-argument]='fg=9' # on_tertiary_container.dark
ZSH_HIGHLIGHT_STYLES[dollar-double-quoted-argument]='fg=9'
ZSH_HIGHLIGHT_STYLES[assign]='fg=11'                # on_secondary_container.dark

# ── Paths y globbing ──────────────────────────────────────────
ZSH_HIGHLIGHT_STYLES[path]='fg=15,underline'        # on_surface.dark — paths existentes
ZSH_HIGHLIGHT_STYLES[path_prefix]='fg=7,underline'  # on_surface_variant.dark — paths parciales
ZSH_HIGHLIGHT_STYLES[globbing]='fg=13,bold'         # tertiary.dark — wildcards * ? []

# ── Palabras reservadas y separadores ────────────────────────
ZSH_HIGHLIGHT_STYLES[reserved-word]='fg=3,bold'     # secondary.dark — if/for/while/do
ZSH_HIGHLIGHT_STYLES[precommand]='fg=11,underline'  # on_secondary_container.dark — sudo/env
ZSH_HIGHLIGHT_STYLES[commandseparator]='fg=3'       # secondary.dark — ; | &&
ZSH_HIGHLIGHT_STYLES[redirection]='fg=14,bold'      # secondary.dark — > >> 
ZSH_HIGHLIGHT_STYLES[named-fd]='fg=6'

# ── Errores y desconocidos ────────────────────────────────────
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=1,bold'     # tertiary.dark — token no reconocido
ZSH_HIGHLIGHT_STYLES[comment]='fg=0,italic'         # outline.dark — comentarios #

# ── Opciones y flags ──────────────────────────────────────────
ZSH_HIGHLIGHT_STYLES[single-hyphen-option]='fg=5'   # on_tertiary_container.dark — -x
ZSH_HIGHLIGHT_STYLES[double-hyphen-option]='fg=5'   # on_tertiary_container.dark — --flag


# ─── FUNCIONES Y ALIAS ────────────────────────────────────────
nvim() {
    # Usar 'command' evita recursión. Ajustamos Kitty solo si estamos en Kitty.
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
# Usar typeset -U evita duplicados en el PATH si haces source varias veces
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
fastfetch
eval "$(starship init zsh)"

# Completar la inicialización de Zinit
autoload -Uz compinit && compinit
zinit cdreplay -q
