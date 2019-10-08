FROM archlinux/base

RUN pacman -Syu --noconfirm
RUN pacman -S --noconfirm --needed base-devel sudo git fish man openssh

# Setup sudoers file
# https://unix.stackexchange.com/a/79341
COPY ./sudoers /tmp/sudoers
ENV VISUAL="cp /tmp/sudoers"
RUN visudo

# Setup new user and make give them sudo access
RUN groupadd sudo
RUN useradd -rm -d /home/justin -s /usr/bin/fish -g root -G sudo -u 1000 justin -p ''

# Switch to user
USER justin
WORKDIR /home/justin

# Install basic programming tools
RUN sudo pacman -S --noconfirm --needed \
        # Minimum set of languages needed
        ruby jdk10-openjdk nodejs npm rust go postgresql \
        # CLI tools
        exa curl ripgrep openssh\
        # Dev libraries
        libyaml imagemagick

# Install pacman helper, to download from AUR
RUN git clone https://aur.archlinux.org/yay.git; \
        cd yay; \
        makepkg -si --noconfirm

#Update databases and install the most important tools a person could
# the latest Emacs, terminal prompt, and some ruby shit
RUN yay -Sy
RUN yay -S --noconfirm emacs-git starship nerd-fonts-inconsolata rbenv ruby-build

## Emacs
RUN git clone https://github.com/justinbarclay/.emacs.d.git ~/.emacs.d
# Preload use-package
RUN git clone https://github.com/jwiegley/use-package.git ~/.emacs.d/site-lisp/use-package

RUN cd ~/.emacs.d/site-lisp/use-package; make; cd ~

## Shell
RUN git clone https://github.com/justinbarclay/dotfiles ~/dev/dotfiles
RUN fish curl -L https://get.oh-my.fish > /tmp/install.sh; fish /tmp/install.sh --noninteractive; rm /tmp/install.sh

## Programming languages
# Rust and Cargo
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs > /tmp/install.sh; sh /tmp/install.sh -y; rm /tmp/install.sh
RUN source $HOME/.cargo/env

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
        sudo ./linux-install-1.10.1.469.sh;

# Configure git
RUN git config --global color.ui true; \
        git config --global user.name "Justin Barclay"; \
        git config --global user.email "justincbarclay@gmail.com"; \
        ssh-keygen -t rsa -q -N "" -b 4096 -C "justincbarclay@gmail.com" -f $HOME/.ssh/id_rsa