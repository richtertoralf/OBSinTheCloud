# OBSinTheCloud
OBS Studio in the cloud
inspiriert von Martin Sauters Blog https://blog.wirelessmoves.com/2021/07/running-obs-studio-in-the-cloud.html

Bei Hetzner einen virtuellen Server mieten  
Intel Xeon, CX51, 8VCPU´s, 32 GB RAM, 240 GB Disk Lokal, 35,58 Euro monatlich  
mit Ubuntu 20.04  

8 vCPUs müssten für für 1920x1080p-Streaming und -Aufzeichnung funktionieren  
 
Zuerst wird das Repository aktualisiert, der Video-Dummy-Treiber und das X-Server-System installiert und ein neuer Benutzer zur Verwendung in der GUI wie folgt erstellt:

`apt update -y && apt upgrade -y`  
 
`apt install xserver-xorg-video-dummy -y`  

einen user 'cloud' anlegen, damit du nicht als 'root' arbeiten musst  
`adduser cloud`  
und ihm root Rechte geben  
`usermod -aG sudo cloud`  

Der X-Server benötigt eine Konfigurationsdatei in /etc/X11/xorg.conf, die folgenden Inhalt haben sollte:  
Die in dieser Konfigurationsdatei verwendete Modeline erstellt einen Monitor, der mit einer Bildwiederholfrequenz von genau 60 Hz läuft. Dies ist wichtig für OBS, um qualitativ hochwertige Aufnahmen von Videostreams zu erstellen!  

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
Als nächstes konfigurieren und startest du den X-Server und brichst ihn Sie mit STRG-C ab, sobald die Konfiguration geschrieben wurde und die Ausgabe nach kurzer Zeit stoppt:

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
**Identifizieren der Displaynummer**    
Wenn kein anderer X-Server läuft, wird standardmäßig die Anzeigenummer 0 verwendet. Suche nach dieser Zeile, um die verwendete Anzeige zu identifizieren:  
hier ist sie **(==) Log file: "/var/log/Xorg.0.log", Time: Fri Sep  3 19:12:00 2021**   
In dieser Zeile  Xorg.0.logwird dir mitgeteilt, dass das Display 0 verwendet wird, während dir Xorg.1.log sagt, dass das Display 1 verwendet wird.  

Jetzt fehlt noch die komplette GUI.    

```
sudo apt install x11vnc gnome-shell ubuntu-gnome-desktop autocutsel gnome-core gnome-panel gnome-themes-standard gnome-settings-daemon metacity nautilus gnome-terminal dconf-editor gnome-tweaks yaru-theme-unity yaru-theme-gnome-shell yaru-theme-gtk yaru-theme-icon fonts-ubuntu tmux fonts-emojione
```
Das dauert paar Minuten.  
Wenn die Installation fertig ist, den Rechner neu starten:  
`reboot`  

Melde dich dann wieder als **root** an.  
Ermittle als nächstes die user-ID vom user 'cloud':  
`id -u cloud`  
Ergibt bei mir 1000  
Verwende in der nächsten Zeile die Benutzer-ID von 'cloud' und   
gibt bei der ersten Abfrage dann das von dir dem Benutzer 'cloud' gegebene Passwort und die richtige Display-Nummer z.B. 0 ein:  

Stand 04.09.2021: 
nach `reboot`  
per ssh wieder als root anmelden  
root@ubuntu-32gb-nbg1-1:~# `ps wwwwaux | grep auth`  
Ausgabe:  
```
root        1061  1.8  0.2 1671784 69504 tty1    Sl+  12:23   0:00 /usr/lib/xorg/Xorg vt1 -displayfd 3 -auth /run/user/128/gdm/Xauthority -background none -noreset -keeptty -verbose 3
root        1516  0.0  0.0   6432   664 pts/0    S+   12:23   0:00 grep --color=auto auth
``` 
```
root@ubuntu-32gb-nbg1-1:~# id -u root
0
root@ubuntu-32gb-nbg1-1:~# id -u cloud
1000
```   

