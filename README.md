# Count Empty Chests

Count Empty Chests is a mod for [Factorio](https://wiki.factorio.com/).

It provides a combinator that outputs a signal indicating the number of
completely-empty storage chests in the logistic network it is placed in.

The primary intended use case is to set up an alarm for when the storage
is close to being full.  Although Factorio provides a built-in alert for
when the storage is completely full, that is only triggered once every
*slot* is full, meaning that by then, many chests have been filled with
a random assortment of items, which is then a mess to clean up.  With
this mod, you can set up an alert to trigger before the bots start
packing the chests to the gills with random trash.

## Performance considerations

This mod is intended to be used in factories that have large storage
networks.

Counting the number of empty chests must be done with a loop; the API
does not provide anything better.  For a logistic network containing
(say) 4000 chests (regardless of whether they are empty), it takes
around 10 ms to loop over them, and the time scales linearly with the
number of chests.  10 ms of time spent in a mod is roughly the point
where frames start getting delayed because it only leaves 6 ms for
everything else.

Therefore, this does a few things to limit the performance impact:

* The combinator update code only runs once every 600 ticks (10 seconds)
  by default.

* Each update only looks at one combinator, cycling through them over
  time.  So if you have N combinators in the world, then each combinator
  gets updated every 600*N ticks.

* The loop code itself has been profiled and optimized.

In terms of factory design, considering the above, it is better to use
just one combinator per network and route the one signal to where it
needs to go, rather than use multiple combinators if the information is
needed in multiple places.

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
