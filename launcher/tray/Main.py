#!/usr/bin/python -O

import os

import pygtk
pygtk.require('2.0')

import bonobo
import gconf
import gnome

from Factory import Factory
from GConfDir import GConfDir
from UploaderTrayIcon import UploaderTrayIcon

import Config
import Keys
import monitor


########################################################################


gnome.program_init('tray', Config.version)
client = gconf.client_get_default()
dir = GConfDir(client, Keys.root, gconf.CLIENT_PRELOAD_ONELEVEL)

factory = Factory()

tray = UploaderTrayIcon(client)
tray.show_all()

if not client.get_bool(Keys.asked):
    first_time = os.path.join('@first_timedir@', 'first-time')
    os.spawnl(os.P_NOWAIT, first_time, first_time)

bonobo.main()
