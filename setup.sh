#! /usr/bin/env bash

if ! [[ -x "$(command -v docker)" ]]; then
    echo "docker-ce is not installed"
    read -p "Would you like to install Docker automatically? [Y/n]" -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        # add docker
        sudo apt-get install \
             apt-transport-https \
             ca-certificates \
             curl \
             software-properties-common
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
        sudo add-apt-repository \
             "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
        sudo apt-get update
        sudo apt-get install docker-ce
        echo "Please log out and back in again and rerun this script"
        exit -1
    else
        echo "Exiting install script!"
        exit -1
    fi
fi

NVIDIA_VERSION=$(modinfo nvidia | grep "^version:" | grep -o "[0-9]\{1,\}" | head -1)
if (( $NVIDIA_VERSION < 390 )); then
    echo "Found NVIDIA graphics driver $NVIDIA_VERSION but needs at least 390"
    read -p "Would you like to install a new version automatically? [Y/n] " -n 1 -r
    echo    # (optional) move to a new line
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        # do dangerous stuff
        sudo add-apt-repository -y ppa:graphics-drivers/ppa
        sudo apt-get install -y nvidia-driver-396
    else
        echo "Exiting install script!"
        exit -1
    fi
fi

if ! [[ -x "$(command -v nvidia-docker)" ]]; then
    echo "nvidia-docker not installed"
    read -p "Would you like to install a new version automatically? [Y/n] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | \
            sudo apt-key add -
        distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
        curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | \
            sudo tee /etc/apt/sources.list.d/nvidia-docker.list
        sudo apt-get update
        
        # Install nvidia-docker2 and reload the Docker daemon configuration
        sudo apt-get install -y nvidia-docker2
        sudo pkill -SIGHUP dockerd
    else
        echo "Exiting install script!"
        exit -1
    fi
fi

echo "#!/usr/bin/env bash
docker run --runtime=nvidia --net=host -e SHELL -e DISPLAY -e DOCKER=1 -v \"\$HOME:\$HOME:rw\" -v \"/tmp/.X11-unix:/tmp/.X11-unix:rw\" --workdir=\$(pwd) -it femtogram/ros:rosdocked \$SHELL" | sudo tee /usr/local/bin/rosdocker > /dev/null
sudo chmod +x /usr/local/bin/rosdocker
echo "Finished install script. Run with `rosdocker`"
