-- rEle - a multimode delay for fx mod
-- v1.0 @sonoCircuit

local fx = require 'fx/lib/fx'
local md = require 'core/mods'

local FxRele = fx:new{subpath = "/fx_rele"}

local del = {}
del.mode = 0
del.sync = true
del.rate_l = 1/4
del.rate_r = 1/4
del.rate_names = {"1/16", "1/12", "3/32", "1/8", "1/6", "3/16", "1/4","1/3", "3/8", "1/2", "2/3", "3/4", "1"}
del.rate_values = {1/16, 1/12, 3/32, 1/8, 1/6, 3/16, 1/4, 1/3, 3/8, 1/2, 2/3, 3/4, 1}

local prms = {"level", "type", "mode", "time_l", "time_r", "rate_l", "rate_r", "time", "rate", "feedback", "lpf_cutoff", "hpf_cutoff", "modulation"}

local function bang_params()
  clock.run(function()
    clock.sleep(1)
    for _, p in ipairs(prms) do
      params:lookup_param(p):bang()
    end
  end)
end

local function update_delay_params()
  if del.mode == 1 then
    params:hide("fx_rele_rate_l")
    params:hide("fx_rele_rate_r")
    params:hide("fx_rele_time_l")
    params:hide("fx_rele_time_r")
    if del.sync then
      params:show("fx_rele_rate")
      params:hide("fx_rele_time")
    else
      params:hide("fx_rele_rate")
      params:show("fx_rele_time")
    end
    params:set("fx_rele_rate", params:get("fx_rele_rate_l"), true)
    params:set("fx_rele_time", params:get("fx_rele_time_l"), true)
  else
    params:hide("fx_rele_time")
    params:hide("fx_rele_rate")
    if del.sync then
      params:show("fx_rele_rate_l")
      params:show("fx_rele_rate_r")
      params:hide("fx_rele_time_l")
      params:hide("fx_rele_time_r")
    else
      params:hide("fx_rele_rate_l")
      params:hide("fx_rele_rate_r")
      params:show("fx_rele_time_l")
      params:show("fx_rele_time_r")
    end
  end
  _menu.rebuild_params()
end

local function set_rates()
  if del.sync then
    local beat_sec = clock.get_beat_sec()
    params:set("fx_rele_time_l", del.rate_l * beat_sec * 4)
    params:set("fx_rele_time_r", del.rate_r * beat_sec * 4)
  end
end

local function set_fx_param(key, val)
  osc.send({ "localhost", 57120 }, "/fx_rele/set", {key, val})
end

local function round_form(param, quant, form)
  return(util.round(param, quant)..form)
end

function FxRele:add_params()
  params:add_group("fx_rele", "fx rEle", 15)
  FxRele:add_slot("fx_rele_slot", "slot")

  params:add_control("fx_rele_level", "level", controlspec.new(0, 1, "lin", 0, 1), function(param) return round_form(param:get() * 100, 1, "%") end)
  params:set_action("fx_rele_level", function(x) set_fx_param("amp", x) end)

  params:add_option("fx_rele_type", "type", {"stereo", "dual mono", "ping pong"}, 1)
  params:set_action("fx_rele_type", function(x) del.mode = x set_fx_param("mode", x - 1) update_delay_params() end)

  params:add_option("fx_rele_mode", "mode", {"free", "clocked"}, 2)
  params:set_action("fx_rele_mode", function(x) del.sync = x == 2 and true or false set_rates() update_delay_params() end)

  params:add_control("fx_rele_time_l", "time L", controlspec.new(0.1, 4, "lin", 0, 1.2), function(param) return round_form(param:get(), 0.01, "s") end)
  params:set_action("fx_rele_time_l", function(x) set_fx_param("timeL", x) end)

  params:add_control("fx_rele_time_r", "time R", controlspec.new(0.1, 4, "lin", 0, 6), function(param) return round_form(param:get(), 0.01, "s") end)
  params:set_action("fx_rele_time_r", function(x) set_fx_param("timeR", x) end)

  params:add_option("fx_rele_rate_l", "rate L", del.rate_names, 6)
  params:set_action("fx_rele_rate_l", function(x) del.rate_l = del.rate_values[x] set_rates() end)

  params:add_option("fx_rele_rate_r", "rate R", del.rate_names, 4)
  params:set_action("fx_rele_rate_r", function(x) del.rate_r = del.rate_values[x] set_rates() end)

  params:add_control("fx_rele_time", "time", controlspec.new(0.1, 4, "lin", 0, 0), function(param) return round_form(param:get(), 0.01, "s") end)
  params:set_action("fx_rele_time", function(x) params:set("fx_rele_time_l", x) end)

  params:add_option("fx_rele_rate", "rate", del.rate_names, 6)
  params:set_action("fx_rele_rate", function(x) params:set("fx_rele_rate_l", x) end)

  params:add_control("fx_rele_feedback", "feedback", controlspec.new(0, 1, "lin", 0, 0.6), function(param) return round_form(param:get() * 100, 1, "%") end)
  params:set_action("fx_rele_feedback", function(x) set_fx_param("fb", x) end)

  params:add_control("fx_rele_lpf_cutoff", "lowpass", controlspec.new(20, 18000, "exp", 0, 1600), function(param) return round_form(param:get(), 1, " hz") end)
  params:set_action("fx_rele_lpf_cutoff", function(x) set_fx_param("hzLpf", x) end)

  params:add_control("fx_rele_hpf_cutoff", "highpass", controlspec.new(20, 18000, "exp", 0, 80), function(param) return round_form(param:get(), 1, " hz") end)
  params:set_action("fx_rele_hpf_cutoff", function(x) set_fx_param("hzHpf", x) end)

  params:add_control("fx_rele_modulation", "mod depth", controlspec.new(0, 1, "lin", 0, 0), function(param) return round_form(param:get() * 100, 1, "%") end)
  params:set_action("fx_rele_modulation", function(x) set_fx_param("mod", x) end)

  bang_params()
end  

md.hook.register("script_post_init", "fx rEle post init", function() FxRele:add_params() end)
