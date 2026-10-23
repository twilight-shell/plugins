# Contributing to plugins

Thank you for helping. The guide for every repository of the organization is [here](https://github.com/twilight-shell/.github/blob/main/CONTRIBUTING.md): how to propose a change, the commit messages, the checks and the code style. What follows is what is particular to this repository.

## Working on it

- **What it needs:** Twilight.Core. Clone them next to this one and put their parent folders on `QML_IMPORT_PATH`, separated by `:`, as full paths (not `~`).
- **Run it:** `XDG_CONFIG_HOME=$(mktemp -d) QML_IMPORT_PATH=$HOME/src/core:$HOME/src/plugins qs -p .` (the first part keeps your real settings out of it). Then `qs -p . ipc call plugins list`; point `dirs` in a throwaway `plugins.toml` at a folder of test plugins.
- **Tests:** there is no test for the screen: run it and look, and say in the pull request what you tried and on which compositor.
- **Before sending:** run the checks of the guide (`ci/run-tests.sh`, `check-settings.sh`, `check-depends.sh`, `check-install.sh` from the `.github` repository) and add a line to `CHANGELOG.md` under `## Unreleased`.

## Good to know

- A plugin is code with the user's rights and there is no sandbox. Nothing runs unless it is in `enabled`; don't weaken that.
- Qt caches loaded QML: switching a plugin off and on runs the same code. `plugins reload` loads the whole shell again. `api` is the version of the interface (`Plugins.api`); raise it when the interface changes in a way a plugin can notice.
- `FolderListModel` doesn't watch a folder that isn't there yet: the first folder is made before the folders are watched.

For security problems, please don't open an issue: see [SECURITY.md](https://github.com/twilight-shell/.github/blob/main/SECURITY.md).
