__manai_base="$(dirname "${BASH_SOURCE:-$0}")"

function __manai_format() {
    local GLAY='\033[30m'
    local WHITE='\033[37m'
    local NC='\033[0m'

    while read line; do
        IFS=$'\t' read -r -A columns <<< "$line"
        printf "${WHITE}%s${NC}\t${GLAY}%s${NC}\t%b\t%b\n" "${columns[1]}" "${columns[2]}" "${columns[3]}" "${columns[4]}"
    done
}

function __manai_preview_format() {
    echo "$1" | sed "s/あ/\x1b[32m/g; s/い/\x1b[31m/g; s/う/\x1b[0m/g"
}

function manai() {
    local BLUE='\e[34m'
    local NC='\e[0m'

    local OPENAI_API_KEY=${MANAI_OPENAI_API_KEY:-"$OPENAI_API_KEY"}

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
            --bind 'enter:execute(echo {3})+abort' \
            --with-nth=1,2 \
            --preview="$preview_command" \
            --preview-window=right:30%:wrap
    )
    zle kill-buffer
    zle -R
    BUFFER=$result
    zle end-of-line
}
zle -N manai
