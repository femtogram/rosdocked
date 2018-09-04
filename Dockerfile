FROM femtogram/ros:kinetic-desktop

# Arguments
ARG user
ARG uid
ARG home
ARG workspace
ARG shell

# Basic Utilities
RUN apt-get -y update && apt-get install -y zsh screen tree sudo ssh synaptic

# Latest X11 / mesa GL
RUN apt-get install -y\
  xserver-xorg-dev-lts-xenial\
  libegl1-mesa-dev-lts-xenial\
  libgl1-mesa-dev-lts-xenial\
  libgbm-dev-lts-xenial\
  mesa-common-dev-lts-xenial\
  libgles2-mesa-lts-xenial\
  libwayland-egl1-mesa-lts-xenial

# Dependencies required to build rviz
RUN apt-get install -y\
  qt4-dev-tools\
  libqt5core5a libqt5dbus5 libqt5gui5 libwayland-client0\
  libwayland-server0 libxcb-icccm4 libxcb-image0 libxcb-keysyms1\
  libxcb-render-util0 libxcb-util1 libxcb-xkb1 libxkbcommon-x11-0\
  libxkbcommon0

# The rest of ROS-desktop
RUN apt-get install -y ros-kinetic-desktop-full \
    ros-kinetic-urg-node \
    ros-kinetic-slam-gmapping

# Additional development tools
RUN apt-get install -y x11-apps python-pip build-essential
RUN pip install catkin_tools

# Install some additional ros stuff
RUN apt-get install -y ros-kinetic-navigation \
    ros-kinetic-teb-local-planner \
    libsvm-dev

RUN add-apt-repository ppa:nschloe/eigen-backports
RUN apt-get update
RUN apt-get install -y libeigen3-dev
RUN apt-get install -y valgrind
RUN apt-get install -y vim

RUN echo "deb http://packages.osrfoundation.org/gazebo/ubuntu-stable `lsb_release -cs` main" > /etc/apt/sources.list.d/gazebo-stable.list 
RUN wget http://packages.osrfoundation.org/gazebo.key -O - | apt-key add -
RUN apt-get update
RUN apt-get install -y libgazebo9-dev ros-kinetic-gazebo9-ros ros-kinetic-gazebo9-ros-control ros-kinetic-gazebo9-plugins ros-kinetic-gazebo9-ros-pkgs

RUN wget https://github.com/fmtlib/fmt/releases/download/5.1.0/fmt-5.1.0.zip
RUN unzip fmt-5.1.0.zip
RUN mkdir fmt-5.1.0/build && cd fmt-5.1.0/build && cmake -DBUILD_SHARED_LIBS=TRUE .. && make -j10 && make install

RUN git clone --single-branch -b cpp-3.0.1 https://github.com/msgpack/msgpack-c.git && mkdir msgpack-c/build && cd msgpack-c/build && cmake -DMSGPACK_CXX11=ON .. && make -j10 && make install

RUN apt-get install -y postgresql libpqxx-dev
RUN apt-get install -y python3-gi python3-click python3-gi-cairo python3-cairo gir1.2-gtk-3.0
RUN pip3 install zmq msgpack
RUN apt-get install -y gir1.2-gdl-3

RUN sed -i 's|export GAZEBO_MASTER_URI=http://localhost:11345|export GAZEBO_MASTER_URI=${GAZEBO_MASTER_URI:-"http://localhost:11345"}|' /usr/share/gazebo/setup.sh


# Make SSH available
EXPOSE 22

# Mount the user's home directory
VOLUME "${home}"

# Clone user into docker image and set up X11 sharing 
RUN \
  echo "${user}:x:${uid}:${uid}:${user},,,:${home}:${shell}" >> /etc/passwd && \
  echo "${user}:x:${uid}:" >> /etc/group && \
  echo "${user} ALL=(ALL) NOPASSWD: ALL" > "/etc/sudoers.d/${user}" && \
  chmod 0440 "/etc/sudoers.d/${user}"

# Switch to user
USER "${user}"
# This is required for sharing Xauthority
ENV QT_X11_NO_MITSHM=1
ENV CATKIN_TOPLEVEL_WS="${workspace}/devel"
# Switch to the workspace
WORKDIR ${workspace}