wenn ich dann:  
root@ubuntu-32gb-nbg1-1:~# `x11vnc -auth /run/user/128/gdm/Xauthority -usepw -forever -repeat -display :0`  so x11vnc starte,  
bekomme ich folgende Meldungen:   

```
root@ubuntu-32gb-nbg1-1:~# x11vnc -auth /run/user/128/gdm/Xauthority -usepw -forever -repeat -display :0
04/09/2021 12:14:41 -usepw: found /root/.vnc/passwd
04/09/2021 12:14:41 x11vnc version: 0.9.16 lastmod: 2019-01-05  pid: 11155
04/09/2021 12:14:41 Using X display :0
04/09/2021 12:14:41 rootwin: 0x50f reswin: 0x1400001 dpy: 0xb9710c30
04/09/2021 12:14:41
04/09/2021 12:14:41 ------------------ USEFUL INFORMATION ------------------
04/09/2021 12:14:41 X DAMAGE available on display, using it for polling hints.
04/09/2021 12:14:41   To disable this behavior use: '-noxdamage'
04/09/2021 12:14:41
04/09/2021 12:14:41   Most compositing window managers like 'compiz' or 'beryl'
04/09/2021 12:14:41   cause X DAMAGE to fail, and so you may not see any screen
04/09/2021 12:14:41   updates via VNC.  Either disable 'compiz' (recommended) or
04/09/2021 12:14:41   supply the x11vnc '-noxdamage' command line option.
04/09/2021 12:14:41
04/09/2021 12:14:41 Wireframing: -wireframe mode is in effect for window moves.
04/09/2021 12:14:41   If this yields undesired behavior (poor response, painting
04/09/2021 12:14:41   errors, etc) it may be disabled:
04/09/2021 12:14:41    - use '-nowf' to disable wireframing completely.
04/09/2021 12:14:41    - use '-nowcr' to disable the Copy Rectangle after the
04/09/2021 12:14:41      moved window is released in the new position.
04/09/2021 12:14:41   Also see the -help entry for tuning parameters.
04/09/2021 12:14:41   You can press 3 Alt_L's (Left "Alt" key) in a row to
04/09/2021 12:14:41   repaint the screen, also see the -fixscreen option for
04/09/2021 12:14:41   periodic repaints.
04/09/2021 12:14:41
04/09/2021 12:14:41 XFIXES available on display, resetting cursor mode
04/09/2021 12:14:41   to: '-cursor most'.
04/09/2021 12:14:41   to disable this behavior use: '-cursor arrow'
04/09/2021 12:14:41   or '-noxfixes'.
04/09/2021 12:14:41 using XFIXES for cursor drawing.
04/09/2021 12:14:41 GrabServer control via XTEST.
04/09/2021 12:14:41
04/09/2021 12:14:41 Scroll Detection: -scrollcopyrect mode is in effect to
04/09/2021 12:14:41   use RECORD extension to try to detect scrolling windows
04/09/2021 12:14:41   (induced by either user keystroke or mouse input).
04/09/2021 12:14:41   If this yields undesired behavior (poor response, painting
04/09/2021 12:14:41   errors, etc) it may be disabled via: '-noscr'
04/09/2021 12:14:41   Also see the -help entry for tuning parameters.
04/09/2021 12:14:41   You can press 3 Alt_L's (Left "Alt" key) in a row to
04/09/2021 12:14:41   repaint the screen, also see the -fixscreen option for
04/09/2021 12:14:41   periodic repaints.
04/09/2021 12:14:41
04/09/2021 12:14:41 XKEYBOARD: number of keysyms per keycode 7 is greater
04/09/2021 12:14:41   than 4 and 51 keysyms are mapped above 4.
04/09/2021 12:14:41   Automatically switching to -xkb mode.
04/09/2021 12:14:41   If this makes the key mapping worse you can
04/09/2021 12:14:41   disable it with the "-noxkb" option.
04/09/2021 12:14:41   Also, remember "-remap DEAD" for accenting characters.
04/09/2021 12:14:41
04/09/2021 12:14:41 X FBPM extension not supported.
Xlib:  extension "DPMS" missing on display ":0".
04/09/2021 12:14:41 X display is not capable of DPMS.
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

The VNC desktop is:      ubuntu-32gb-nbg1-1:0
PORT=5900

******************************************************************************
Have you tried the x11vnc '-ncache' VNC client-side pixel caching feature yet?

The scheme stores pixel data offscreen on the VNC viewer side for faster
retrieval.  It should work with any VNC viewer.  Try it by running:

    x11vnc -ncache 10 ...

One can also add -ncache_cr for smooth 'copyrect' window motion.
More info: http://www.karlrunge.com/x11vnc/faq.html#faq-client-caching
```

