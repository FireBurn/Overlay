#!/bin/bash
cd ~/frida-build/fc
rm -rf build
VALAC=/usr/bin/valac-0.58 meson setup build --wrap-mode=nodownload -Dbuildtype=release -Ddefault_library=static \
  -Dfruity_backend=disabled -Ddroidy_backend=disabled -Dsimmy_backend=disabled -Dbarebone_backend=disabled \
  -Dconnectivity=disabled -Dportal=disabled -Dgadget=disabled -Dinject=disabled -Dserver=disabled \
  -Dcompat=disabled -Ddevkits=core -Dtests=disabled \
  -Dfrida-gum:v8=disabled -Dfrida-gum:quickjs=enabled -Dfrida-gum:database=disabled -Dfrida-gum:gumpp=disabled -Dfrida-gum:tests=disabled -Dglib:introspection=disabled --force-fallback-for=glib-2.0,gobject-2.0,gio-2.0,gio-unix-2.0,gmodule-2.0,gthread-2.0,json-glib-1.0,gee-0.8,capstone "$@" 2>&1 | tail -${TAILN:-15}
