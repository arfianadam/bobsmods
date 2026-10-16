# Bob's Mods

Bob's Mods for Factorio 2.0.

## Installation

`bob_mod_builder.py` copies every `bob*` mod folder into your Factorio `mods` folder as `<mod>_<version>`.
It needs Python 3, and the `mods` folder must already exist: launch Factorio once before installing.

> **Warning:** the script first deletes every folder and zip in `mods` whose name contains a mod's name,
> e.g. a `bobplates_2.0.0.zip` downloaded from the mod portal. This is how it replaces older versions.

### Linux

```sh
git clone https://github.com/arfianadam/bobsmods.git
cd bobsmods
python3 bob_mod_builder.py --factoriodir="$HOME/.factorio"
```

`~/.factorio` is the data folder for Steam and package installs.
For the standalone `.tar.xz` build, pass the extracted `factorio` folder instead.

### macOS

```sh
git clone https://github.com/arfianadam/bobsmods.git
cd bobsmods
python3 bob_mod_builder.py --factoriodir="$HOME/Library/Application Support/factorio"
```

`python3` comes with the Xcode Command Line Tools (`xcode-select --install`) or Homebrew (`brew install python`).

### After installing

Start Factorio and check that the Bob's mods are enabled under **Mods** in the main menu.

To update, `git pull` and run the same command again. Run it from the repository root: it copies from the current folder.

Windows users can run `build_bobmods.bat` instead.