Als nächstes melde ich mich per SSH als user cloud an.  
und versuche x11vnc  so zu starten:  
`sudo x11vnc -auth /run/user/1000/gdm/Xauthority -usepw -forever -repeat -display :1`  
Ich bekomme folgende Meldungen:  
```
cloud@ubuntu-32gb-nbg1-1:~$ sudo x11vnc -auth /run/user/1000/gdm/Xauthority -usepw -forever -repeat -display :1
04/09/2021 12:32:15 -usepw: found /root/.vnc/passwd
04/09/2021 12:32:15 x11vnc version: 0.9.16 lastmod: 2019-01-05  pid: 1817
04/09/2021 12:32:15 XOpenDisplay(":1") failed.
04/09/2021 12:32:15 Trying again with XAUTHLOCALHOSTNAME=localhost ...

04/09/2021 12:32:15 ***************************************
04/09/2021 12:32:15 *** XOpenDisplay failed (:1)

*** x11vnc was unable to open the X DISPLAY: ":1", it cannot continue.
*** There may be "Xlib:" error messages above with details about the failure.

Some tips and guidelines:

** An X server (the one you wish to view) must be running before x11vnc is
   started: x11vnc does not start the X server.  (however, see the -create
   option if that is what you really want).

** You must use -display <disp>, -OR- set and export your $DISPLAY
   environment variable to refer to the display of the desired X server.
 - Usually the display is simply ":0" (in fact x11vnc uses this if you forget
   to specify it), but in some multi-user situations it could be ":1", ":2",
   or even ":137".  Ask your administrator or a guru if you are having
   difficulty determining what your X DISPLAY is.

** Next, you need to have sufficient permissions (Xauthority)
   to connect to the X DISPLAY.   Here are some Tips:

 - Often, you just need to run x11vnc as the user logged into the X session.
   So make sure to be that user when you type x11vnc.
 - Being root is usually not enough because the incorrect MIT-MAGIC-COOKIE
   file may be accessed.  The cookie file contains the secret key that
   allows x11vnc to connect to the desired X DISPLAY.
 - You can explicitly indicate which MIT-MAGIC-COOKIE file should be used
   by the -auth option, e.g.:
       x11vnc -auth /home/someuser/.Xauthority -display :0
       x11vnc -auth /tmp/.gdmzndVlR -display :0
   you must have read permission for the auth file.
   See also '-auth guess' and '-findauth' discussed below.

** If NO ONE is logged into an X session yet, but there is a greeter login
   program like "gdm", "kdm", "xdm", or "dtlogin" running, you will need
   to find and use the raw display manager MIT-MAGIC-COOKIE file.
   Some examples for various display managers:

     gdm:     -auth /var/gdm/:0.Xauth
              -auth /var/lib/gdm/:0.Xauth
     kdm:     -auth /var/lib/kdm/A:0-crWk72
              -auth /var/run/xauth/A:0-crWk72
     xdm:     -auth /var/lib/xdm/authdir/authfiles/A:0-XQvaJk
     dtlogin: -auth /var/dt/A:0-UgaaXa

   Sometimes the command "ps wwwwaux | grep auth" can reveal the file location.

   Starting with x11vnc 0.9.9 you can have it try to guess by using:

              -auth guess

   (see also the x11vnc -findauth option.)

   Only root will have read permission for the file, and so x11vnc must be run
   as root (or copy it).  The random characters in the filenames will of course
   change and the directory the cookie file resides in is system dependent.

See also: http://www.karlrunge.com/x11vnc/faq.html
```
## Anmeldung mit VNC Viewer von einem Windows-PC
als root bekam ich auf dem Server folgende Meldung:  
```
04/09/2021 12:14:41 screen setup finished.  
04/09/2021 12:14:41  
The VNC desktop is:      ubuntu-32gb-nbg1-1:0
PORT=5900  
```
Deshalb verwende ich folgende Einstellungen auf dem Windows-PC:  
**VNC-Server: <IP-Adresse des Servers>:5900**
**Name: ubuntu-32gb-nbg1-1:0**
 
