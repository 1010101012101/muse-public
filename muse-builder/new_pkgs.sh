#!/bin/bash
##
## Copyright (c) 2014-2017 Leidos.
## 
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##
##
## Developed under contract #FA8750-14-C-0241
##

export DEBIAN_FRONTEND noninteractive
export TERM linux

echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections
dpkg-reconfigure debconf
apt-get update

apt-get -f install -y

echo "installing *** graphicsmagick-imagemagick-compat ***"
apt-get install -y graphicsmagick-imagemagick-compat
echo "installing *** libbjack-ocaml-dev ***"
apt-get install -y libbjack-ocaml-dev
echo "installing *** libclam-dev ***"
apt-get install -y libclam-dev
echo "installing *** libgdal-dev ***"
apt-get install -y libgdal-dev
echo "installing *** libgdal1-dev ***"
apt-get install -y libgdal1-dev
echo "installing *** libgdchart-gd2-noxpm-dev ***"
apt-get install -y libgdchart-gd2-noxpm-dev
echo "installing *** libhdf5-serial-dev ***"
apt-get install -y libhdf5-serial-dev
echo "installing *** libmatio-dev:amd64 ***"
apt-get install -y libmatio-dev:amd64
echo "installing *** libxatracker-dev-lts-utopic:amd64 ***"
apt-get install -y libxatracker-dev-lts-utopic:amd64
echo "installing *** phonon-backend-gstreamer:amd64 ***"
apt-get install -y phonon-backend-gstreamer:amd64
echo "installing *** python3-requests ***"
apt-get install -y python3-requests
echo "installing *** python3-requests-oauthlib ***"
apt-get install -y python3-requests-oauthlib
echo "installing *** python3-urllib3 ***"
apt-get install -y python3-urllib3
echo "installing *** tix ***"
apt-get install -y tix
echo "installing *** tix-dev ***"
apt-get install -y tix-dev
echo "installing *** tk-dev:amd64 ***"
apt-get install -y tk-dev:amd64
echo "installing *** tk8.4 ***"
apt-get install -y tk8.4
echo "installing *** tmux ***"
apt-get install -y tmux
echo "installing *** tofrodos ***"
apt-get install -y tofrodos
echo "installing *** tomboy ***"
apt-get install -y tomboy
echo "installing *** tomcat6 ***"
apt-get install -y tomcat6
echo "installing *** tor ***"
apt-get install -y tor
echo "installing *** torsocks ***"
apt-get install -y torsocks
echo "installing *** troffcvt ***"
apt-get install -y troffcvt
echo "installing *** trscripts ***"
apt-get install -y trscripts
echo "installing *** ttf-kochi-gothic ***"
apt-get install -y ttf-kochi-gothic
echo "installing *** ttf-kochi-mincho ***"
apt-get install -y ttf-kochi-mincho
echo "installing *** ttf-wqy-microhei ***"
apt-get install -y ttf-wqy-microhei
echo "installing *** ttf-wqy-zenhei ***"
apt-get install -y ttf-wqy-zenhei
echo "installing *** ttf2ufm ***"
apt-get install -y ttf2ufm
echo "installing *** ttfautohint ***"
apt-get install -y ttfautohint
echo "installing *** tth ***"
apt-get install -y tth
echo "installing *** tuxcmd ***"
apt-get install -y tuxcmd
echo "installing *** twiggy ***"
apt-get install -y twiggy
echo "installing *** twm ***"
apt-get install -y twm
echo "installing *** txt2html ***"
apt-get install -y txt2html
echo "installing *** txt2man ***"
apt-get install -y txt2man
echo "installing *** txt2tags ***"
apt-get install -y txt2tags
echo "installing *** u-boot-tools ***"
apt-get install -y u-boot-tools
echo "installing *** ubuntu-artwork ***"
apt-get install -y ubuntu-artwork
echo "installing *** ubuntu-download-manager ***"
apt-get install -y ubuntu-download-manager
echo "installing *** ubuntu-drivers-common ***"
apt-get install -y ubuntu-drivers-common
echo "installing *** ubuntu-ui-toolkit-doc ***"
apt-get install -y ubuntu-ui-toolkit-doc
echo "installing *** ubuntu-ui-toolkit-examples ***"
apt-get install -y ubuntu-ui-toolkit-examples
echo "installing *** ubuntu-wallpapers ***"
apt-get install -y ubuntu-wallpapers
echo "installing *** ubuntu-wallpapers-trusty ***"
apt-get install -y ubuntu-wallpapers-trusty
echo "installing *** ubuntuone-dev-tools ***"
apt-get install -y ubuntuone-dev-tools
echo "installing *** umockdev ***"
apt-get install -y umockdev
echo "installing *** unicode-data ***"
apt-get install -y unicode-data
echo "installing *** unicon-imc2 ***"
apt-get install -y unicon-imc2
echo "installing *** unity-action-doc ***"
apt-get install -y unity-action-doc
echo "installing *** unity-webapps-common ***"
apt-get install -y unity-webapps-common
echo "installing *** unity-webapps-dev ***"
apt-get install -y unity-webapps-dev
echo "installing *** unixodbc-bin ***"
apt-get install -y unixodbc-bin
echo "installing *** unoconv ***"
apt-get install -y unoconv
echo "installing *** unshield ***"
apt-get install -y unshield
echo "installing *** uthash-dev ***"
apt-get install -y uthash-dev
echo "installing *** uuagc ***"
apt-get install -y uuagc
echo "installing *** uuid-runtime ***"
apt-get install -y uuid-runtime
echo "installing *** vala-0.16-doc ***"
apt-get install -y vala-0.16-doc
echo "installing *** vala-dbus-binding-tool ***"
apt-get install -y vala-dbus-binding-tool
echo "installing *** valabind ***"
apt-get install -y valabind
echo "installing *** valac ***"
apt-get install -y valac
echo "installing *** valac-0.14 ***"
apt-get install -y valac-0.14
echo "installing *** valac-0.16 ***"
apt-get install -y valac-0.16
echo "installing *** valac-0.16-vapi ***"
apt-get install -y valac-0.16-vapi
echo "installing *** valac-0.18 ***"
apt-get install -y valac-0.18
echo "installing *** valac-0.18-vapi ***"
apt-get install -y valac-0.18-vapi
echo "installing *** valac-0.20 ***"
apt-get install -y valac-0.20
echo "installing *** valac-0.20-vapi ***"
apt-get install -y valac-0.20-vapi
echo "installing *** valac-0.22 ***"
apt-get install -y valac-0.22
echo "installing *** valac-0.22-vapi ***"
apt-get install -y valac-0.22-vapi
echo "installing *** valadoc ***"
apt-get install -y valadoc
echo "installing *** valgrind ***"
apt-get install -y valgrind
echo "installing *** vamp-plugin-sdk:amd64 ***"
apt-get install -y vamp-plugin-sdk:amd64
echo "installing *** vc-dev ***"
apt-get install -y vc-dev
echo "installing *** vdr-dev ***"
apt-get install -y vdr-dev
echo "installing *** vflib3 ***"
apt-get install -y vflib3
echo "installing *** vflib3-dev ***"
apt-get install -y vflib3-dev
echo "installing *** visp-images-data ***"
apt-get install -y visp-images-data
echo "installing *** vlan ***"
apt-get install -y vlan
echo "installing *** vmfs-tools ***"
apt-get install -y vmfs-tools
echo "installing *** voms-clients ***"
apt-get install -y voms-clients
echo "installing *** vstream-client-dev ***"
apt-get install -y vstream-client-dev
echo "installing *** vtk-doc ***"
apt-get install -y vtk-doc
echo "installing *** vxi-dev ***"
apt-get install -y vxi-dev
echo "installing *** w3c-dtd-xhtml ***"
apt-get install -y w3c-dtd-xhtml
echo "installing *** w3c-sgml-lib ***"
apt-get install -y w3c-sgml-lib
echo "installing *** wamerican-huge ***"
apt-get install -y wamerican-huge
echo "installing *** wamerican-insane ***"
apt-get install -y wamerican-insane
echo "installing *** wamerican-large ***"
apt-get install -y wamerican-large
echo "installing *** wamerican-small ***"
apt-get install -y wamerican-small
echo "installing *** wbritish ***"
apt-get install -y wbritish
echo "installing *** wbritish-huge ***"
apt-get install -y wbritish-huge
echo "installing *** wbritish-insane ***"
apt-get install -y wbritish-insane
echo "installing *** wbritish-large ***"
apt-get install -y wbritish-large
echo "installing *** wbritish-small ***"
apt-get install -y wbritish-small
echo "installing *** websockify ***"
apt-get install -y websockify
echo "installing *** wkhtmltopdf ***"
apt-get install -y wkhtmltopdf
echo "installing *** wmaker ***"
apt-get install -y wmaker
echo "installing *** wmaker-common ***"
apt-get install -y wmaker-common
echo "installing *** wml ***"
apt-get install -y wml
echo "installing *** woff-tools ***"
apt-get install -y woff-tools
echo "installing *** wordnet ***"
apt-get install -y wordnet
echo "installing *** wordnet-base ***"
apt-get install -y wordnet-base
echo "installing *** wordnet-dev ***"
apt-get install -y wordnet-dev
echo "installing *** wordnet-sense-index ***"
apt-get install -y wordnet-sense-index
echo "installing *** wpasupplicant ***"
apt-get install -y wpasupplicant
echo "installing *** wvdial ***"
apt-get install -y wvdial
echo "installing *** wx2.8-i18n ***"
apt-get install -y wx2.8-i18n
echo "installing *** x11-session-utils ***"
apt-get install -y x11-session-utils
echo "installing *** x11-xfs-utils ***"
apt-get install -y x11-xfs-utils
echo "installing *** x11proto-bigreqs-dev ***"
apt-get install -y x11proto-bigreqs-dev
echo "installing *** x11proto-dri3-dev ***"
apt-get install -y x11proto-dri3-dev
echo "installing *** x11proto-present-dev ***"
apt-get install -y x11proto-present-dev
echo "installing *** x11proto-xcmisc-dev ***"
apt-get install -y x11proto-xcmisc-dev
echo "installing *** x11proto-xf86bigfont-dev ***"
apt-get install -y x11proto-xf86bigfont-dev
echo "installing *** x11proto-xf86dri-dev ***"
apt-get install -y x11proto-xf86dri-dev
echo "installing *** xa65 ***"
apt-get install -y xa65
echo "installing *** xaw3dg-dev:amd64 ***"
apt-get install -y xaw3dg-dev:amd64
echo "installing *** xcftools ***"
apt-get install -y xcftools
echo "installing *** xchat-common ***"
apt-get install -y xchat-common
echo "installing *** xchat-gnome ***"
apt-get install -y xchat-gnome
echo "installing *** xchat-gnome-common ***"
apt-get install -y xchat-gnome-common
echo "installing *** xclip ***"
apt-get install -y xclip
echo "installing *** xcursor-themes ***"
apt-get install -y xcursor-themes
echo "installing *** xdelta3 ***"
apt-get install -y xdelta3
echo "installing *** xdg-user-dirs ***"
apt-get install -y xdg-user-dirs
echo "installing *** xdotool ***"
apt-get install -y xdotool
echo "installing *** xemacs21 ***"
apt-get install -y xemacs21
echo "installing *** xemacs21-basesupport ***"
apt-get install -y xemacs21-basesupport
echo "installing *** xemacs21-bin ***"
apt-get install -y xemacs21-bin
echo "installing *** xemacs21-mule ***"
apt-get install -y xemacs21-mule
echo "installing *** xemacs21-mulesupport ***"
apt-get install -y xemacs21-mulesupport
echo "installing *** xemacs21-support ***"
apt-get install -y xemacs21-support
echo "installing *** xfce4-dev-tools ***"
apt-get install -y xfce4-dev-tools
echo "installing *** xfce4-panel ***"
apt-get install -y xfce4-panel
echo "installing *** xfce4-panel-dev ***"
apt-get install -y xfce4-panel-dev
echo "installing *** xfig ***"
apt-get install -y xfig
echo "installing *** xfonts-intl-asian ***"
apt-get install -y xfonts-intl-asian
echo "installing *** xfonts-intl-chinese ***"
apt-get install -y xfonts-intl-chinese
echo "installing *** xfonts-intl-chinese-big ***"
apt-get install -y xfonts-intl-chinese-big
echo "installing *** xfonts-intl-european ***"
apt-get install -y xfonts-intl-european
echo "installing *** xfonts-intl-japanese ***"
apt-get install -y xfonts-intl-japanese
echo "installing *** xfonts-intl-japanese-big ***"
apt-get install -y xfonts-intl-japanese-big
echo "installing *** xfonts-intl-phonetic ***"
apt-get install -y xfonts-intl-phonetic
echo "installing *** xfonts-scalable ***"
apt-get install -y xfonts-scalable
echo "installing *** xfonts-unifont ***"
apt-get install -y xfonts-unifont
echo "installing *** xfpt ***"
apt-get install -y xfpt
echo "installing *** xfsdump ***"
apt-get install -y xfsdump
echo "installing *** xfslibs-dev ***"
apt-get install -y xfslibs-dev
echo "installing *** xgraph ***"
apt-get install -y xgraph
echo "installing *** xkb-data-i18n ***"
apt-get install -y xkb-data-i18n
echo "installing *** xmhtml1:amd64 ***"
apt-get install -y xmhtml1:amd64
echo "installing *** xmhtml1-dev:amd64 ***"
apt-get install -y xmhtml1-dev:amd64
echo "installing *** xml-twig-tools ***"
apt-get install -y xml-twig-tools
echo "installing *** xmlroff ***"
apt-get install -y xmlroff
echo "installing *** xmlstarlet ***"
apt-get install -y xmlstarlet
echo "installing *** xmltex ***"
apt-get install -y xmltex
echo "installing *** xmltoman ***"
apt-get install -y xmltoman
echo "installing *** xmltooling-schemas ***"
apt-get install -y xmltooling-schemas
echo "installing *** xorg-docs-core ***"
apt-get install -y xorg-docs-core
echo "installing *** xplanet ***"
apt-get install -y xplanet
echo "installing *** xscreensaver ***"
apt-get install -y xscreensaver
echo "installing *** xscreensaver-data ***"
apt-get install -y xscreensaver-data
echo "installing *** xscreensaver-data-extra ***"
apt-get install -y xscreensaver-data-extra
echo "installing *** xscreensaver-gl ***"
apt-get install -y xscreensaver-gl
echo "installing *** xscreensaver-gl-extra ***"
apt-get install -y xscreensaver-gl-extra
echo "installing *** xscreensaver-screensaver-bsod ***"
apt-get install -y xscreensaver-screensaver-bsod
echo "installing *** xscreensaver-screensaver-webcollage ***"
apt-get install -y xscreensaver-screensaver-webcollage
echo "installing *** xsdcxx ***"
apt-get install -y xsdcxx
echo "installing *** yapps2 ***"
apt-get install -y yapps2
echo "installing *** yard ***"
apt-get install -y yard
echo "installing *** yasm ***"
apt-get install -y yasm
echo "installing *** yaz ***"
apt-get install -y yaz
echo "installing *** yelp-tools ***"
apt-get install -y yelp-tools
echo "installing *** yorick ***"
apt-get install -y yorick
echo "installing *** yorick-data ***"
apt-get install -y yorick-data
echo "installing *** yorick-dev ***"
apt-get install -y yorick-dev
echo "installing *** yorick-yutils ***"
apt-get install -y yorick-yutils
echo "installing *** yui-compressor ***"
apt-get install -y yui-compressor
echo "installing *** yydebug ***"
apt-get install -y yydebug
echo "installing *** z80asm ***"
apt-get install -y z80asm
echo "installing *** zathura-dev ***"
apt-get install -y zathura-dev
echo "installing *** zbuildtools ***"
apt-get install -y zbuildtools
echo "installing *** zh-autoconvert ***"
apt-get install -y zh-autoconvert
echo "installing *** zlib-bin ***"
apt-get install -y zlib-bin
echo "installing *** zookeeper ***"
apt-get install -y zookeeper
echo "installing *** zope-debhelper ***"
apt-get install -y zope-debhelper
echo "installing *** zsh ***"
apt-get install -y zsh
echo "installing *** zsh-common ***"
apt-get install -y zsh-common
