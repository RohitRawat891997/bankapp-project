#!/bin/bash
sudo apt update
sudo apt install docker.io -y
sudo apt install docker-compose-v2 -y
sudo usermod -aG  docker  ubuntu
newgrp docker

