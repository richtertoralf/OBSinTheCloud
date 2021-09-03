# OBSinTheCloud
OBS Studio in the cloud


Bei Hetzner einen virtuellen Server mieten
Intel Xeon, CX51, 8VCPU´s, 32 GB RAM, 240 GB Disk Lokal, 35,58 Euro monatlich
mit Ubuntu 20.04

8 vCPUs müssten für für 1920x1080p-Streaming und -Aufzeichnung funktionieren.

Das unten beschriebene Setup habe ich auf Intel-basierten VMs getestet, während der X-Server sich hartnäckig weigert, in ihren AMD-basierten VMs zu arbeiten.

Und hier ist die Reihenfolge der Paketinstallationen in der VM, die das System zum Leben erweckt. Zuerst wird das Repository aktualisiert, der Video-Dummy-Treiber und das X-Server-System installiert und ein neuer Benutzer zur Verwendung in der GUI wie folgt erstellt:

apt update -y && apt upgrade -y
apt install xserver-xorg-video-dummy -y

# einen user 'cloud' anlegen
adduser cloud
# und ihm root Rechte geben / Root rights for the user
usermod -aG sudo cloud

Der X-Server benötigt eine Konfigurationsdatei in /etc/X11/xorg.conf , die folgenden Inhalt haben sollte. Die in dieser Konfigurationsdatei verwendete Modeline erstellt einen Monitor, der mit einer Bildwiederholfrequenz von genau 60 Hz läuft. Dies ist wichtig für OBS, um qualitativ hochwertige Aufnahmen von Videostreams zu erstellen!

nano /etc/X11/xorg.conf

```
# This xorg configuration file is meant to be used
# to start a dummy X11 server.
# For details, please see:
# https://www.xpra.org/xorg.conf

# Here we setup a Virtual Display of 1920x1080 pixels
 
Section "Device"
     Identifier "Configured Video Device"
     Driver "dummy"
     #VideoRam 4096000
     VideoRam 256000
     #VideoRam 16384
EndSection

Section "Monitor"
    Identifier "Configured Monitor"
    HorizSync 5.0 - 1000.0
    VertRefresh 5.0 - 200.0
    Modeline "1920x1080_60.00"  173.00  1920 2048 2248 2576  1080 1083 1088 1120 -hsync +vsync
EndSection

Section "Screen"
    Identifier "Default Screen"
    Monitor "Configured Monitor"
    Device "Configured Video Device"
    DefaultDepth 24
    SubSection "Display"
        Viewport 0 0
        Depth 24
        Virtual 1920 1080
    EndSubSection
EndSection
```
Als nächstes konfigurieren und starten Sie den X-Server und brechen Sie mit STRG-C ab, sobald die Konfiguration geschrieben wurde und die Ausgabe nach einer Sekunde stoppt:

X -config /etc/X11/xorg.conf 

Now, install the Ubuntu desktop packages for the GUI:

```
sudo apt install x11vnc gnome-shell ubuntu-gnome-desktop autocutsel gnome-core gnome-panel gnome-themes-standard gnome-settings-daemon metacity nautilus gnome-terminal dconf-editor gnome-tweaks yaru-theme-unity yaru-theme-gnome-shell yaru-theme-gtk yaru-theme-icon fonts-ubuntu tmux fonts-emojione
```

And that’s it, now reboot.

reboot

x11vnc -storepasswd 

sudo x11vnc -auth /run/user/ 114 /gdm/Xauthority -usepw -forever -repeat -display :0
vnc Passwort: obs01
