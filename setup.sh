cp .vimrc ~/
vim -c PlugInstall -c qall

#YCM
sudo apt install build-essential cmake
git clone https://github.com/ycm-core/YouCompleteMe.git ~/.vim/plugged/
cd ~/.vim/plugged/YouCompleteMe
python3 install.py

#ctags
sudo apt-get install ctags

#pip
sudo apt-get update
sudo apt-get install python3-pip

# skelebot
sudo pip3 install skelebot
