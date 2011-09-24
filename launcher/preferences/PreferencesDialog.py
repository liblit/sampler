import Keys


class PreferencesDialog(object):

    __slots__ = ['__apps_group', '__client', '__dialog', '__dir']

    def __init__(self, application):
        from gi.repository import Gtk
        import Paths
        builder = Gtk.Builder()
        builder.add_from_file(Paths.ui)
        builder.connect_signals(self)
        self.__dialog = builder.get_object('preferences')
        self.__dialog.set_application(application)

        from gi.repository import GConf
        from GConfDir import GConfDir
        self.__client = GConf.Client.get_default()
        self.__dir = GConfDir(self.__client, Keys.root, GConf.ClientPreloadType.PRELOAD_NONE)

        from AppFinder import AppFinder
        from AppModel import AppModel
        from Application import Application
        finder = AppFinder(self.__client)
        model = AppModel()
        for path in finder:
            Application(self.__client, model, path)

        from gi.repository import Gio
        settings = Gio.Settings(Keys.BASE)

        from WindowIcon import WindowIcon
        WindowIcon(settings, self.__dialog)
        settings.bind(Keys.MASTER, builder.get_object('master'), 'active', Gio.SettingsBindFlags.DEFAULT)
        settings.bind(Keys.MASTER, builder.get_object('apps-group'), 'sensitive', Gio.SettingsBindFlags.DEFAULT)

        view = builder.get_object('applications')

        selection = view.get_selection()
        selection.set_mode(Gtk.SelectionMode.NONE)

        renderer = Gtk.CellRendererText()
        column = Gtk.TreeViewColumn('Application', renderer)
        column.set_cell_data_func(renderer, self.__name_data_func)
        column.set_sort_column_id(model.COLUMN_NAME)
        column.set_reorderable(True)
        column.set_resizable(True)
        view.append_column(column)

        renderer = Gtk.CellRendererToggle()
        renderer.connect('toggled', self.on_application_toggled, model)
        column = Gtk.TreeViewColumn('Enabled', renderer)
        column.set_cell_data_func(renderer, self.__enabled_data_func)
        column.set_sort_column_id(model.COLUMN_ENABLED)
        column.set_reorderable(True)
        view.append_column(column)

        view.set_model(model)

    def __name_data_func(self, column, renderer, model, iterator, unused):
        __pychecker__ = 'no-argsused'
        app = model.get_value(iterator, model.COLUMN_NAME)
        renderer.set_property('text', app.name)

    def __enabled_data_func(self, column, renderer, model, iterator, unused):
        __pychecker__ = 'no-argsused'
        app = model.get_value(iterator, model.COLUMN_ENABLED)
        renderer.set_property('active', app.get_enabled())

    def on_application_toggled(self, renderer, path, model):
        __pychecker__ = 'no-argsused'
        path = int(path)
        iterator = model.get_iter(path)
        app = model.get_value(iterator, model.COLUMN_ENABLED)
        app.set_enabled(not app.get_enabled())

    def run(self):
        result = self.__dialog.run()
        self.__dialog.destroy()
        return result
