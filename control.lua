-- control.lua
-- Code that runs as the game is played.


-- --------------------------- Configuration ---------------------------
-- The variable values in this section are overwritten by configuration
-- settings during initialization and after re-reading updated
-- configuration values, but for ease of reference, the values here are
-- the same as the defaults in `settings.lua`.

-- How much to log, from among:
--   0: Nothing.
--   1: Only things that indicate a serious problem.  These suggest a
--      bug in this mod, but are recoverable.
--   2: Relatively infrequent things possibly of interest to the user.
--   3: More verbose user-level events.
--   4: Individual algorithm steps only of interest to a developer.
--   5: Even more algorithm details.
local diagnostic_verbosity = 1;

-- Time between checks for empty chests.
local check_period_ticks = 600;


-- ------------------------------- Data --------------------------------

-- Map from unit ID of each tracked combinator to its associated record.
--
-- Each record has:
--
--   combinator: The combinator LuaEntity.
--
--   (Currently there are no other attributes, but I retain this
--   structure it make it easy to add then if needed.)
--
-- This is populated on the first scan once the mod starts running by
-- scanning the entire map.  It is not saved to the Factorio save-game
-- file.
--
local all_combinator_records = nil;


-- Which element of `all_combinator_records` to process next in the
-- round-robin algorithm.
local next_rr_index = 1;


-- ----------------------------- Functions -----------------------------
-- Log 'str' if we are at verbosity 'v' or higher.
local function diag(v, str)
  if (v <= diagnostic_verbosity) then
    log(str);
  end;
end;


-- Return the position of `e` as a string.
local function ent_pos_str(e)
  return "(" .. e.position.x .. ", " .. e.position.y .. ")";
end;


-- Return the logistic network to use for `combinator`, or nil if none
-- is suitable.
local function find_associated_network(combinator)
  local network = combinator.surface.find_logistic_network_by_position(
    combinator.position,
    combinator.force);

  diag(4, "find_associated_network: For combinator " .. combinator.unit_number ..
          " at " .. ent_pos_str(combinator) ..
          ", found " .. (network and
                          ("network " .. network.network_id) or
                          "no network"
                        )
      );

  return network;
end;


-- Return the number of empty, general-purpose storage chests in
-- `network`, a LuaLogisticNetwork.
local function num_empty_chests(network)
  -- Count of empty chests in the network.
  local empty_count = 0;

  if (network == nil) then
    diag(4, "No associated network, count is zero.");

  else
    diag(4, "Checking network: " .. network.network_id);

    -- Hoisting this out of the loop seems to improve performance by 1-2
    -- percent.
    local defines_inventory_chest = defines.inventory.chest;

    -- Add up all of the empty storage chests.
    --
    -- This is the inner loop of the mod.  A network can have thousands
    -- of chests, so each iteration must be fast.  Consequently, the
    -- diagnostics are all commented-out unless I am in the middle of
    -- debugging.  (They triple the cost of the loop!).
    --
    for _, chest in pairs(network.storages) do
      --diag(4, "chest: " .. chest.name ..
      --        " at " .. ent_pos_str(chest));

      local inv = chest.get_inventory(defines_inventory_chest);
      if (inv == nil) then
        -- The chest has no inventory?  Then it does not count as
        -- empty because, here, "empty" means bots can use it to store
        -- things.
        --diag(4, "Has no inventory.");

      elseif (not inv.is_empty()) then
        --diag(4, "Is not empty.");

      -- If some slots have filters applied, which is detectable by
      -- calling `inv.is_filtered()`, then I would prefer to regard it
      -- as not empty because it cannot be used for general purpose
      -- storage.  But that check adds 20% to the cost of the loop, and
      -- the storage chest in the base game cannot have filtered slots,
      -- so I removed it.

      -- Note: The API docs explain that `storage_filter` can only be
      -- used on storage chests.  I think that `network.storages` only
      -- returns storage chests.  I had code to double-check the value
      -- of `chest.prototype.logistic_mode`, but that adds 10% of loop
      -- overhead, so I removed it.
      elseif (chest.storage_filter ~= nil) then
        -- A filtered chest also cannot be used for general purpose.
        --
        -- Possible TODO: Count empty chests with each distinct filter
        -- and report those as separate signals so one can create an
        -- alarm for being nearly out of storage dedicated to a
        -- particular item.
        --
        --diag(4, "Has a storage filter.");

      else
        --diag(4, "Is empty without filters, adding to count.");
        empty_count = empty_count + 1;

      end;
    end;
    diag(4, "Found " .. empty_count .. " empty chests.");
  end;

  return empty_count;
end;


-- Scan for empty chests in the network of `record`, and update its
-- combinator output signal accordingly.
local function update_one_combinator(record)
  local combinator = record.combinator;
  diag(4, "processing combinator " .. combinator.unit_number ..
          " at " .. ent_pos_str(combinator));

  -- Get the combinator signal definitions so we can adjust them.
  local control_behavior = combinator.get_control_behavior();
  if (not control_behavior.enabled) then
    diag(4, "Combinator is disabled, skipping scan.");
    return;
  end;

  -- We will operate exclusively on the first section of the signal
  -- definitions.
  local combinator_logistic_section = control_behavior.get_section(1);
  if (combinator_logistic_section == nil) then
    -- The user can delete all sections in the combinator.
    diag(4, "Missing section 1, will skip.");
    return;
  end;

  -- Count of empty chests in the network.
  local empty_count = num_empty_chests(
    find_associated_network(combinator));

  -- Set the combinator output to `empty_count`.

  -- In order to ensure there are no conflicts, clear all slots
  -- after slot 1.
  for i=2, combinator_logistic_section.filters_count do
    combinator_logistic_section.clear_slot(i);
  end;

  -- Set signal "E" to output the number of empty chests.
  combinator_logistic_section.set_slot(1, {
    value = {
      comparator = "=",
      quality = "normal",
      type = "virtual",
      name = "signal-E",
    },
    min = empty_count,
  });

