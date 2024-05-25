#!/usr/bin/env zsh

# TODO: Better markers for diff e.g. invisible unicode characters
ADD_START='追追追';
DEL_START='削削削';
DIFF_END='終終終';

description="$1"
diff_markup="$2"

diff_colored=$(echo -E "$diff_markup" | sed "s/$ADD_START/\x1b[32m/g; s/$DEL_START/\x1b[31m/g; s/$DIFF_END/\x1b[0m/g");

local BLUE='\e[34m'
local NC='\e[0m'

printf "${BLUE}%s${NC}\n\n%b${NC}\n" "$description" "$diff_colored"

