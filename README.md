# OBSinTheCloud
OBS Studio in the cloud  
**inspiriert von Martin Sauters Blog https://blog.wirelessmoves.com/2021/07/running-obs-studio-in-the-cloud.html**  
> OBS in der Cloud bietet mir einige Vorteile, wenn ich z.B. bei Outdoor-Sportveranstaltungen, wie Radrennen, Motorsportveranstaltungen oder Skilanglaufmarathons, Videostreams mit mobilen Kameras mit 4G-Encodern produziere. Der Schnitt und die Produktion des fertigen Programms kann dann ortsunabhängig, von einem kleinen Rechner aus, in der Cloud erfolgen.

## Grundinstallation ##
### Ubuntu 20.04 ###
#### Server ohne GPU ####
Eine sehr einfache Lösung: miete bei Hetzner einen virtuellen Server.
Damit hat es funktioniert:
Intel Xeon, CX51, 8VCPU´s, 32 GB RAM, 240 GB Disk Lokal mit Ubuntu 20.04  
Aber auch andere Varianten mit AMD Prozessoren habe ich getestet und funktionieren. Da Hetzner aktuell (02/2022) keine Server mit GPU anbietet, müssen wir die fehlende Grafikkarte mit vielen CPU-Kernen ersetzen. Wenn ich Full-HD (1080p) Streams mit 30 fps bearbeiten und weiterleiten will, benötige ich 32 Kerne und trotzdem werden immer wieder mal paar Frames fallen gelassen. Also testen, testen und testen.   
#### Warum Linux und nicht Windows? ####
- Kostenreduzierung (keine Lizenzkosten)
- effektivere Auslastung der Hardware  

### xserver-xorg-video-dummy ###
Nach der Buchung des Servers mit Ubuntu, zuerst das Repository aktualisieren, den Video-Dummy-Treiber und das X-Windows-System installieren und einen neuen Benutzer zur Verwendung in der GUI wie folgt erstellen:

`apt update -y && apt upgrade -y`  
`apt install xserver-xorg-video-dummy -y`  
  
`adduser obs`  
und ihm root Rechte geben  
`usermod -aG sudo obs`  

### X11 konfigurieren ###

Da unser ausgewählter virtueller Server über keine Grafikarte und auch keinen Bildschirm verfügt, müssen wir diese simulieren und konfigurieren. Mit den folgenden Einstellungen in der Konfigurationsdatei wird ein Monitor erstellt/simuliert, der mit einer Bildwiederholfrequenz von genau 60 Hz läuft. Dies ist wichtig für OBS, um qualitativ hochwertige Aufnahmen von Videostreams mit 1080p und 30 oder 60 Hz zu erstellen!  
Dafür hat X-Windows die Konfigurationsdatei **/etc/X11/xorg.conf**, die folgenden Inhalt haben sollte:  

`nano /etc/X11/xorg.conf`    

```
# This xorg configuration file is meant to be used
# to start a dummy X11 server.
# For details, please see:
# https://www.xpra.org/xorg.conf

# Here we setup a Virtual Display of 1920x1080 pixels
 
Section "Device"
  Identifier "dummy_videocard"
  Driver "dummy"
  Option "ConstantDPI" "true"
  #VideoRam 4096000
  #VideoRam 256000
  VideoRam 192000
EndSection

Section "Monitor"
  Identifier "dummy_monitor"
  HorizSync   5.0 - 1000.0
  VertRefresh 5.0 - 200.0
  # Modeline Calculator
  # https://arachnoid.com/modelines/
  # 1920x1080 @ 60.00 Hz (GTF) hsync: 67.08 kHz; pclk: 172.80 MHz
  Modeline "1920x1080_60.00" 172.80 1920 2040 2248 2576 1080 1081 1084 1118 -HSync +Vsync
EndSection

Section "Screen"
  Identifier "dummy_screen"
    Device "dummy_videocard"
    Monitor "dummy_monitor"
    DefaultDepth 24
    SubSection "Display"
        Viewport 0 0
        Depth 24
        Virtual 1920 1080
    EndSubSection
EndSection
```

OBS macht aber mit zwei Monitoren (Studio-Ansicht und Multiview-Ansicht) mehr Spaß.
Das grundlegende Verfahren besteht darin, einen „Monitor“-Abschnitt pro Monitor zu definieren und dann alles in einem „Device“-Abschnitt zusammenzufassen, der den Videochip angibt, der die Monitore ansteuert.  
Dazu habe ich hier paar Infos gefunden: https://wiki.archlinux.org/title/Multihead  

