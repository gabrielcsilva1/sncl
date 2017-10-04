Connector = {}
Connector_mt = {}

Connector_mt.__index = Connector

function Connector.new(id)
   local connectorObject = {
      id = id,
      numConditions = 0,
      numActions = 0,
      pai = nil,
      linkParams = {},
      conditions = {},
      actions = {},
   }
   setmetatable(connectorObject, Connector_mt)
   return connectorObject
end

function Connector:setNumCondsAndActions (numConds, numActions)
   self.numConds = numConds
   self.numActions = numActions
end

function Connector:getId() return self.id end

function Connector:addConditions (conditions)
   self.conditions = conditions
end
function Connector:addActions (actions)
   self.actions = actions
end

function Connector:toNCL (indent)
   local connector = indent.."<causalConnector id=\""..self.id.."\">"

   --Conditions
   local newIndent = indent
   if self.numConds > 1 then
      newIndent = indent.."   "
   end
   local condString = ""
   for pos, val in pairs(self.conditions) do
      condString = condString..newIndent.."   <simpleCondition role=\""..pos.. "\" "
      if pos == "onSelection" and val.param == true then
         condString = condString.."key=\"$keyCode\""
         connector = connector..indent.."   <connectorParam name=\"keyCode\" />"
      end
      if val.times > 1 then
         condString = condString.." max=\"unbounded\" qualifier=\"or\""
      end
      condString = condString.."/>"
   end
   if self.numConds > 1 then
      condString = indent.."   <compoundCondition operator=\"and\">"..condString..indent.."   </compoundCondition>"
   end

   --Actions
   newIndent = indent
   if self.numActions > 1 then
      newIndent = indent.."   "
   end
   local actionString = ""
   for pos, val in pairs(self.actions) do
      actionString = actionString..newIndent.."   <simpleAction role=\""..pos.."\" "
      if val.times > 1 then
         actionString = actionString.." max=\"unbounded\" qualifier=\"par\""
      end
      for __, j in pairs(val.propriedades) do
         connector = connector..indent.."   <connectorParam name=\""..j.."\"/>"
         if j == "delay" then
            actionString = actionString.." delay=\"$delay\""
         else
            actionString = actionString.." value=\""..j.."\""
         end
      end
      actionString = actionString.."/>"
   end
   if self.numActions > 1 then
      actionString = indent.."   <compoundAction operator=\"seq\">"..actionString..indent.."   </compoundAction>"
   end

   connector = connector..condString..actionString
   connector = connector..indent.."</causalConnector>"

   return connector
end


