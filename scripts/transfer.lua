local transfer = {}

function transfer.move(source, destination)
  local last_slot = #destination
  if destination.supports_bar() then
    last_slot = math.min(last_slot, destination.get_bar() - 1)
  end
  local filtered = destination.supports_filters()
  local moved = 0

  for source_index = 1, #source do
    local stack = source[source_index]
    if stack.valid_for_read then
      local original_count = stack.count
      -- Fill matching stacks first, then empty slots. Native stack transfers
      -- preserve metadata (blueprints, equipment, tags, durability and ammo).
      for pass = 1, 2 do
        for destination_index = 1, last_slot do
          if not stack.valid_for_read then break end
          local target = destination[destination_index]
          local occupied = target.valid_for_read
          if (pass == 1 and occupied and target.name == stack.name)
            or (pass == 2 and not occupied) then
            local filter = filtered and destination.get_filter(destination_index)
            if not filter or filter == stack.name then
              target.transfer_stack(stack)
            end
          end
        end
        if not stack.valid_for_read then break end
      end
      moved = moved + original_count - (stack.valid_for_read and stack.count or 0)
    end
  end

  return moved, source.get_item_count()
end

return transfer
