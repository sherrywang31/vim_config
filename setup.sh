cp .vimrc ~/

#YCM
sudo apt install build-essential cmake python3-dev
git clone https://github.com/ycm-core/YouCompleteMe.git ~/.vim/plugged/
cd ~/.vim/plugged/YouCompleteMe
python3 install.py

#ctags
sudo apt-get install ctags
