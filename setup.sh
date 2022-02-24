cp .vimrc ~/
vim -c PlugInstall -c qall

#YCM
apt install build-essential cmake
git clone https://github.com/ycm-core/YouCompleteMe.git ~/.vim/plugged/
cd ~/.vim/plugged/YouCompleteMe
python3 install.py

#ctags
apt-get install ctags

#pip
apt-get update
apt-get install python3-pip

# skelebot
#pip3 install skelebot
