-- Loaded only into the isolated test copy by tests/run.py.
local transfer = require("scripts.transfer")
local ran = false

local function equal(actual, expected, message)
  assert(actual == expected, message .. ": expected " .. tostring(expected)
    .. ", got " .. tostring(actual))
end

local function run()
  if ran then return end
  ran = true
  local source = game.create_inventory(8)
  local surface = game.create_surface("clear-trash-tests", {
    width = 64, height = 64, water = 0, autoplace_controls = {}
  })
  surface.request_to_generate_chunks({0, 0}, 1)
  surface.force_generate_chunk_requests()
  local tiles = {}
  for x = -16, 16 do
    for y = -16, 16 do
      tiles[#tiles + 1] = {name = "grass-1", position = {x, y}}
    end
  end
  surface.set_tiles(tiles)
  local chest = surface.create_entity{name = "steel-chest", position = {2, 0}, force = "player"}
  local destination = chest.get_inventory(defines.inventory.chest)

  source.insert{name = "iron-plate", count = 150}
  source.insert{name = "copper-plate", count = 20}
  local moved, remaining = transfer.move(source, destination)
  equal(moved, 170, "all items moved")
  equal(remaining, 0, "trash emptied")
  equal(destination.get_item_count("iron-plate"), 150, "iron received")
  equal(destination.get_item_count("copper-plate"), 20, "copper received")

  destination.clear()
  destination.set_bar(2)
  destination[1].set_stack{name = "iron-plate", count = 90}
  source.insert{name = "iron-plate", count = 30}
  source.insert{name = "copper-plate", count = 20}
  moved, remaining = transfer.move(source, destination)
  equal(moved, 10, "partial stack filled")
  equal(remaining, 40, "overflow kept")
  equal(destination.get_item_count(), 100, "bar respected")
  equal(destination[2].valid_for_read, false, "barred slot untouched")
  moved, remaining = transfer.move(source, destination)
  equal(moved, 0, "full chest unchanged")
  equal(remaining, 40, "full chest loses nothing")
  destination.set_bar(1)
  equal(transfer.move(source, destination), 0, "fully barred chest")

  source.clear()
  destination.clear()
  destination.set_bar()
  source[1].set_stack{name = "blueprint", count = 1}
  source[1].set_blueprint_entities{{entity_number = 1, name = "wooden-chest", position = {0, 0}}}
  source[1].label = "Keep blueprint data"
  local blueprint = source[1].export_stack()
  source[2].set_stack{name = "firearm-magazine", count = 2}
  source[2].ammo = 3
  source[3].set_stack{name = "repair-pack", count = 1}
  source[3].durability = 75
  source[4].set_stack{name = "power-armor", count = 1}
  source[4].grid.put{name = "battery-equipment", position = {0, 0}}
  equal(transfer.move(source, destination), 5, "special items moved")
  equal(destination.find_item_stack("blueprint").export_stack(), blueprint, "blueprint data preserved")
  equal(destination.find_item_stack("firearm-magazine").ammo, 3, "ammo preserved")
  equal(destination.find_item_stack("repair-pack").durability, 75, "durability preserved")
  equal(#destination.find_item_stack("power-armor").grid.equipment, 1, "equipment preserved")

  for y = 2, 14, 2 do
    surface.create_entity{name = "straight-rail", position = {8, y}, direction = defines.direction.north, force = "player"}
  end
  local wagon = surface.create_entity{name = "cargo-wagon", position = {8, 8}, force = "player"}
  local filtered = wagon.get_inventory(defines.inventory.cargo_wagon)
  filtered.set_bar(2)
  filtered.set_filter(1, "copper-plate")
  source.insert{name = "iron-plate", count = 10}
  source.insert{name = "copper-plate", count = 20}
  moved, remaining = transfer.move(source, filtered)
  equal(moved, 20, "matching filter accepted")
  equal(remaining, 10, "mismatching filter rejected")
  source.clear()
  equal(transfer.move(source, destination), 0, "empty trash")
  log("[Clear_Trash tests] PASS: transfers, overflow, full chest, bars, filters, item metadata")

  local player = game.players[1]
  if player then
    player.set_controller{type = defines.controllers.god}
    player.teleport({0, 0}, surface)
    local character = surface.create_entity{name = "character", position = {0, 0}, force = player.force}
    player.set_controller{type = defines.controllers.character, character = character}
    player.character_trash_slot_count_bonus = 10
    local trash = character.get_inventory(defines.inventory.character_trash)
    local main = character.get_inventory(defines.inventory.character_main)
    main.insert{name = "iron-plate", count = 17}
    local main_count = main.get_item_count()
    local opened = script.get_event_handler(defines.events.on_gui_opened)
    local click = script.get_event_handler(defines.events.on_gui_click)
    local closed = script.get_event_handler(defines.events.on_gui_closed)
    local function open(entity)
      player.opened = entity
      opened{player_index = player.index, gui_type = defines.gui_type.entity, entity = entity}
      local frame = player.gui.relative.clear_trash_chest_frame
      assert(frame and frame.valid, "chest button created")
      return frame.clear_trash_move_to_chest
    end

    destination.clear()
    trash.insert{name = "copper-plate", count = 23}
    local button = open(chest)
    equal(button.parent.anchor.gui, defines.relative_gui_type.container_gui, "ordinary chest anchor")
    click{player_index = player.index, element = button}
    equal(trash.get_item_count(), 0, "button empties character trash")
    equal(destination.get_item_count("copper-plate"), 23, "button fills opened chest")
    equal(main.get_item_count(), main_count, "main inventory untouched")
    click{player_index = player.index, element = button}
    player.opened = nil
    closed{player_index = player.index, gui_type = defines.gui_type.entity, entity = chest}
    equal(player.gui.relative.clear_trash_chest_frame, nil, "button removed on close")

    for _, name in ipairs({"logistic-chest-passive-provider", "logistic-chest-requester", "infinity-chest", "linked-chest"}) do
      local entity = surface.create_entity{name = name, position = {3, 2}, force = player.force}
      trash.insert{name = "copper-plate", count = 5}
      button = open(entity)
      local anchor = entity.type == "linked-container"
        and defines.relative_gui_type.linked_container_gui or defines.relative_gui_type.container_gui
      equal(button.parent.anchor.gui, anchor, name .. " anchor")
      click{player_index = player.index, element = button}
      equal(trash.get_item_count(), 0, name .. " trash emptied")
      equal(entity.get_inventory(defines.inventory.chest).get_item_count("copper-plate"), 5, name .. " received trash")
      player.opened = nil
      closed{player_index = player.index}
      entity.destroy()
    end

    trash.insert{name = "copper-plate", count = 9}
    button = open(chest)
    player.teleport({15, 15})
    click{player_index = player.index, element = button}
    equal(trash.get_item_count(), 9, "out-of-reach click rejected")
    player.opened = wagon
    opened{player_index = player.index}
    equal(player.gui.relative.clear_trash_chest_frame, nil, "non-chest has no button")
    log("[Clear_Trash tests] PASS: real player GUI handlers, all chest types, character trash only, distance, close")
  end
  source.destroy()
  log("[Clear_Trash tests] COMPLETE")
end

script.on_init(run)
script.on_nth_tick(1, run)
