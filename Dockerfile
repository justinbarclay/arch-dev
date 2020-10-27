# Note as you read this document, I run yay _mutliple times in this setup and that's
# to take advantage of the caching that docker does. The further down in the file the
# yay command, the more likely I am to add or remove software.
FROM archlinux/base

RUN pacman -Syu --noconfirm --needed base-devel sudo git \
        gnupg zsh man openssh postgresql htop

# Setup sudoers file
# https://unix.stackexchange.com/a/79341
COPY ./sudoers /tmp/sudoers
ENV VISUAL="cp /tmp/sudoers"
RUN visudo

# Setup new user and make give them sudo access
RUN groupadd sudo
RUN useradd -rm -d /home/justin -s /usr/bin/zsh -g root -G sudo -u 1000 justin -p ''
# RUN useradd -rm -d /home/postgres -g root -G sudo -u 1001 postgres -p ''

# Set-up postgres
USER postgres
RUN initdb --locale=en_US.UTF-8 -E UTF8 -D /var/lib/postgres/data

# Switch to user
USER justin
WORKDIR /home/justin

# Install pacman helper, to download from AUR
RUN git clone https://aur.archlinux.org/yay.git /tmp/yay; \
        cd /tmp/yay; \
        makepkg -si --noconfirm; \
        cd ~; \
        rm -rf yay;

RUN rm -rf ./yay
#Update databases and install the most important tools a person could
# the latest Emacs, terminal prompt, and some ruby shit
RUN yay -Sy
RUN yay -S --noconfirm \
        emacs-git starship nerd-fonts-inconsolata rbenv ruby-build \
        ttf-cascadia-code nerd-fonts-cascadia-code nerd-fonts-inconsolata

# Install Powerline Fonts
RUN git clone https://github.com/powerline/fonts.git /tmp/fonts; \
        /tmp/fonts/install.sh; \
        rm -rf fonts
## Emacs
RUN git clone https://github.com/justinbarclay/.emacs.d.git ~/.emacs.d
# Preload use-package
RUN git clone https://github.com/jwiegley/use-package.git ~/.emacs.d/site-lisp/use-package

RUN cd ~/.emacs.d/site-lisp/use-package; make; cd ~

# Install basic programming tools
RUN yay -S --noconfirm --needed \
        # Minimum set of languages needed
        ruby jdk11-openjdk nodejs npm go \
        # CLI tools
        exa curl ripgrep openssh jq \
        # Dev libraries
        libyaml imagemagick

## Shell
RUN git clone https://github.com/justinbarclay/dotfiles ~/dev/dotfiles

## Programming languages
# Rust and Cargo
# Using rustup here because it will manage Rust version instead of something like pacman or yay
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs > /tmp/install.sh; sh /tmp/install.sh -y; rm /tmp/install.sh
RUN source $HOME/.cargo/env; rustup component add rls rust-analysis rust-src

# Ruby
RUN rbenv rehash
RUN rbenv install 2.6.5
RUN rbenv global 2.6.5
RUN gem install bundler -v 1.17.3
RUN gem install rails -v 5.2

# Clojure
RUN sudo npm install -g shadow-cljs

# Command stolen from https://clojure.org/guides/getting_started
RUN curl -O https://download.clojure.org/install/linux-install-1.10.1.469.sh; \
        chmod +x linux-install-1.10.1.469.sh; \
        sudo ./linux-install-1.10.1.469.sh; \
        rm linux-install-1.10.1.469.sh;

# Configure git
RUN git config --global color.ui true; \
        git config --global user.name "Justin Barclay"; \
        git config --global user.email "justincbarclay@gmail.com"; \
        git config --global pull.rebase true; \
        ssh-keygen -t rsa -q -N "" -b 4096 -C "justincbarclay@gmail.com" -f $HOME/.ssh/id_rsa

# Non dev related programs, these are things that I expect to change more often
RUN yay -Syu --noconfirm \
        # Spellchecking, needed for flyspell
        ispell languagetool \
        # CLI Email tools
        notmuch gmailieer \
        # Graphing tools
        gnuplot graphviz \
        # Compressing
        zip unzip \
        # Networking
        nmap \
        # Document writing/conversion
        pandoc texlive-most

# Clean up cache
RUN yay -Sc --noconfirm

RUN ~/dev/dotfiles/setup.sh zsh

# Delete /etc/resolv.conf to allow WSL to generate a version based on Windows networking information
# RUN rm -f /etc/resolv.conf
RUN echo "You need to setup GPG for signing git keys, ssh keys for Gitlab, Github, and AWS"
