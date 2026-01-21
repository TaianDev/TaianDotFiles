# ─── Zinit ─────────────────────────────────────
source /home/taian/.local/share/zinit/zinit.git/zinit.zsh

export ZSH="$HOME/.oh-my-zsh"
plugins=(git)
source $ZSH/oh-my-zsh.sh

# Plugins Zsh
zinit light zsh-users/zsh-autosuggestions
zinit light zsh-users/zsh-history-substring-search
zinit light Aloxaf/fzf-tab
zinit light zsh-users/zsh-syntax-highlighting

# Configuración: History Substring Search (Flechas Arriba/Abajo)
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down


# ─── Configuración de Plugins ──────────────────

# Configuración: History Substring Search (Flechas Arriba/Abajo)
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

# Configuración: fzf-tab
# disable sort when completing `git checkout`
zstyle ':completion:*:git-checkout:*' sort false
# set descriptions format to enable group support
# NOTE: don't use escape sequences (like '%F{white}%d%f') here, fzf-tab will ignore them
zstyle ':completion:*:descriptions' format '[%d]'
# set list-colors to enable filename colorizing
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
# force zsh not to show completion menu, which allows fzf-tab to capture the unambiguous prefix
zstyle ':completion:*' menu no
# preview directory's content with eza when completing cd
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
#show enviroment variables
zstyle ':fzf-tab:complete:(-command-|-parameter-|-brace-parameter-|export|unset|expand):*' \
	fzf-preview 'echo ${(P)word}'
#for all
zstyle ':fzf-tab:complete:*:*' fzf-preview '
  if [ -d $realpath ]; then 
     eza -1 --color=always --icons $realpath
  else 
     # Si tienes "bat" instalado (recomendado):
     bat --color=always --style=numbers --line-range=:500 $realpath 2>/dev/null || cat $realpath
  fi'
## custom fzf flags
# NOTE: fzf-tab does not follow FZF_DEFAULT_OPTS by default
zstyle ':fzf-tab:*' fzf-flags --color=fg:0,fg+:2 --bind=tab:accept
# To make fzf-tab follow FZF_DEFAULT_OPTS.
# NOTE: This may lead to unexpected behavior since some flags break this plugin. See Aloxaf/fzf-tab#455.
zstyle ':fzf-tab:*' use-fzf-default-opts no

zstyle ':fzf-tab:*' fzf-flags \
--color=bg+:13,fg+:0,hl:3,hl+:3,pointer:4,info:2,prompt:4,header:4 \
--bind=tab:accept
# switch group using `<` and `>`
zstyle ':fzf-tab:*' switch-group '<' '>'

# ─── Cargar colores de pywal ───
load_wal_colors() {
  [[ -f "${HOME}/.cache/wal/colors.sh" ]] && source "${HOME}/.cache/wal/colors.sh"
}
#CAMBIO CON SEÑAL
trap 'load_wal_colors' USR1
# Cargar colores al inicio
load_wal_colors

# ─── Alias ─────────────────────────────────────
alias kittyfloat='kitty --class floating-term'
alias ff='fastfetch'

# --- FUNCIÓN MAGICA PARA NVIM ---
nvim() {
    # 1. Quitar el padding al entrar
    kitty @ set-spacing padding=1
    
    # 2. Ejecutar nvim pasando todos los argumentos ("$@")
    command nvim "$@"
    
    # 3. Restaurar el padding al salir 
    # IMPORTANTE: Cambia '20' por el número que tengas en tu kitty.conf
    kitty @ set-spacing padding=5
}

# ─── PATH ──────────────────────────────────────
#export PATH="$HOME/.local/bin:$HOME/.config/waybar/SCRIPTS:$PATH"
export PATH="$HOME/Personal_Scripts/Set_Target:$HOME/.local/bin:$HOME/.config/waybar/SCRIPTS:$PATH"
export PATH=$PATH:/home/taian/.spicetify

# ─── Fastfetch y Estado inicial ───────────────
FASTFETCH_SHOWN=0

#precmd() {
#  load_wal_colors
  # Mostrar fastfetch una sola vez
#  if [[ $FASTFETCH_SHOWN -eq 0 ]]; then
#    ff
#    FASTFETCH_SHOWN=1
#  fi
#}

#if [[ -z "$IS_FLOATING" ]]; then
    fastfetch
#fi

# ─── Inicializar Starship ──────────────────────
eval "$(starship init zsh)"

# Load a few important annexes, without Turbo
# (this is currently required for annexes)
zinit light-mode for \
    zdharma-continuum/zinit-annex-as-monitor \
    zdharma-continuum/zinit-annex-bin-gem-node \
    zdharma-continuum/zinit-annex-patch-dl \
    zdharma-continuum/zinit-annex-rust

### End of Zinit's installer chunk
