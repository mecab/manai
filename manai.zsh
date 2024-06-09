__manai_base="$(dirname "${BASH_SOURCE:-$0}")"

function __manai_format() {
    local WHITE='\033[37m'
    local NC='\033[0m'

    while read line; do
        IFS=$'\t' read -r -A columns <<< "$line"
        printf "${WHITE}%s${NC}\t%s\t%s\t%b\n" "${columns[1]}" "${columns[2]}" "${columns[3]}" "${columns[4]}"
    done
}

function manai() {
    local BLUE='\e[34m'
    local NC='\e[0m'

    local OPENAI_API_KEY=${MANAI_OPENAI_API_KEY:-"$OPENAI_API_KEY"}

    # Check if fzf version is 0.38 or later and if so, use the new `become` feature.
    # Specifically, fzf 0.53.0 or later must use execute (https://github.com/junegunn/fzf/issues/3845)

    # `fzf --version` output is like `0.53.0 (c4a9ccd)` but some people might alias fzf to `fzf-tmux`.
    # `fzf-tmux --version` output is like `fzf-tmux (with fzf 0.53.0 (c4a9ccd))` so we need to extract the version number first.

    # fzf_version is an array of 3 integers: major, minor, patch
    local fzf_version=($(fzf --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | awk -F. '{printf "%d %d %d", $1, $2, $3}'))
    if [[ $fzf_version[1] -gt 0 ]] || [[ $fzf_version[2] -ge 38 ]]; then
        local bind_command='enter:become(echo -E {3})'
    else
        local bind_command='enter:execute(echo -E {3})+abort'
    fi

    autoload -Uz read-from-minibuffer
    subcommand=$BUFFER

    if [[ -z "$OPENAI_API_KEY" ]]; then
        zle beginning-of-line
        zle kill-buffer
        zle -R
        echo "🤖 Please set OPENAI_API_KEY or MANAI_OPENAI_API_KEY"
        BUFFER=$subcommand
        zle end-of-line
        return
    fi

    read-from-minibuffer '🤖 What do you want to do?: '
    local requirement=$REPLY
    REPLY=""

    if [[ -z $requirement ]]; then
        return
    fi

    local preview_command="${__manai_base}/lib/manai-preview-format.zsh {2} {4}"
    # result=$( cat $HOME/tmp/out.txt |
    result=$(OPENAI_API_KEY="${OPENAI_API_KEY}" "${__manai_base}/bin/manai" "$subcommand" "$requirement" |
        __manai_format |
        fzf --ansi \
            --delimiter='\t' \
            --layout=reverse \
            --bind="$bind_command" \
            --with-nth=1 \
            --preview="$preview_command" \
            --preview-window=right:40%:wrap
    )
    zle kill-buffer
    zle -R
    BUFFER=$result
    zle end-of-line
}
zle -N manai