Variante für zwei gleiche Monitore an einer Grafikkarte: `xorg.conf`, die aber so nicht funktioniert:    
```
#Virtual Display of 1920x1080 pixels
 
Section "Device"
  Identifier "dummy_videocard"
  Driver "dummy"
  Option "ConstantDPI" "true"
  #VideoRam 4096000
  #VideoRam 256000
  VideoRam 192000
EndSection

Section "Monitor"
  Identifier "dummy_monitor_1"
  HorizSync   5.0 - 1000.0
  VertRefresh 5.0 - 200.0
  Modeline "1920x1080_60.00" 172.80 1920 2040 2248 2576 1080 1081 1084 1118 -HSync +Vsync
  Option "Primary" "true"
  Option "LeftOf" "dummy_monitor_2"
EndSection

Section "Monitor"
  Identifier "dummy_monitor_2"
  HorizSync   5.0 - 1000.0
  VertRefresh 5.0 - 200.0
  Modeline "1920x1080_60.00" 172.80 1920 2040 2248 2576 1080 1081 1084 1118 -HSync +Vsync
  Option "RightOf" "dummy_monitor_1"
EndSection

Section "Screen"
  Identifier "dummy_screen_1"
    Device "dummy_videocard"
    Monitor "dummy_monitor_1"
    DefaultDepth 24
    SubSection "Display"
        Viewport 0 0
        Depth 24
        Virtual 1920 1080
    EndSubSection
EndSection

Section "Screen"
  Identifier "dummy_screen_2"
    Device "dummy_videocard"
    Monitor "dummy_monitor_2"
    DefaultDepth 24
    SubSection "Display"
        Viewport 0 0
        Depth 24
        Virtual 1920 1080
    EndSubSection
EndSection

Section "ServerLayout"
    Identifier "Main Layout"
    Screen 1 "dummy_screen_1"
    Screen 2 "dummy_screen_2"
EndSection
```

Als nächstes X-Windows konfigurieren, indem du **X** als user **root** startest und nach kurzer Zeit, sobald die Konfiguration geschrieben wurde und die Ausgabe im Terminal stoppt, mit **STRG-C** abbrichst.  
**`X -config /etc/X11/xorg.conf`**  
(Im Skript geht das nicht. Deshalb mal testen, ob ich den X-Server mit nohup einfach in einer extra Shell laufen lassen.)
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

## Sprache einstellen ##
`locale-gen de_DE.UTF-8`  

## GUI installieren ##
>Achtung: OBS Studio benötigt OpenGL 3.3 oder höher für Linux. Du kannst die Version von OpenGL deines Systems überprüfen, indem du `glxinfo | grep "OpenGL"` im Terminal eingibst. Dazu musst du vorher aber noch die mesa-utils installieren: `apt install mesa-utils`.  

Jetzt fehlt noch die komplette GUI, also der Windowmanager, der Displaymanager und die Desktop-Umgebung sowie ein Tool für den Fernzugriff (X11vnc).  
Dafür kannst du dich jetzt als user obs zusätzlich per ssh auf deinem Server neu anmelden.  

**Variante**  
apt install gnome-session gnome-terminal -y
apt install nautilus 
apt install x11vnc -y

**Variante 1**  
Dabei werden z.B. Firefox, LibreOffice und Thunderbird mitinstalliert.
```
sudo apt install x11vnc gnome-shell ubuntu-gnome-desktop autocutsel gnome-core gnome-panel gnome-themes-standard gnome-settings-daemon metacity nautilus gnome-terminal dconf-editor gnome-tweaks yaru-theme-unity yaru-theme-gnome-shell yaru-theme-gtk yaru-theme-icon fonts-ubuntu tmux fonts-emojione -y
```
**Variante 2**  
Bei der noch etwas zusätzliche Software mit installiert wird, wie z.B. LibreOffice, Firefox und Thunderbird sowie paar Spiele ... entspricht Variante 1 (??):   
```
apt install ubuntu-desktop --no-install-recommends -y
apt install x11vnc -y
```
**Variante 3**  
Sparsame kleine Desktopumgebung (Lubuntu ohne Anwendungsprogramme)  
`apt install x11vnc lightdm lxde-core`  

Die Installation dauert jeweils paar Minuten.  

## reboot ##
Wenn die Installation fertig ist, den Rechner neu starten:  
`reboot`  oder reicht auch `sudo systemctl restart gdm`??   
mal testen, ob das funktioniert:  
```
displaymanager=$( cut -d/ -f4 /etc/X11/default-display-manager )  
systemctl restart $displaymanager
``` 
---  

