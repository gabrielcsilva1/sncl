local utils = require("sncl.utils")
--local ins = require("sncl.inspect")

local nclGeneration = {}

function nclGeneration:conditions(conditions, indent, properties)
   local result = ''
   for pos, val in pairs(conditions) do
      result = result..string.format('%s   <simpleCondition role="%s"', indent, pos)
      if val > 1 then
         result = result..(' max="unbounded" qualifier="and"')
      end
      if pos == 'onSelection' and utils.containsValue(properties, '__keyValue') then
         result = result..' key="$__keyValue"'
      end
      result = result..string.format('>%s   </simpleCondition>', indent)
   end
   return result
end

function nclGeneration:actions(actions, conProperties, indent)
   local result = ''
   local tagAttibutes = {}
   for attValue, attName in pairs(conProperties) do
      local role = attValue:match("([%l]+)%u")

      if not tagAttibutes[role] then
         tagAttibutes[role] = string.format(' %s="$%s"', attName, attValue)
      else
         tagAttibutes[role] = tagAttibutes[role]..string.format(' %s="$%s"', attName, attValue)
      end
   end

   for role, val in pairs(actions) do
      result = result..string.format('%s   <simpleAction role="%s"', indent, role)
      if val > 1 then
         result = result..' max="unbounded" qualifier="par"'
      end
      if tagAttibutes[role] then
         result = result..tagAttibutes[role]
      end
      result = result..string.format('>%s   </simpleAction>', indent)
   end
   return result
end

function nclGeneration:xconnector(xconnector, indent)
   local result = string.format('%s<causalConnector id="%s" >', indent, xconnector.id)

   local nConds = 0
   for _, _ in pairs(xconnector.condition) do
      nConds = nConds + 1
   end
   if nConds > 1 then
      result = result..string.format('%s   <compoundCondition operator="and" >', indent)
      result = result..self:conditions(xconnector.condition, indent, xconnector.properties)
      result = result..string.format('%s   </compoundCondition>', indent)
   else
      result = result..self:conditions(xconnector.condition, indent, xconnector.properties)
   end

   local nActs = 0
   for _, _ in pairs(xconnector.action) do
      nActs = nActs + 1
   end
   if nActs > 1 then
      result = result..string.format('%s   <compoundAction operator="par" >', indent)
      result = result..self:actions(xconnector.action, xconnector.properties, indent)
      result = result..string.format('%s   </compoundAction>', indent)
   else
      result = result..self:actions(xconnector.action, xconnector.properties, indent)
   end
   for value, _ in pairs(xconnector.properties) do
      result = result..string.format('%s   <connectorParam name="%s" />', indent, value)
   end
   result = result..string.format('%s</causalConnector>', indent)

   return result
end

function nclGeneration:region(region, indent)
   local result = string.format('%s <region id="%s"', indent, region.id)
   if region.properties then
      for name, value in pairs(region.properties) do
         result = result..string.format(' %s="%s"', name, value)
      end
   end
   result = result..'>'

   for _, son in pairs(region.children) do
      result = result..self:region(son, indent..'  ')
   end

   result = result..string.format('%s </region>', indent)
   return result
end

function nclGeneration:descriptor(descriptor, indent)
   local result = string.format('%s<descriptor id="%s" region="%s" />', indent, descriptor.id, descriptor.region)
   return result
end

function nclGeneration:head(symbolsTable, indent)
   local result = ""
   local has_conn, has_rg, has_desc = false, false, false

   local connector_base = '<connectorBase>'
   local region_base = '<regionBase>'
   local descriptor_base = '<descriptorBase>'

   for _, val in pairs(symbolsTable.head) do
      if val._type == "xconnector"then
         has_conn = true
         connector_base = connector_base..self:xconnector(val, indent.."   ")
      elseif val._type == "region" and not val.father then
         has_rg = true
         region_base = region_base..self:region(val, indent.."   ")
      elseif val._type == "descriptor" then
         has_desc = true
         descriptor_base = descriptor_base..self:descriptor(val, indent.."   ")
      end
   end
   if has_conn then
      result = string.format('%s%s%s%s</connectorBase>', indent, result, connector_base, indent)
   end
   if has_rg then
      result = string.format('%s%s%s%s</regionBase>', indent, result, region_base, indent)
   end
   if has_desc then
      result = string.format('%s%s%s%s</descriptorBase>', indent, result, descriptor_base, indent)
   end
   return result
end