Ich kann jetzt die GUI des Servers erreichen und kann mich dort als user 'cloud' anmelden, erhalte dann aber nur einen leeren  Bildschirm.

**Es läuft ja nur der Bildschirm :0 für den User root. Das Display für den user cloud habe ich ja noch nicht zum Laufen gebracht.**
 
Im Terminal auf dem Server, bei dem ich noch als root angemeldet bin und zuvor x11vnc gestartet habe, erhalte ich folgende Meldungen:  
```
04/09/2021 12:46:12 Got connection from client 93.197.255.7
04/09/2021 12:46:12   other clients:
04/09/2021 12:46:12 Normal socket connection
04/09/2021 12:46:12 incr accepted_client=1 for 93.197.255.7:64345  sock=10
04/09/2021 12:46:13 Client Protocol Version 3.8
04/09/2021 12:46:13 Protocol version sent 3.8, using 3.8
04/09/2021 12:46:13 rfbProcessClientSecurityType: executing handler for type 2
04/09/2021 12:46:13 created   xdamage object: 0x1400040
04/09/2021 12:46:17 client_set_net: 93.197.255.7  0.0375
04/09/2021 12:46:17 rfbProcessClientNormalMessage: ignoring unsupported encoding type Enc(0x00000018)
04/09/2021 12:46:17 rfbProcessClientNormalMessage: ignoring unsupported encoding type Enc(0x00000016)
04/09/2021 12:46:17 rfbProcessClientNormalMessage: ignoring unsupported encoding type Enc(0x00000015)
04/09/2021 12:46:17 rfbProcessClientNormalMessage: ignoring unsupported encoding type Enc(0x0000000F)
04/09/2021 12:46:17 rfbProcessClientNormalMessage: ignoring unsupported encoding type Enc(0xFFFFFEC6)
04/09/2021 12:46:17 Enabling full-color cursor updates for client 93.197.255.7
04/09/2021 12:46:17 Enabling NewFBSize protocol extension for client 93.197.255.7
04/09/2021 12:46:17 Using ZRLE encoding for client 93.197.255.7
04/09/2021 12:46:17 Pixel format for client 93.197.255.7:
04/09/2021 12:46:17   8 bpp, depth 6
04/09/2021 12:46:17   true colour: max r 3 g 3 b 3, shift r 4 g 2 b 0
04/09/2021 12:46:18 rfbProcessClientNormalMessage: ignoring unsupported encoding type Enc(0x00000018)
04/09/2021 12:46:18 rfbProcessClientNormalMessage: ignoring unsupported encoding type Enc(0x00000016)
04/09/2021 12:46:18 rfbProcessClientNormalMessage: ignoring unsupported encoding type Enc(0x00000015)
04/09/2021 12:46:18 rfbProcessClientNormalMessage: ignoring unsupported encoding type Enc(0x0000000F)
04/09/2021 12:46:18 rfbProcessClientNormalMessage: ignoring unsupported encoding type Enc(0xFFFFFEC6)
04/09/2021 12:46:18 Enabling full-color cursor updates for client 93.197.255.7
04/09/2021 12:46:18 Enabling NewFBSize protocol extension for client 93.197.255.7
04/09/2021 12:46:18 Switching from ZRLE to raw Encoding for client 93.197.255.7
04/09/2021 12:46:18 rfbProcessClientNormalMessage: ignoring unsupported encoding type Enc(0x00000018)
04/09/2021 12:46:18 rfbProcessClientNormalMessage: ignoring unsupported encoding type Enc(0x00000016)
04/09/2021 12:46:18 rfbProcessClientNormalMessage: ignoring unsupported encoding type Enc(0x00000015)
04/09/2021 12:46:18 rfbProcessClientNormalMessage: ignoring unsupported encoding type Enc(0x0000000F)
04/09/2021 12:46:18 rfbProcessClientNormalMessage: ignoring unsupported encoding type Enc(0xFFFFFEC6)
04/09/2021 12:46:18 Enabling full-color cursor updates for client 93.197.255.7
04/09/2021 12:46:18 Enabling NewFBSize protocol extension for client 93.197.255.7
04/09/2021 12:46:18 Switching from raw to ZRLE Encoding for client 93.197.255.7
04/09/2021 12:46:18 Pixel format for client 93.197.255.7:
04/09/2021 12:46:18   32 bpp, depth 24, little endian
04/09/2021 12:46:18   true colour: max r 255 g 255 b 255, shift r 16 g 8 b 0
04/09/2021 12:46:18 no translation needed
04/09/2021 12:46:18 client 1 network rate 143.3 KB/sec (143.3 eff KB/sec)
04/09/2021 12:46:18 client 1 latency:  25.2 ms
04/09/2021 12:46:18 dt1: 0.0003, dt2: 0.1358 dt3: 0.0252 bytes: 17694
04/09/2021 12:46:18 link_rate: LR_BROADBAND - 25 ms, 143 KB/s
04/09/2021 12:46:20 copy_tiles: allocating first_line at size 61
04/09/2021 12:46:21 created selwin: 0x1400041
04/09/2021 12:46:21 called initialize_xfixes()
04/09/2021 12:46:41 increased wireframe timeouts for slow network connection.
04/09/2021 12:46:41 netrate: 143 KB/sec, latency: 25 ms
```  
Wenn ich mich vom Windows-PC wieder abmelde, sehe ich auf dem Server Folgendes:  
```  
04/09/2021 12:52:22 client_count: 0
04/09/2021 12:52:22 Client 93.197.255.7 gone
04/09/2021 12:52:22 Statistics             events    Transmit/ RawEquiv ( saved)
04/09/2021 12:52:22  ServerCutText       :      1 |         8/        8 (  0.0%)
04/09/2021 12:52:22  FramebufferUpdate   :    145 |         0/        0 (  0.0%)
04/09/2021 12:52:22  raw                 :      1 |     17292/    17292 (  0.0%)
04/09/2021 12:52:22  ZRLE                :    282 |    150842/ 31222952 ( 99.5%)
04/09/2021 12:52:22  RichCursor          :     13 |     26178/    26178 (  0.0%)
04/09/2021 12:52:22  TOTALS              :    442 |    194320/ 31266430 ( 99.4%)
04/09/2021 12:52:22 Statistics             events    Received/ RawEquiv ( saved)
04/09/2021 12:52:22  ClientCutText       :      1 |       127/      127 (  0.0%)
04/09/2021 12:52:22  KeyEvent            :     54 |       432/      432 (  0.0%)
04/09/2021 12:52:22  PointerEvent        :    543 |      3258/     3258 (  0.0%)
04/09/2021 12:52:22  FramebufferUpdate   :    146 |      1460/     1460 (  0.0%)
04/09/2021 12:52:22  SetPixelFormat      :      2 |        40/       40 (  0.0%)
04/09/2021 12:52:22  SetEncodings        :      3 |       168/      168 (  0.0%)
04/09/2021 12:52:22  TOTALS              :    749 |      5485/     5485 (  0.0%)
04/09/2021 12:52:22 destroyed xdamage object: 0x1400040
```
