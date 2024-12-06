# Count Empty Chests

Count Empty Chests is a mod for [Factorio](https://wiki.factorio.com/).

It provides a combinator that outputs a signal indicating the number of
completely-empty storage chests in the logistic network it is placed in.

The primary intended use case is to set up an alarm for when the storage
is close to being full.  Although Factorio provides a built-in alert for
when the storage is completely full, that is only triggered once every
*slot* is full, meaning that by then, many chests have been filled with
a random assortment of various items, which is a mess to clean up.  With
this mod, you can set up an alert to trigger before the bots start
packing the chests to the gills with random trash.

## State of work

Work in progress.

## Performance considerations

TODO

## Uninstallation

Simply remove the mod, as there should be no unexpected adverse
consequences:

* The mod adds one new entity, the combinator that counts empty chests.
  If you remove the mod, then instances of that entity will be deleted.

* The mod does not add any save-game state of its own.

## Related mods

In my search, the only vaguely related mod I found was [Chest Slot
Reader](https://mods.factorio.com/mod/chest-slot-reader), but that just
reads the number of empty slots in a single chest, whereas I want the
number of completely empty *chests* across an entire network.

Otherwise, I didn't find anything similar to this mod in my search.  Let
me know if you know of another mod that does something like this, since
at very least I'd like to link to related alternatives.
