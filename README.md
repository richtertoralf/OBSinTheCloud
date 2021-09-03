# OBSinTheCloud
OBS Studio in the cloud


Bei Hetzner einen virtuellen Server mieten
Intel Xeon, CX51, 8VCPU´s, 32 GB RAM, 240 GB Disk Lokal, 35,58 Euro monatlich
mit Ubuntu 20.04

8 vCPUs müssten für für 1920x1080p-Streaming und -Aufzeichnung funktionieren.

Das unten beschriebene Setup habe ich auf Intel-basierten VMs getestet, während der X-Server sich hartnäckig weigert, in ihren AMD-basierten VMs zu arbeiten.

Und hier ist die Reihenfolge der Paketinstallationen in der VM, die das System zum Leben erweckt.   
Zuerst wird das Repository aktualisiert, der Video-Dummy-Treiber und das X-Server-System installiert und ein neuer Benutzer zur Verwendung in der GUI wie folgt erstellt:

`apt update -y && apt upgrade -y`  
Wenn du auf einem Headless-Server (also ohne angeschlossenen physischen Monitor) ein Dummy-Display benötigst, installierst du zuerst das Dummy-Treiberpaket:  
`apt install xserver-xorg-video-dummy -y`  

einen user 'cloud' anlegen, damit du nicht als 'root' arbeiten musst
`adduser cloud`  
und ihm root Rechte geben / Root rights for the user
`usermod -aG sudo cloud`  

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

`X -config /etc/X11/xorg.conf`  
Jetzt müsste so eine Anzeige kommen:
```
X.Org X Server 1.20.11
X Protocol Version 11, Revision 0
Build Operating System: linux Ubuntu
Current Operating System: Linux ubuntu-32gb-nbg1-1 5.4.0-81-generic #91-Ubuntu SMP Thu Jul 15 19:09:17 UTC 2021 x86_64
Kernel command line: BOOT_IMAGE=/boot/vmlinuz-5.4.0-81-generic root=UUID=0bf56f61-7d4e-4900-8328-dfb8aaf686f0 ro consoleblank=0 systemd.show_status=true console=tty1 console=ttyS0
Build Date: 06 July 2021  10:17:51AM
xorg-server 2:1.20.11-1ubuntu1~20.04.2 (For technical support please see http://www.ubuntu.com/support)
Current version of pixman: 0.38.4
        Before reporting problems, check http://wiki.x.org
        to make sure that you have the latest version.
Markers: (--) probed, (**) from config file, (==) default setting,
        (++) from command line, (!!) notice, (II) informational,
        (WW) warning, (EE) error, (NI) not implemented, (??) unknown.
(==) Log file: "/var/log/Xorg.0.log", Time: Fri Sep  3 19:12:00 2021
(++) Using config file: "/etc/X11/xorg.conf"
(==) Using system config directory "/usr/share/X11/xorg.conf.d"
(II) Server terminated successfully (0). Closing log file.
```
Identifizieren der Displaynummer
Wenn kein anderer X-Server läuft, wird standardmäßig die Anzeigenummer 0 verwendet. Suche nach dieser Zeile, um die verwendete Anzeige zu identifizieren:
hier ist sie **(==) Log file: "/var/log/Xorg.0.log", Time: Fri Sep  3 19:12:00 2021**  
In dieser Zeile  Xorg.0.logwird dir mitgeteilt, dass das Display 0 verwendet wird, während dir Xorg.1.log sagt, dass das Display 1 verwendet wird.

Jetzt fehlt noch die komplette GUI. Ich habe gnome ausgewählt:

```
sudo apt install x11vnc gnome-shell ubuntu-gnome-desktop autocutsel gnome-core gnome-panel gnome-themes-standard gnome-settings-daemon metacity nautilus gnome-terminal dconf-editor gnome-tweaks yaru-theme-unity yaru-theme-gnome-shell yaru-theme-gtk yaru-theme-icon fonts-ubuntu tmux fonts-emojione
```
Das dauert paar Minuten.
Wenn die Installation fertig ist, den Rechner neu starten:
`reboot`  

Melde dich dann wieder als **roor** an.
Ermittle als nächstes die user-ID vom user 'cloud':  
`id -u cloud`  
Ergibt bei mir 1000  
Verwende in der nächsten Zeile die Benutzer-ID von 'cloud' und   
gibt bei der ersten Abfrage dann das von dir dem Benutzer 'cloud' gegebene Passwort und die richtige Display-Nummer z.B. 0 ein:
'sudo x11vnc -auth /run/user/ 1000 /gdm/Xauthority -usepw -forever -repeat -display :0'  
vnc Passwort: mortel95  (max. 8 Zeichen)

folgende Fehlermeldung bekomme ich:
```
cloud@ubuntu-32gb-nbg1-1:~$ sudo x11vnc -auth /run/user/ 1000 /gdm/Xauthority -usepw -forever -repeat -display :0
[sudo] password for cloud:
03/09/2021 20:20:54 passing arg to libvncserver: 1000
03/09/2021 20:20:54 passing arg to libvncserver: /gdm/Xauthority
03/09/2021 20:20:54 -usepw: found /root/.vnc/passwd
03/09/2021 20:20:54 x11vnc version: 0.9.16 lastmod: 2019-01-05  pid: 1745
No protocol specified
03/09/2021 20:20:54 XOpenDisplay(":0") failed.
03/09/2021 20:20:54 Trying again with XAUTHLOCALHOSTNAME=localhost ...
No protocol specified

03/09/2021 20:20:54 ***************************************
03/09/2021 20:20:54 *** XOpenDisplay failed (:0)
```
