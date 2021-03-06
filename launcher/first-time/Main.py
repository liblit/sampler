from gi.repository import GLib, Gtk
from os.path import abspath, dirname, join
from sys import argv, path

path.insert(1, join(dirname(dirname(abspath(__file__))), 'common'))


########################################################################


def activate(application):
    windows = application.get_windows()
    if windows:
        windows[0].present_with_time(Gtk.get_current_event_time())
    else:
        from FirstTime import FirstTime
        dialog = FirstTime(application)
        GLib.idle_add(dialog.run)


def main():
    application = Gtk.Application.new('edu.wisc.cs.cbi.FirstTime', 0)
    application.connect('activate', activate)
    status = application.run(argv)
    exit(status)
