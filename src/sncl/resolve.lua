
local resolve = { }

function resolve:makeDescriptor(regionName, symbolsTable)
  local newDescriptor = {
    _type = "descriptor",
    region = regionName,
    id = '__desc__'..regionName
  }
  symbolsTable.head[newDescriptor.id] = newDescriptor
  return newDescriptor.id
end

function resolve:makeConnectorBind(xconn, bind)
  if xconn[bind._type][bind.role] then
    xconn[bind._type][bind.role] = xconn[bind._type][bind.role]+1
  else
    xconn[bind._type][bind.role] = 1
  end
  if xconn.id:find(bind.role:gsub('^%l', string.upper)) then
    xconn.id = xconn.id..'N'
  else
    xconn.id = xconn.id..bind.role:gsub('^%l', string.upper)
  end
  
  if bind.role == 'onSelection' then
    xconn.properties.__keyValue = '__keyValue'
  elseif bind.properties then
    for name, _ in pairs(bind.properties) do
      local nameWithoutRolePrefix = name:match("%u.*"):lower()
      xconn.properties[name] = nameWithoutRolePrefix
    end
  end
end

function resolve:makeConnector(link, symbolsTable)
  local newConn = {
    _type = 'xconnector',
    id = '',
    condition = {},
    action = {},
    properties = {}
  }

  for _, cond in pairs(link.conditions) do
    self:makeConnectorBind(newConn, cond)
  end
  for _, act in pairs(link.actions) do
    self:makeConnectorBind(newConn, act)
  end
  if link.properties then
    for name, _ in pairs(link.properties) do
      local nameWithoutRolePrefix = name:match("_(.+)")
      if nameWithoutRolePrefix ~= nil then
       newConn.properties[name] = nameWithoutRolePrefix
      end
    end
  end

  for name, _ in pairs(newConn.properties) do
    if name ~= '__keyValue' then
      newConn.id = newConn.id..'_'..name
    end
 end

  -- TODO: Has to do all above to check if another equal
  -- connect is already created, wasting time. How to fix?

  if not symbolsTable.head[newConn.id] then
    symbolsTable.head[newConn.id] = newConn
  end

  return newConn.id
end

return resolve
