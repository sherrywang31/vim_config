cp .vimrc ~/

#YCM
apt install build-essential cmake python3-dev
cd ~/.vim/plugged/YouCompleteMe
python3 install.py

#ctags
apt-get install ctags
