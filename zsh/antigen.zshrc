source ~/.config/zsh/antigen.zsh

antigen use oh-my-zsh

antigen bundle git
antigen bundle git-extras
antigen bundle git-flow

antigen bundle npm
antigen bundle encode64
antigen bundle colorize

antigen bundle zsh-users/zsh-syntax-highlighting
antigen bundle zsh-users/zsh-completions
antigen bundle zsh-users/zsh-autosuggestions

antigen bundle autojumb
antigen bundle Composer
antigen bundle common-aliases
antigen bundle copyfile
antigen bundle jsontools
antigen bundle laravel4
antigen bundle sudo

AUTOSUGGESTION_ACCEPT_RIGHT_ARROW=1

# Enable autosuggestions automatically
zle-line-init() {
    zle autosuggest-start
}
zle -N zle-line-init

antigen theme bureau

antigen apply
