# OBSinTheCloud
OBS Studio in the cloud  
**inspiriert von Martin Sauters Blog https://blog.wirelessmoves.com/2021/07/running-obs-studio-in-the-cloud.html**  
> OBS in der Cloud bietet mir einige Vorteile, wenn ich z.B. bei Outdoor-Sportveranstaltungen, wie Radrennen, Motorsportveranstaltungen oder Skilanglaufmarathons, Videostreams mit mobilen Kameras mit 4G-Encodern produziere. Der Schnitt und die Produktion des fertigen Programms kann dann ortsunabhängig, von einem kleinen Rechner aus, in der Cloud erfolgen.

## Ubuntu ##
Zuerst z.B. bei Hetzner einen virtuellen Server mieten.
Damit hat es funktioniert:
Intel Xeon, CX51, 8VCPU´s, 32 GB RAM, 240 GB Disk Lokal, 35,58 Euro monatlich  
mit Ubuntu 20.04  
Warum Linux und nicht Windows? 
- Kostenreduzierung (keine Lizenzkosten)
- effektivere Auslastung der Hardware  
8 vCPUs müssten für für 1920x1080p-Streaming und -Aufzeichnung funktionieren  
 
Zuerst wird das Repository aktualisiert, der Video-Dummy-Treiber und das X-Windows-System installiert und ein neuer Benutzer zur Verwendung in der GUI wie folgt erstellt:

`apt update -y && apt upgrade -y`  
`apt install xserver-xorg-video-dummy -y`  
  
`adduser cloud`  
und ihm root Rechte geben  
`usermod -aG sudo cloud`  

Da unser ausgewählter virtueller Server über keine Grafikarte und auch keinen Bildschirm verfügt, müssen wir diese simulieren und konfigurieren. Mit den folgenden Einstellungen in der Konfigurationsdatei wird ein Monitor erstellt/simuliert, der mit einer Bildwiederholfrequenz von genau 60 Hz läuft. Dies ist wichtig für OBS, um qualitativ hochwertige Aufnahmen von Videostreams mit 1080p und 30 oder 60 Hz zu erstellen!  
Dafür hat X-Windows die Konfigurationsdatei **/etc/X11/xorg.conf**, die folgenden Inhalt haben sollte (Danke an Martin Sauter):  

`nano /etc/X11/xorg.conf`    

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

Als nächstes X-Windows konfigurieren indem du **X** als user root startest    
und nach kurzer Zeit, sobald die Konfiguration geschrieben wurde und die Ausgabe Zeit stoppt,  mit STRG-C abbrichst:  
`X -config /etc/X11/xorg.conf`  
Jetzt kommt so eine Anzeige:  
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
paar Infos dazu:  
**Identifizieren der Displaynummer**    
Wenn kein anderer X-Server läuft, wird standardmäßig die Anzeigenummer 0 verwendet. Suche nach dieser Zeile, um die verwendete Anzeige zu identifizieren:  
hier ist sie **(==) Log file: "/var/log/Xorg.0.log", Time: Fri Sep  3 19:12:00 2021**   
Mit der Zeile **Xorg.0.log** wird dir mitgeteilt, dass das Display 0 verwendet wird, während dir **Xorg.1.log** sagt, dass das Display 1 verwendet wird.  

Jetzt fehlt noch die komplette GUI, also der Windowmanager, der Displaymanager und die Desktop-Umgebung sowie ein Tool für den Fernzugriff (X11vnc).  

**Variante 1**  
```
sudo apt install x11vnc gnome-shell ubuntu-gnome-desktop autocutsel gnome-core gnome-panel gnome-themes-standard gnome-settings-daemon metacity nautilus gnome-terminal dconf-editor gnome-tweaks yaru-theme-unity yaru-theme-gnome-shell yaru-theme-gtk yaru-theme-icon fonts-ubuntu tmux fonts-emojione
```
**Variante 2**  
Bei der jede Menge Kram mit installiert wird, welchen wir nicht wirklich benötigen, wie z.B. LibreOffice, Firefox und Thunderbird sowie paar Spiele:   
```
apt install --no-install-recommends ubuntu-desktop -y
apt install x11vnc -y
```
**Variante 3**  
Sparsame kleine Desktopumgebung (Lubuntu ohne Anwendungsprogramme)  
`apt install x11vnc lightdm lxde-core`  

