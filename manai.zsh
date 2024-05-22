__manai_base="$(dirname "${BASH_SOURCE:-$0}")"

function format() {
    local GLAY='\033[30m'
    local WHITE='\033[37m'
    local NC='\033[0m'

    while read line; do
        IFS=$'\t' read -r -A columns <<< "$line"
        printf "${WHITE}%s${NC}\t${GLAY}%s${NC}\t%s\n" "${columns[1]}" "${columns[2]}" "${(j/\t/)columns[@]:2}"
    done
}

function format_preview() {
    local BLUE='\033[34m'
    local NC='\033[0m'

    echo -ne "${BLUE}\{2}${NC}\\n\\n{3}\\n"
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

    local preview_command="printf '${BLUE}%s${NC}\n\n%s' {2} {3}"
    # result=$( cat $HOME/tmp/out.txt |
    result=$(OPENAI_API_KEY="${OPENAI_API_KEY}" "${__manai_base}/bin/manai" "$subcommand" "$requirement" |
        format |
        fzf --ansi \
            --delimiter='\t' \
            --layout=reverse \
            --bind 'enter:execute(echo {3})+abort' \
            --with-nth=1,2 \
            --preview="$preview_command" \
            --preview-window=bottom:40%:wrap
    )
    zle kill-buffer
    zle -R
    BUFFER=$result
    zle end-of-line
}
zle -N manai
bindkey '\eh' manai
