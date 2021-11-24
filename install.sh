#!/bin/bash
# Achtung, funktioniert noch nicht!
# Ist nur eine Sammlung von Kommandos.
apt update -y && apt upgrade -y
apt install xserver-xorg-video-dummy -y
# /etc/X11/xorg.conf hinzufügen
# und starten 
nohup X -config /etc/X11/xorg.conf
# funktioniert so mit gdm aber nicht mit gdm3
apt install apt install x11vnc 
apt install gnome-shell autocutsel gnome-core gnome-panel gnome-themes-standard gnome-settings-daemon metacity nautilus gnome-terminal dconf-editor gnome-tweaks fonts-ubuntu tmux
reboot
