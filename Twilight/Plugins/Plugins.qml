import QtQuick
import Quickshell
import Quickshell.Io
import Twilight.Core

// Finds the plugins and runs the ones that are enabled. A plugin is a folder
// with a plugin.toml next to the QML file it starts from:
//
//     name = "weather"            # the name it is enabled by, no spaces
//     title = "Weather"
//     version = "0.1.0"
//     description = "The weather in the bar"
//     author = "Someone"
//     entry = "Weather.qml"       # defaults to Plugin.qml
//     api = 1                     # the version of this interface it was made for
//
// The entry is any QML, usually a Scope with windows of its own. If it has
// an `outputName` property, the output the shell is on is set there.
//
// IPC: `qs -c shell ipc call plugins list`, `plugins reload` (the whole shell
// is loaded again, which runs the edited files of a plugin)
Scope {
    id: root

    // Name of the output the plugins are to appear on, set by the host.
    property string outputName: ""

    // What is found: [{ name, title, version, description, author, entry, api,
    // dir, enabled, running, error }], in the order of the folders.
    readonly property var available: scanned.map(p => Object.assign({}, p, {
        enabled: enabled.includes(p.name),
        running: running.includes(p.name),
        error: errors[p.name] ?? ""
    }))
    // The folders that are searched, `~` made the home folder.
    readonly property var dirs: (config.get("dirs") ?? []).map(expand)
    // The names that are switched on in plugins.toml.
    readonly property var enabled: config.get("enabled") ?? []

    // The version of the interface a plugin has to ask for, or lower.
    readonly property int api: 1

    // The names of the plugins that are running.
    property var running: []
    // What went wrong with a plugin, by its name.
    property var errors: ({})

    property var scanned: []
    property var objects: ({})

    function expand(path: string): string {
        return path.startsWith("~") ? Quickshell.env("HOME") + path.slice(1) : path;
    }

    // Looks in the folders again, and starts and stops plugins to match. One
    // look at a time: a look that is asked for during another one waits for it,
    // so an answer for old folders can't come after the one for the new ones.
    property bool rescan: false

    function scan(): void {
        if (finder.running) {
            rescan = true;
            return;
        }
        if (dirs.length === 0) {
            scanned = [];
            sync();
            return;
        }
        finder.running = true;
    }

    // Starts the plugins that are enabled and not running, and stops those that
    // are running and no longer wanted.
    function sync(): void {
        const wanted = scanned.filter(p => enabled.includes(p.name) && p.api <= api);
        for (const name of Object.keys(objects)) {
            if (!wanted.some(p => p.name === name))
                stop(name);
        }
        for (const p of wanted) {
            if (!(p.name in objects))
                start(p);
        }
    }

    function fail(name: string, message: string): void {
        console.warn("twilight: plugin " + name + ": " + message);
        errors = Object.assign({}, errors, { [name]: message });
    }

    function start(p): void {
        const component = Qt.createComponent("file://" + p.dir + "/" + p.entry);
        if (component.status !== Component.Ready) {
            fail(p.name, component.errorString().trim());
            return;
        }
        const object = component.createObject(root);
        if (!object) {
            fail(p.name, "can't create " + p.entry + ": " + component.errorString().trim());
            return;
        }
        if ("outputName" in object)
            object.outputName = Qt.binding(() => root.outputName);

        objects[p.name] = object;
        running = Object.keys(objects);
        const rest = Object.assign({}, errors);
        delete rest[p.name];
        errors = rest;
    }

    function stop(name: string): void {
        objects[name].destroy();
        delete objects[name];
        running = Object.keys(objects);
    }

    // Qt keeps the QML it has loaded, so the only way to run the edited files of
    // a plugin is to load the shell again. This is for developing a plugin.
    function reload(): void {
        Quickshell.reload(false);
    }

    function parse(chunk: string): var {
        const nl = chunk.indexOf("\n");
        const path = chunk.slice(0, nl);
        const dir = path.slice(0, path.lastIndexOf("/"));
        try {
            const manifest = Toml.parse(chunk.slice(nl + 1));
            if (typeof manifest.name !== "string" || !/^[A-Za-z0-9_-]+$/.test(manifest.name)) {
                console.warn("twilight: " + path + ": needs a name of letters, digits, - and _");
                return null;
            }
            return {
                name: manifest.name,
                title: manifest.title ?? manifest.name,
                version: manifest.version ?? "",
                description: manifest.description ?? "",
                author: manifest.author ?? "",
                entry: manifest.entry ?? "Plugin.qml",
                api: manifest.api ?? 1,
                dir: dir
            };
        } catch (e) {
            console.warn("twilight: " + path + ": " + e.message);
            return null;
        }
    }

    ConfigFile {
        id: config

        name: "plugins"
        defaults: Qt.resolvedUrl("plugins.defaults.toml")
    }

    onDirsChanged: scan()
    onEnabledChanged: sync()
    Component.onCompleted: scan()

    Process {
        id: finder

        command: ["sh", "-c", "find -L \"$@\" -maxdepth 2 -name plugin.toml -exec sh -c 'for f; do printf \"@@@%s\\n\" \"$f\"; cat \"$f\"; done' _ {} + 2>/dev/null", "_"].concat(root.dirs)
        onExited: {
            if (root.rescan) {
                root.rescan = false;
                root.scan();
            }
        }
        stdout: StdioCollector {
            onStreamFinished: {
                // Folders changed meanwhile: this answer is for the old ones.
                if (root.rescan)
                    return;
                const seen = [];
                const found = [];
                for (const chunk of text.split("@@@").filter(c => c.trim() !== "")) {
                    const p = root.parse(chunk);
                    // Two plugins of one name: the first folder's wins.
                    if (p && !seen.includes(p.name)) {
                        seen.push(p.name);
                        found.push(p);
                    }
                }
                found.sort((a, b) => a.title.localeCompare(b.title));
                root.scanned = found;
                root.sync();
            }
        }
    }

    IpcHandler {
        target: "plugins"

        function list(): string {
            return root.available.map(p => p.name + (p.running ? " (running)" : p.enabled ? " (enabled)" : "") + (p.error ? " - " + p.error.split("\n")[0] : "")).join("\n");
        }

        function reload(): void {
            root.reload();
        }
    }
}