## geht das auch mit Debian 11 und xfce? ##
Schnell mal getestet:  
### quick and dirty ###
`apt update -y && apt upgrade -y`  
`adduser cloud`  
`usermod -aG sudo cloud`  
`apt install xserver-xorg-video-dummy -y`  
**jetzt die /etc/X11/xorg.conf erstellen**  
`apt install x11vnc lightdm xfce4`  
`apt install xfce4-terminal`  
`reboot`  
**wieder per SSH als user root verbinden und x11vnc starten**
`/usr/bin/x11vnc -xkb -noxrecord -noxfixes -noxdamage -display :0 -auth /var/run/lightdm/root/:0 -usepw`  
Im Terminal wird jetzt x11vnc gestartet. Wenn alles Fehlerfrei durchläuft erhältst du unter anderem die Info:  
*The VNC desktop is:  debian....:0  
PORT=5900*  
**testen, ob der Fernzugriff per VNC Viewer funktioniert:**  
-> z.B. im VNC-Viewer von deiner lokalen Windows Maschine mit `<Cloud-Server-IP>:5900` aufrufen. Bei mir hat´s funktioniert.  
Das ist der Root-Zugriff
### Autostart für x11vnc per systemd einrichten: ###
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
dann noch:    
```
systemctl daemon-reload
systemctl enable x11vnc.service
systemctl start x11vnc.service
systemctl status x11vnc.service
```

>Diese Variante ist aus Sicherheitsgründen nicht zu empfehlen, da du dann auch per VNC Viewer immer als user root unterwegs bist. Außerdem wird kein VNC-Passwort abgefragt. Diese Variante macht auch keinen Sinn, wenn so eine virtuelle Maschine mal schnell, nur für wenige Stunden erzeugt, genutzt und dann wieder gelöscht wird, denn bereits nach wenigen Minuten wird deine Maschine von Boots gescannt und angegriffen.   

Jetzt noch ffmpeg und OBS-Studio installieren:
```
#apt-get install software-properties-common
#add-apt-repository ppa:obsproject/obs-studio
apt install v4l2loopback-dkms -y
apt install ffmpeg
apt install obs-studio
#Bei Debian wird (01/2022) auf diese Weise leider nur eine ältere Version von OBS installiert. 
```
>Debian hat den Nachteil, das sich OBS nur in älteren Versionen über den Paktemanager installieren lässt. Ubuntu basiert zwar auch auf Debian, bringt aber von Haus aus deutlich aktuellere Software mit. Deswegen werde ich Ubuntu nutzen!  

### noch paar Infos: ###
x11vnc Passwort ändern: `x11vnc -storepasswd`  
x11vnc starten:  `x11vnc -auth /run/user/root/gdm/Xauthority -usepw -forever -repeat -display :0`  

---  

##  jetzt zurück zu Ubuntu ##
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

**Melde dich jetzt in einem neuen Terminal per SSH als user obs auf dem Server an.**  
Mit `echo $UID` ermittelst du deine User ID.   
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
**Achtung: In der Firewall müssen die Ports 5900 und 5901 offen !**  
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

## Pulseaudio ##
Wir brauchen auch Audio für die OBS-Aufnahme. PulseAudio-System funktioniert auch dann gut, wenn keine physische Soundkarte vorhanden ist.   
`sudo apt install pulseaudio jackd2 alsa-utils dbus-x11`  

## OBS installieren ##
https://obsproject.com/wiki/install-instructions  
im Terminal als user cloud  
zuerst ffmpeg installieren und dann:  
```
sudo apt install v4l2loopback-dkms -y
sudo add-apt-repository ppa:obsproject/obs-studio -y
# sudo apt update -y
sudo apt install obs-studio -y
``` 
In der Cloud bei Hetzner funktioniert so allerdings die "Virtuelle Kamera" noch nicht. Die Schaltfläche "Virtuelle Kamera" wird zwar angezeigt, beim Draufklicken öffnet sich ein Fenster mit einer Passwortabfrage, mehr passiert aber nicht. Im Log sehe ich folgende Fehlermeldung:  
`modprobe: ERROR: could not insert 'v4l2loopback': Unknown symbol in module, or unknown parameter (see dmesg)`  
Lösung:  
```
# OBS beenden und dann:  
sudo apt -y install v4l2loopback-dkms v4l2loopback-utils linux-modules-extra-$(uname -r)  
sudo modprobe v4l2loopback
```
Jetzt läuft auch die "Virtuelle Kamera".  

## Google Chrome installieren ##
```
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb  
sudo apt install ./google-chrome-stable_current_amd64.deb -y  
```

## TeamViewer installieren ##
```
wget https://download.teamviewer.com/download/linux/teamviewer_amd64.deb  
sudo apt install ./teamviewer_amd64.deb -y  

```
