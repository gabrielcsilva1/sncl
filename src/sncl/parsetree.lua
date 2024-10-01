local lpeg = require('lpeg')

local utils = require('sncl.utils')
local gbl = require('sncl.globals')
local resolve = require('sncl.resolve')

-- TODO: Make it conform with the other modules
local parsingTable = {
  --- Generate a better formated table for the Port element
  -- Receives what the lpeg returns when it parses the port,
  -- then creates a better formated table
  -- then inserts it in the symbol table
  -- @param str The return of lpeg
  -- @param sT The symbol table
  -- @return The generated table
  makePort = function(str, symbolsTable, isMacroSon)
    return str / function(id, comp, iface)
      local element = {
        _type = 'port',
        id = id,
        component = comp,
        interface = iface,
        line = gbl.parser_line
      }
      if utils:isIdUsed(element.id, symbolsTable) then
        return nil
      end

      if not isMacroSon then
        symbolsTable.presentation[id] = element
      end
      return element
    end
  end,

  --- Generate a better formated table for the Property element
  -- @param str The return of lpeg
  -- @return The generated table
  makeProperty = function(str)
    return str / function(name, value)
      return {
        _type = 'property',
        [name] = value,
        line = gbl.parser_line
      }
    end
  end,

  makeRelationship = function(str)
    return str / function(rl, cp, iface)
      local element = {
        role = rl,
        component = cp,
        interface = iface,
        line = gbl.parser_line
      }
      return element
    end
  end,

  --- Join the conditions and actions that are linked by "and"
  -- @param str The return of lpeg
  -- @param _type The type of the bind, can be an action or a condition
  -- @return The generated table
  makeBind = function(str, _type)
    return str / function(...)
      local tbl = {...}
      local element = {
        _type = _type,
        properties = nil,
        line = gbl.parser_line,
        hasEnd = false
      }

      for _, val in pairs(tbl) do
        if type(val) == 'table' then
          if val._type == 'property' then
            val._type = nil
            val.line = nil
            for name, value in pairs(val) do
              local nameWithRolePrefix = element.role..name:gsub("^%l", string.upper)
              utils:addProperty(element, nameWithRolePrefix, value)
            end
          else
            element.role = val.role
            element.component = val.component
            if val.interface then
              if element._type == 'condition' and lpeg.match(utils.checks.buttons, val.interface) then
                utils:addProperty(element, '__keyValue', val.interface)
              else
                element.interface = val.interface
              end
            end
          end
        elseif val == 'end' then
          element.hasEnd = true
        end
      end

      return element
    end
  end,

  --- Generate a better formated table for the Link element
  -- @param str
  -- @param sT
  -- @return
  makeLink = function(str, sT, isMacroSon)
    return str / function(...)
      local tbl = {...}
      local element = {
        _type = 'link',
        conditions = {},
        actions = {},
        properties = {},
        line = gbl.parser_line,
        hasEnd = false
      }
      for _, val in pairs(tbl) do
        if type(val) == 'table' then
          if val._type == 'action' then
            table.insert(element.actions, val)
            val.father = element
          elseif val._type == 'condition' then
            val.father = element
            table.insert(element.conditions, val)
          else
            for name, value in pairs(val) do
              utils:addProperty(element, name, value)
            end
          end
        elseif val == 'end' then
          element.hasEnd = true
        end
      end

      if not isMacroSon then
        table.insert(sT.presentation, element)
      end
      element.xconnector = resolve:makeConnector(element, sT)
      return element
    end
  end,

  -- TODO: Propriedades de uma macro devem ser propriedades
  -- do elemento em q a macro foi chamada

  --- Generates a better formated table for the Macro element
  -- @param str
  -- @param sT
  -- @return
  makeMacro = function(str, sT)
    return str / function(id, ...)
      local tbl = {...}
      local element = {
        _type = 'macro',
        id = id,
        properties = {},
        children = {},
        parameters = {},
        hasEnd = false,
        line = gbl.parser_line
      }

      if utils:isIdUsed(element.id, sT) then
        return nil
      end

      sT.macro[element.id] = element

      for _, val in pairs(tbl) do
        if type(val) == 'table' then
          if val.parameters then -- If val is the parameter table
            element.parameters = val.parameters
          else -- If val is the children
            table.insert(element.children, val)
            val.father = element
          end
        elseif val == 'end' then
          element.hasEnd = true
        end
      end

      return element
    end
  end,

  --- Generate a better formated table for the Macro Call element
  -- @param str
  -- @param sT
  -- @return
  makeMacroCall = function(str, sT)
    return str / function(mc, args)
      local element = {
        _type = 'macro-call',
        macro = mc,
        arguments = args,
        line = gbl.parser_line
      }
      table.insert(sT.macroCall, element)
      return element
    end
  end,

  --- Generate a better formated table for the Template element
  -- @param str
  -- @param sT
  -- @return
  makeTemplate = function(str, sT)
    return str / function(iterator, start, class, ...)
      local tbl = {...}
      local element = {
        _type = 'for',
        iterator = iterator,
        start = start,
        class = class,
        children = {},
        line = gbl.parser_line-1
      }

      for _, val in pairs(tbl) do
        if val._type == 'macro-call' then
          val.father = element
          table.insert(element.children, val)
        end
      end

      table.insert(sT.template, element)
      return element
    end
  end
}

function parsingTable:makePresentationElement(str, symbolsTable, isMacroSon)
  return str / function(_type, id, ...)
    local elementBody = {...}
    local element = {
      _type = _type,
      id = id,
      properties = {},
      children = {},
      hasEnd = false,
      line = gbl.parser_line
    }

    -- TODO: this shouldn't be on utils
    if utils:isIdUsed(element.id, symbolsTable) then
      return error(string.format("Id %s already declared", element.id))
    end

    if element._type == 'region' and not isMacroSon then
      symbolsTable.head[element.id] = element
    elseif not isMacroSon then
      symbolsTable.presentation[element.id] = element
    end
    
    for _, val in pairs(elementBody) do
      if type(val) == 'table' then
        if val._type == 'property' then
          for propertyName, propertyValue in pairs(val) do
            if isMacroSon then
              element.properties[propertyName] = propertyValue
            else
              if propertyName == 'rg' then
                if element.region then
                   utils.printError(string.format('Region %s already declared', element.region), element.line)
                   return nil
                end
                element.region = propertyValue
                
                element.descriptor = resolve:makeDescriptor(propertyValue, symbolsTable)
              else
                utils:addProperty(element, propertyName, propertyValue)
              end
            end
          end
        else
          table.insert(element.children, val)
          val.father = element
        end
      elseif val == 'end' then
        element.hasEnd = true
      end
    end

    return element
  end
end

return parsingTable

