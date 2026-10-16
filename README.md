# Bob's Mods

Bob's Mods for Factorio 2.0.

## Installation

Symlink each mod folder from this repository into your Factorio `mods` folder with `ln -s`.
The `mods` folder must already exist: launch Factorio once before installing.

`bobplates`, `bobelectronics` and `bobclasses` are left out on purpose.

> **Note:** first remove any other copy of these mods from `mods`, such as a `bobores_2.1.2` folder
> or a `bobores_2.1.2.zip` from the mod portal. Factorio won't start with two copies of the same mod.

```sh
git clone https://github.com/arfianadam/bobsmods.git
cd bobsmods
MODS="$HOME/.factorio/mods" # macOS: MODS="$HOME/Library/Application Support/factorio/mods"
for mod in bobassembly bobenemies bobequipment bobgreenhouse bobinserters boblibrary boblogistics \
  bobmining bobmodules bobores bobpower bobrevamp bobtech bobvehicleequipment bobwarfare; do
  ln -sfn "$PWD/$mod" "$MODS/$mod"
done
```

On Linux, `~/.factorio` is the data folder for Steam and package installs.
For the standalone `.tar.xz` build, use the `mods` folder inside the extracted `factorio` folder instead.

### After installing

Start Factorio and check that the Bob's mods are enabled under **Mods** in the main menu.

To update, `git pull` and restart Factorio. The links point into this clone, so don't move or delete it.

Windows users can run `build_bobmods.bat` instead.
