import gconf
import gtk.gdk
import gtk.glade

from AboutDialog import AboutDialog
from GConfNotifier import GConfNotifier
from LazyWidget import LazyWidget

import Keys
import Paths


class PopupMenu(LazyWidget):
    def __init__(self, client, preferences):
        LazyWidget.__init__(self, 'popup')
        self.__about = AboutDialog(client)
        self.__client = client
        self.__preferences = preferences

    def populate(self, xml, widget):
        self.__notifier = GConfNotifier(self.__client, Keys.master, self.__master_refresh)
        self.__master = xml.get_widget('menu-master')
        self.__master_refresh()

    def popup(self, event):
        assert event.type == gtk.gdk.BUTTON_PRESS
        self.widget().popup(None, None, None, event.button, event.time)

    def on_master_toggled(self, item):
        active = item.get_active()
        self.__client.set_bool(Keys.master, active)
        self.__master_refresh()

    def __master_refresh(self, *args):
        self.__master.set_active(self.__client.get_bool(Keys.master))

    def on_preferences_activate(self, item):
        self.__preferences.present()

    def on_about_activate(self, item):
        self.__about.present()
