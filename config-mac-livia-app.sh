#!/bin/bash

# Notes:
#
# - If installing full Xcode, it's better to install that first from the app
#   store before running the Config MacOs to Lívia App script. Otherwise, Homebrew can't access
#   the Xcode libraries as the agreement hasn't been accepted yet.

# - Before running this script, please execute this command in your terminal
# chmod u+x test.sh

# - Before running this script, please change the MACUSER variable with your mac user.

MACUSER=

echo "Starting Config MacOs to Lívia App"

if test ! $(xcode-select -p); then
    echo "Please install Xcode from the app store before running this script!!!"
    exit 1
fi

if [ -z "${MACUSER}" ]; then
    echo "Please fill in MACUSER variable before running this script!!!"
    exit 1
fi

# Check for Homebrew, install if we don't have it
if test ! $(which brew); then
    echo "Installing homebrew..."
    ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

# Update homebrew recipes
brew update

# Install GNU core utilities (those that come with OS X are outdated)
brew tap homebrew/dupes
brew install coreutils
brew install gnu-sed --with-default-names
brew install gnu-tar --with-default-names
brew install gnu-indent --with-default-names
brew install gnu-which --with-default-names
brew install gnu-grep --with-default-names

# Install GNU `find`, `locate`, `updatedb`, and `xargs`, g-prefixed
brew install findutils

# Install Bash 4
brew install bash

PACKAGES=(
    docker
    docker-compose
    git
    npm
    nvm
    vim
    zsh
    yarn
)

echo "Installing packages..."
brew install ${PACKAGES[@]}

echo "Cleaning up..."
brew cleanup

echo "Installing cask..."
brew install caskroom/cask/brew-cask

CASKS=(
    visual-studio-code
    insomnia
    figma
    adoptopenjdk8
    android-studio
    google-chrome
    slack
    discord
    microsoft-teams
    forticlient
)

echo "Installing cask apps..."
brew cask install ${CASKS[@]}

echo "Set zsh terminal to default"
chsh -s /usr/local/bin/zsh

echo "Configuring Android Studio"
echo "\n# Android_ENV" >> .zshrc
echo "\nexport JAVA_HOME=/Library/Java/JavaVirtualMachines/adoptopenjdk-8.jdk/Contents/Home" >> .zshrc
echo "\nexport ANDROID_HOME=/Users/$MACUSER/Library/Android/sdk" >> .zshrc
echo "\nexport PATH=\$PATH:\$ANDROID_HOME/emulator" >> .zshrc
echo "\nexport PATH=\$PATH:\$ANDROID_HOME/tools" >> .zshrc
echo "\nexport PATH=\$PATH:\$ANDROID_HOME/tools/bin" >> .zshrc
echo "\nexport PATH=\$PATH:\$ANDROID_HOME/platform-tools" >> .zshrc

echo "Creating folder structure"
[[ ! -d Workspace ]] && mkdir Workspace

echo "Cloning the project"
cd Workspace
[[ ! -d livia-app ]] && git clone https://github.com/holding-digital/livia-app
[[ ! -d livia-saude-bff ]] && git clone https://bitbucket.org/dasa_desenv/livia-saude-bff

echo "Install Dependencies"
cd livia-app && yarn
cd ..
cd livia-saude-bff && yarn
cd ..

echo "Configuring IOS project"
cd packages/app/ios && pod install && cd ../../..

echo "Configuring Android project"
cd livia-app/packages/app/android
echo "sdk.dir=/Users/$MACUSER/Library/Android/sdk" >> local.properties
cd app
keytool -genkey -v -keystore debug.keystore -storepass android -alias androiddebugkey -keypass android -keyalg RSA -keysize 2048 -validity 10000 -dname “CN=$MACUSER, OU=LiviaApp, O=Dasa, L=SaoPaulo, S=SaoPaulo, C=BR”
cd ../../../..

echo "Complete starting"