end;


-- Add a combinator to those we track, and return its record.
local function add_combinator(combinator)
  local record = {
    combinator = combinator,
  };
  all_combinator_records[combinator.unit_number] = record;

  return record;
end;


-- Remove the record associated with `combinator`.
local function remove_combinator(combinator)
  all_combinator_records[combinator.unit_number] = nil;
end;


-- If necessary, initialize the set of combinators.
local function initialize_combinators_if_needed()
  if (all_combinator_records == nil) then
    diag(4, "initialize_combinators_if_needed: scanning all surfaces");

    all_combinator_records = {};

    for surface_id, surface in pairs(game.surfaces) do
      diag(4, "scanning surface: " .. surface_id);
      local combinators = surface.find_entities_filtered{
        name = "empty-chest-combinator-entity",
      };
      for _, combinator in pairs(combinators) do
        diag(4, "combinator " .. combinator.unit_number ..
                " at " .. ent_pos_str(combinator));
        add_combinator(combinator);
      end;
    end;
  end;
end;


-- Number of table entries.  How is this not built in to Lua?
function table_size(t)
  local ct = 0;
  for _, _ in pairs(t) do
    ct = ct + 1;
  end;
  return ct;
end;


-- Update combinators one at a time in a round-robin fashion.
local function update_rr_combinators()
  initialize_combinators_if_needed();

  local num_combinators = table_size(all_combinator_records);

  -- Clamp and cycle the index.
  if (next_rr_index > num_combinators) then
    next_rr_index = 1;
  end;

  diag(4, "-- update RR combinator: " .. next_rr_index ..
          " of " .. num_combinators .. " --");

  local loop_index = 1;

  -- Iterate over the records, scanning from each, and also removing
  -- any that refer to invalid entities.  (The event handlers should
  -- ensure that invalid entities are removed earlier, but this is a
  -- defensive measure, and would handle the case of a mod removing an
  -- entity without notifying event listeners.)
  for unit_number, record in pairs(all_combinator_records) do
    if (record.combinator.valid) then
      if (loop_index == next_rr_index) then
        update_one_combinator(record);
      end;

    else
      diag(4, "removing invalid entity for unit " .. unit_number);
      all_combinator_records[unit_number] = nil;

    end;

    loop_index = loop_index + 1;
  end;

  -- Increment the RR index.  It will cycle back the start when clamped
  -- at the start of the next call to this function.
  next_rr_index = next_rr_index + 1;
end;


-- ----------------------------- Settings ------------------------------
-- Re-read the configuration settings.
--
-- Below, this is done once on startup, then afterward in response to
-- the on_runtime_mod_setting_changed event.
local function read_configuration_settings()
  -- Note: Because the diagnostic verbosity is changed here, it is
  -- possible to see unpaired "begin" or "end" in the log.
  diag(4, "read_configuration_settings begin");

  -- Clear any existing tick handler.
  script.on_nth_tick(nil);

  diagnostic_verbosity = settings.global["empty-chest-combinator-diagnostic-verbosity"].value;
  check_period_ticks   = settings.global["empty-chest-combinator-check-period-ticks"].value;

  -- Re-establish the tick handler with the new period.
  script.on_nth_tick(check_period_ticks, function(e)
    update_rr_combinators();
  end);

  diag(4, "read_configuration_settings end");
end;


-- -------------------------- Event Handlers ---------------------------
local function handle_entity_created(event)
  local e = event.entity;
  diag(4, "entity " .. e.name .. " created at " .. ent_pos_str(e));

  -- Note: If the game has just been loaded, then this initialization
  -- scan will find the new combinator, making the subsequent
  -- `add_combinator` call redundant but harmless.
  initialize_combinators_if_needed();

  local record = add_combinator(e);

  -- Do an immediate update so the user can see the count without having
  -- to wait for the update period.
  update_one_combinator(record);
end;


local function handle_entity_destroyed(event)
  local e = event.entity;
  diag(4, "entity " .. e.name .. " destroyed at " .. ent_pos_str(e));

  initialize_combinators_if_needed();
  remove_combinator(e);
end;


local event_filter = {
  {
    filter = "name",
    name = "empty-chest-combinator-entity",
  },
};

script.on_event(
  defines.events.on_built_entity,
  handle_entity_created,
  event_filter);

script.on_event(
  defines.events.on_robot_built_entity,
  handle_entity_created,
  event_filter);

script.on_event(
  defines.events.on_player_mined_entity,
  handle_entity_destroyed,
  event_filter);

script.on_event(
  defines.events.on_robot_mined_entity,
  handle_entity_destroyed,
  event_filter);

script.on_event(
  defines.events.on_entity_died,
  handle_entity_destroyed,
  event_filter);


script.on_event(defines.events.on_runtime_mod_setting_changed,
  read_configuration_settings);


-- -------------------------- Initialization ---------------------------
read_configuration_settings();


-- EOF
