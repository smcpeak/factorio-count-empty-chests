-- settings.lua
-- Configuration settings.


data:extend({
  -- Time between checks for empty chests.
  {
    type = "int-setting",
    name = "empty-chest-combinator-check-period-ticks",
    setting_type = "runtime-global",
    default_value = 600,
    minimum_value = 1,
    maximum_value = 3600,
  },

  -- Diagnostic log verbosity level.  See 'diagnostic_verbosity' in
  -- control.lua.
  {
    type = "int-setting",
    name = "empty-chest-combinator-diagnostic-verbosity",
    setting_type = "runtime-global",
    default_value = 1,
    minimum_value = 0,
    maximum_value = 5,
  },
});


-- EOF