Die Installation dauert jeweils paar Minuten.  
Wenn die Installation fertig ist, den Rechner neu starten:  
`reboot`  

## geht das auch mit Debian 11 und xfce? ##
Schnell mal getestet:  
### quick and dirty ###
`apt install x11vnc lightdm xfce4`  
`reboot`  
`sudo x11vnc -xkb -noxrecord -noxfixes -noxdamage -display :0 -auth /var/run/lightdm/root/:0 -usepw` 
`/usr/bin/x11vnc -xkb -noxrecord -noxfixes -noxdamage -display :0 -auth /var/run/lightdm/root/:0 -usepw`
### Autostart per systemd einrichten: ###
`nano /lib/systemd/system/x11vnc.service`  
und einfügen:
```
[Unit]
Description=Start x11vnc
After=multi-user.target

[Service]
Type=simple
ExecStart=x11vnc -xkb -noxrecord -noxfixes -noxdamage -display :0 -auth /var/run/lightdm/root/:0

[Install]
WantedBy=multi-user.target
```
dann noch   
```
systemctl daemon-reload
systemctl enable x11vnc.service
systemctl start x11vnc.service
systemctl status x11vnc.service
```

>Diese Variante ist aus Sicherheitsgründen nicht zu empfehlen, da du dann auch per VNC Viewer immer als user root unterwegs bist. Außerdem wird kein VNC-Passwort abgefragt. Diese Variante kann aber Sinn machen, wenn so eine virtuelle Maschine mal schnell, nur für wenige Stunden erzeugt, genutzt und dann wieder gelöscht wird.  
>Auf Sicherheitsaspekte bin ich hier nicht weiter eingegangen.  

Jetzt noch ffmpeg und OBS-Studio installieren:
```
# apt-get install software-properties-common
# add-apt-repository ppa:obsproject/obs-studio
apt install v4l2loopback-dkms -y
apt install ffmpeg
apt install obs-studio
# damit wird leider nur eine ältere Version von OBS installiert. Muss ich mir noch mal anschauen ;-)
```

**Testen - im VNC-Viewer z.B. von deiner Windows Maschine mit `168.xxx.xxx.xxx:5900` aufrufen.  Bei mir hat´s funktioniert.**

## und so gehts mit Ubuntu ##
Melde dich dann wieder per SSH als **root** an.  
root@ubuntu-32gb-nbg1-1:~# `ps wwwwaux | grep auth`  
Ausgabe:  
```
root        1061  1.8  0.2 1671784 69504 tty1    Sl+  12:23   0:00 /usr/lib/xorg/Xorg vt1 -displayfd 3 -auth /run/user/128/gdm/Xauthority -background none -noreset -keeptty -verbose 3
root        1516  0.0  0.0   6432   664 pts/0    S+   12:23   0:00 grep --color=auto auth
``` 
Du brauchst die Zahl zwischen /run/user/**xxx**/gdm/Xauthotity!  
Starte dann x11vnc  
root@ubuntu-32gb-nbg1-1:~# `x11vnc -auth /run/user/**XXX**/gdm/Xauthority -usepw -forever -repeat -display :0`  
Wenn alles klappt, erhältst du solche Meldungen:   

