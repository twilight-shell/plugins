# twilight-shell/plugins

Plugins for the [twilight-shell](https://github.com/twilight-shell)
organization's shell: this finds them, and runs the ones that are switched on.
A plugin is a folder with a `plugin.toml` and some QML; it can draw windows,
answer IPC calls and have a page of its own in the settings window. Start from
[plugin-template](https://github.com/twilight-shell/plugin-template).

## A plugin

```
~/.local/share/twilight-shell/plugins/weather/
    plugin.toml
    Weather.qml                  the file it starts from
    weather.defaults.toml        its settings and their defaults (optional)
    weather.schema.toml          how the settings window shows them (optional)
```

```toml
# plugin.toml
name = "weather"                 # what it is switched on by: letters, digits, - and _
title = "Weather"
version = "0.1.0"
description = "The weather in a corner of the screen"
author = "Someone"
entry = "Weather.qml"            # defaults to Plugin.qml
api = 1                          # the version of this interface it was made for
```

The entry is any QML, usually a `Scope` that owns windows of its own. It can use
everything the components use, starting with the sticker look from
[core](https://github.com/twilight-shell/core):

```qml
import Quickshell
import Twilight.Core

Scope {
    // Set by the shell to the output it is on; the plugin may leave it out.
    property string outputName: ""

    PanelWindow {
        screen: Quickshell.screens.find(s => s.name === outputName) ?? Quickshell.screens[0]
        // ...
    }
}
```

`outputName` is set right after the plugin is created, and follows the output
the shell is on, so react to it changing rather than reading it once.

A plugin keeps its settings the way the components do, in
`~/.config/twilight-shell/<name>.toml`, with `ConfigFile` from core. If it also
ships a `<name>.schema.toml` (see the
[settings](https://github.com/twilight-shell/settings) README), the settings
window gets a page for it without any change.

## Running it

```qml
import Twilight.Plugins

Plugins { outputName: Compositor.focusedOutput }
```

Or on its own, to try plugins out: `qs -p /path/to/plugins`.

Nothing runs by itself. A plugin has to be listed in `plugins.toml`, or switched
on in the settings window:

```toml
# ~/.config/twilight-shell/plugins.toml

# Folders searched for plugins: each holds one folder per plugin.
dirs = ["~/.local/share/twilight-shell/plugins", "/usr/share/twilight-shell/plugins"]

# The plugins that run, by name.
enabled = ["weather"]
```

Changing either file takes effect at once: plugins are started and stopped to
match. So does a plugin folder that is added or removed, a second or so after.
The first folder is made if it isn't there. If two folders hold a plugin of one
name, the first folder's wins.

| | |
|---|---|
| `outputName` | The output the plugins are to appear on. |
| `available` | What was found: `name`, `title`, `version`, `description`, `author`, `entry`, `api`, `dir` and whether it is `enabled`, `running` or has an `error`. |
| `enabled`, `dirs` | What `plugins.toml` says. |
| `running` | The names of the plugins that are running. |
| `reload()` | Loads the whole shell again, which runs the edited files of a plugin. |

IPC: `qs -c shell ipc call plugins list` shows each plugin and what is wrong with
it, `plugins scan` looks in the folders again (a plugin whose files changed in
place, say), `plugins reload` loads the shell again. A plugin that doesn't load is reported in the
shell's log and in `list`, and the others go on running.

## What to know

- **A plugin is code with your rights.** It can run programs and read your files;
  there is no sandbox, and QML can't have one. That is why nothing runs until you
  switch it on: do that for plugins you trust.
- Qt keeps the QML it has loaded. Switching a plugin off and on runs the same code again; to run the files you have edited, use `plugins reload`, or restart the shell.
- `api` is the version of the interface a plugin was made for. A plugin that asks
  for a newer one than this shell has is listed but not started.

## Installing

Needs [Quickshell](https://quickshell.org) 0.3 or newer, with
[twilight-shell/core](https://github.com/twilight-shell/core) installed.

```sh
sudo make install        # to /usr/lib/qt6/qml/Twilight/Plugins
```

## License

MIT, see `LICENSE`.
