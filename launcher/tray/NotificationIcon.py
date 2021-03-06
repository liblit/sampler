# -*- coding: utf-8 -*-

import gi
gi.require_version('Notify', '0.7')

from gi.repository import GLib, Gtk, Notify

import Keys


BODY = 'You are now using instrumented software from the <a href="http://research.cs.wisc.edu/cbi/">Cooperative Bug Isolation Project</a>.  Automatic feedback reporting is <b>%s</b>.'


BODY_HYPERLINKS = True


WORDS = {
    True: (
        'enabled',
        'Enable',
        ),
    False: (
        'disabled',
        'Disable',
        ),
    }


class NotificationIcon(object):

    __slots__ = '__note'

    def __init__(self, settings):
        Notify.init('Bug Isolation Monitor')
        self.__note = None

        # workaround for <https://bugzilla.gnome.org/show_bug.cgi?id=653033>
        if 'body-hyperlinks' not in Notify.get_server_caps():
            import re
            global BODY, BODY_HYPERLINKS
            BODY = re.sub('<(a href="[^"]*"|/a)>', '', BODY)
            BODY_HYPERLINKS = False

        key = Keys.MASTER
        settings.connect('changed::' + key, self.__changed_enabled)
        self.__changed_enabled(settings, key)

    def close(self):
        if self.__note:
            try:
                self.__note.close()
            except GLib.GError:
                pass
        self.__note = None

    # GSettings signal callbacks

    def __changed_enabled(self, settings, key):

        enabled = settings[key]
        adjective = WORDS[enabled][0]
        Imperative = WORDS[not enabled][1]

        summary = 'CBI reporting is %s' % adjective
        body = BODY % adjective
        themed = 'sampler-' + ('enabled' if enabled else 'disabled')

        note = Notify.Notification(summary=summary, body=body, icon_name=themed)
        note.set_urgency(Notify.Urgency.LOW)
        note.set_hint('resident', GLib.Variant.new_boolean(True))
        note.set_hint_string('desktop-entry', 'sampler-tray')

        note.add_action('toggle', Imperative, self.__set_enabled, (settings, key, not enabled))
        if not BODY_HYPERLINKS:
            note.add_action('learn-more', 'Learn More…', self.__learn_more, None)

        self.close()
        self.__note = note
        if self.__show_note(note):
            GLib.timeout_add_seconds(1, self.__show_note, note)

    def __show_note(self, note):
        if self.__note:
            try:
                note.show()
            except GLib.GError:
                return True
        return False

    # notification action callbacks

    def __learn_more(self, note, action, unused):
        __pychecker__ = 'no-argsused'
        destination = 'http://research.cs.wisc.edu/cbi/learn-more/'
        timestamp = Gtk.get_current_event_time()
        Gtk.show_uri(None, destination, timestamp)

    def __set_enabled(self, note, action, (settings, key, enabled)):
        __pychecker__ = 'no-argsused'
        settings[key] = enabled