```
04/09/2021 12:14:41 -usepw: found /root/.vnc/passwd
04/09/2021 12:14:41 x11vnc version: 0.9.16 lastmod: 2019-01-05  pid: 11155
04/09/2021 12:14:41 Using X display :0
04/09/2021 12:14:41 rootwin: 0x50f reswin: 0x1400001 dpy: 0xb9710c30
04/09/2021 12:14:41
04/09/2021 12:14:41 ------------------ USEFUL INFORMATION ------------------
---
04/09/2021 12:14:41 --------------------------------------------------------
04/09/2021 12:14:41
04/09/2021 12:14:41 Default visual ID: 0x21
04/09/2021 12:14:41 Read initial data from X display into framebuffer.
04/09/2021 12:14:41 initialize_screen: fb_depth/fb_bpp/fb_Bpl 24/32/7680
04/09/2021 12:14:41
04/09/2021 12:14:41 X display :0 is 32bpp depth=24 true color
04/09/2021 12:14:41
04/09/2021 12:14:41 Autoprobing TCP port
04/09/2021 12:14:41 Autoprobing selected TCP port 5900
04/09/2021 12:14:41 Autoprobing TCP6 port
04/09/2021 12:14:41 Autoprobing selected TCP6 port 5900
04/09/2021 12:14:41 listen6: bind: Address already in use
04/09/2021 12:14:41 Not listening on IPv6 interface.
04/09/2021 12:14:41
04/09/2021 12:14:41 Xinerama is present and active (e.g. multi-head).
04/09/2021 12:14:41 Xinerama: number of sub-screens: 1
04/09/2021 12:14:41 Xinerama: no blackouts needed (only one sub-screen)
04/09/2021 12:14:41
04/09/2021 12:14:41 fb read rate: 485 MB/sec
04/09/2021 12:14:41 fast read: reset -wait  ms to: 10
04/09/2021 12:14:41 fast read: reset -defer ms to: 10
04/09/2021 12:14:41 The X server says there are 10 mouse buttons.
04/09/2021 12:14:41 screen setup finished.
04/09/2021 12:14:41

**The VNC desktop is:      ubuntu-32gb-nbg1-1:0**
**PORT=5900**
```
Herzlichen Glückwunsch. Damit läuft x11vnc für den User root.
Du musst aber auch noch für den user cloud x11vnc starten!  

**Melde dich jetzt in einem neuen Terminal per SSH als user cloud auf dem Server an.**  
Mit `echo $UID` ermittelst dui deine User ID.   
In meinem Fall 1000. Diese 1000 fügst du in der folgenden Zeile ein und startest damit x11vnc als user cloud:  
`sudo x11vnc -auth /run/user/1000/gdm/Xauthority -usepw -forever -repeat -display :1`  
**Leider funktioniert das hier nicht. Folgende Meldung erhalte ich:**
```
cloud@ubuntu-32gb-fsn1-2:~$ sudo x11vnc -auth /run/user/1000/gdm/Xauthority -usepw -forever -repeat -display :1
[sudo] password for cloud:
04/09/2021 21:51:52 -usepw: found /root/.vnc/passwd
04/09/2021 21:51:52 x11vnc version: 0.9.16 lastmod: 2019-01-05  pid: 1835
04/09/2021 21:51:52 XOpenDisplay(":1") failed.
04/09/2021 21:51:52 Trying again with XAUTHLOCALHOSTNAME=localhost ...

04/09/2021 21:51:52 ***************************************
04/09/2021 21:51:52 *** XOpenDisplay failed (:1)

*** x11vnc was unable to open the X DISPLAY: ":1", it cannot continue.
*** There may be "Xlib:" error messages above with details about the failure.
```
**Lösung:**
Rufe zuerst mit dem VNC-Viewer den "root-Bildschirm" auf: "deine Server IP":5900  
(siehe "Vom Windows Client mit dem Server verbinden")  
Ich habe mich verbinden und anmelden können. Dann kam aber ein leerer Bildschirm, da für den user cloud noch kein x11vnc Server gestartet wurde.  
Melde dich wieder ab und starte jetzt als user cloud im Terminal den x11server  
vorher kannst du mit `ps wwwwaux | grep auth`  nachschauen, ob du so eine Zeile siehst:  
`root        1990  1.2  0.2 1688272 82500 tty2    Sl+  21:55   0:00 /usr/lib/xorg/Xorg vt2 -displayfd 3 -auth /run/user/1000/gdm/Xauthority -background none -noreset -keeptty -verbose 3`  
jetzt: 
`sudo x11vnc -auth /run/user/1000/gdm/Xauthority -usepw -forever -repeat -display :1`

**Jetzt hast du zwei Instanzen von x11vnc laufen. Später werden wir das noch als Service (systemd) laufen lassen. Jetzt musst du erstmal beide Terminals noch offen lassen!**

## Vom Windows Client mit dem Server verbinden: ##  
Ich habe den RealVNC Viewer installiert.  
Starte den VNC Viewer mit "deiner Server IP":5901   
5901 ist der Standartport für Display 1, also das Display vom user cloud.  
Hat bei mir funktioniert. Mein Server hat jetzt eine GUI und ich kann per VNC darauf zugreifen  

## OBS installieren ##
im Terminal als user cloud  
zuerst ffmpeg installieren und dann:  
```
sudo apt install v4l2loopback-dkms -y
sudo add-apt-repository ppa:obsproject/obs-studio -y
sudo apt install obs-studio -y
``` 
