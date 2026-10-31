local transfer = require("scripts.transfer")

local FRAME_NAME = "clear_trash_chest_frame"
local BUTTON_NAME = "clear_trash_move_to_chest"
local chest_types = {
  ["container"] = true,
  ["logistic-container"] = true,
  ["infinity-container"] = true,
  ["linked-container"] = true
}

local function get_open_chest(player)
  if player.opened_gui_type ~= defines.gui_type.entity then return end
  local entity = player.opened
  if entity and entity.valid and chest_types[entity.type] then
    return entity
  end
end

local function remove_button(player)
  local frame = player.gui.relative[FRAME_NAME]
  if frame then frame.destroy() end
end

local function update_button(player)
  remove_button(player)
  local chest = get_open_chest(player)
  if not chest then return end

  local frame = player.gui.relative.add{
    type = "frame",
    name = FRAME_NAME,
    direction = "vertical",
    anchor = {
      gui = chest.type == "linked-container"
        and defines.relative_gui_type.linked_container_gui
        or defines.relative_gui_type.container_gui,
      position = defines.relative_gui_position.bottom
    }
  }
  frame.add{
    type = "button",
    name = BUTTON_NAME,
    caption = {"clear-trash.button"},
    tooltip = {"clear-trash.tooltip"}
  }
end

script.on_event(defines.events.on_gui_opened, function(event)
  local player = game.get_player(event.player_index)
  if player then update_button(player) end
end)

script.on_event(defines.events.on_gui_closed, function(event)
  local player = game.get_player(event.player_index)
  if player then remove_button(player) end
end)

script.on_configuration_changed(function()
  for _, player in pairs(game.players) do
    update_button(player)
  end
end)

script.on_event(defines.events.on_gui_click, function(event)
  local element = event.element
  if not (element and element.valid and element.name == BUTTON_NAME) then return end

  local player = game.get_player(event.player_index)
  if not (player and player.character and player.character.valid) then return end
  local frame = player.gui.relative[FRAME_NAME]
  if not (frame and element.parent == frame) then return end

  local chest = get_open_chest(player)
  if not (chest and chest.operable and player.can_reach_entity(chest)) then return end
  local trash = player.character.get_inventory(defines.inventory.character_trash)
  local destination = chest.get_inventory(defines.inventory.chest)
  if not (trash and destination) then return end

  local moved, remaining = transfer.move(trash, destination)
  if remaining > 0 then
    player.print({"clear-trash.remaining", moved, remaining})
  elseif moved == 0 then
    player.print({"clear-trash.empty"})
  end
end)