function nclGeneration.bind(element, symbolsTable, indent)
   local result = ""
   local link = element.father

   local hasComp = false
   -- If the link is inside of a context
   if link.father then
      -- If the father of the link has a children that is the component of the Link
      for _, val in pairs(link.father.children) do
         if element.component == val.id then
            hasComp = true
         end
      end
      if not hasComp then
         utils.printError(string.format('Component %s not in scope', element.component), element.line)
         return result
      end
   else
      if symbolsTable.presentation[element.component].father then
         utils.printError(string.format('Component %s not in scope', element.component), element.line)
         return result
      end
   end

   if not symbolsTable.presentation[element.component] then
      utils.printError(string.format('No element %s declared', element.component))
      return ""
   end
   result = result..string.format('%s<bind role="%s" component="%s"', indent, element.role, element.component)
   if element.interface then
      result = result..string.format(' interface="%s"', element.interface)
   end
   result = result..'>'
   if element.properties then
      for name, value in pairs(element.properties) do
         result = result..string.format('%s   <bindParam name="%s" value="%s" />', indent, name, value)
      end
   end
   result = result..string.format('%s</bind>', indent)

   return result
end

function nclGeneration:link(element, symbolsTable, indent)
   local result = string.format('%s<link xconnector="%s" >', indent, element.xconnector)

   for _, act in pairs(element.actions) do
      result = result..self.bind(act, symbolsTable, indent..'   ')
   end
   for _, cond in pairs(element.conditions) do
      result = result..self.bind(cond, symbolsTable, indent..'   ')
   end
   if element.properties then
      for name, value in pairs(element.properties) do
         result = result..string.format('%s   <linkParam name="%s" value="%s" />', indent, name, value)
      end
   end
   result = result..string.format('%s</link>', indent)

   return result
end

function nclGeneration:area(element, indent)
   local result = string.format('%s<area id="%s"', indent, element.id)

   if element.properties then
      for name, value in pairs(element.properties) do
         result = result..string.format(' %s="%s"', name, value)
      end
   end

   result = result..' />'
   return result
end

function nclGeneration:presentation(element, symbolsTable, indent)
   if element._type == 'macro-call' or element._type == 'for' then
      return ''
   end
   if element._type == 'area' then
      return self:area(element, indent)
   end

   -- Check if the refered region is decladed
   if element.region then
      if not symbolsTable.head[element.region] then
         utils.printError(string.format('Region %s not declared', element.region))
         return ''
      end
   end

   local result = string.format('%s<%s id="%s"', indent, element._type, element.id)

   if element.component then
      result = result..string.format(' component="%s"', element.component)
   end
   if element.interface then
      result = result..string.format(' interface="%s"', element.interface)
   end
   if element.src then
      result = result..string.format(' src="%s"', element.src)
   end
   if element.descriptor then
      result = result..string.format(' descriptor="%s"', element.descriptor)
   end
   if element.type then
      result = result..string.format(' type="%s"', element.type)
   end
   result = result..'>'
   if element.properties then
      for name, value in pairs(element.properties) do
        -- TODO: Check if the property is valid
         result = result..string.format('%s   <property name="%s" value="%s" />', indent, name, value)
      end
   end
   -- TODO: Check if the son type is valid
   if element.children then
      for _, son in pairs(element.children) do
         if son._type == 'link' then
            result = result..self:link(son, symbolsTable, indent..'   ')
         else
            result = result..self:presentation(son, symbolsTable, indent..'   ')
         end
      end
   end
   result = result..string.format('%s</%s>', indent, element._type)

   return result
end

function nclGeneration:body(symbolsTable, indent)
   local result = ''

   for _, ele in pairs(symbolsTable.presentation) do
      if ele._type and not ele.father then
         if ele._type == 'link' then
            result = result..self:link(ele, symbolsTable, indent)
         else
            result = result..self:presentation(ele, symbolsTable, indent)
         end
      end
   end

   for _, ele in pairs(symbolsTable.link) do
      if not ele.father then
         result = result..self:link(ele, symbolsTable, indent)
      end
   end

   return result
end

function nclGeneration:generateNCL(symbolsymbolsTableable)
   local indent = '\n   '
   local result = [[<?xml version="1.0" encoding="ISO-8859-1"?>
<ncl id="main" xmlns="http://www.ncl.org.br/NCL3.0/EDTVProfile">]]
   result = result..indent..'<head>'
   result = result..self:head(symbolsymbolsTableable, indent..'   ')
   result = result..indent..'</head>'
   result = result..indent..'<body>'
   result = result..self:body(symbolsymbolsTableable, indent..'   ')
   result = result..indent..'</body>\n</ncl>'
   return result
end

return nclGeneration
