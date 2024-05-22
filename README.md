manai
=====

Prerequisites
-------------
- [Zsh](https://www.zsh.org/)
- [fzf](https://github.com/junegunn/fzf)

Installation
------------

1. Clone this package to somewhere you are comfortable with (e.g. `$HOME/.dotfiles/manai`)

    ```bash
    $ git clone git@github.com:mecab/manai.git $HOME/.dotfiles/manai
    ```

2. Download manai binary

    ```bash
    $ $HOME/.dotfiles/manai/download-manai.zsh
    ```

3. Source `manai.zsh` in your zshrc then bind `manai` function to any keybind

    ```bash
    $ nano ~/.zshrc
    ```

    and add the following

    ```
    source $HOME/.dotfiles/manai.zsh
    bindkey '\eh' manai
    ```

4. then reload your zshrc

    ```bash
    $ exec $SHELL -l
    ```
