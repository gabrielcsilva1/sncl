local ins = require"inspect"
local utils = require"utils"

function genLink(ele, indent)
   local NCL = indent.."<link xconnector= >"

   for _, act in pairs(ele.actions) do
      NCL = NCL..indent.."   <bind role="..act.role.." component="..act.component
      if act.interface then
         NCL = NCL.." interface="..act.interface
      end
      NCL = NCL.." >"
      if act.properties then
         for name, value in pairs(act.properties) do
            NCL = NCL..indent.."      <bindParam name="..name.." value="..value.."/>"
         end
      end
      NCL = NCL..indent.."   </bind>"
   end

   for _, cond in pairs(ele.conditions) do
      NCL = NCL..indent.."   <bind role="..cond.role.." component="..cond.component
      if cond.interface then
         NCL = NCL.." interface="..cond.interface
      end
      NCL = NCL.." >"
      NCL = NCL..indent.."   </bind>"
   end

   local NCL = NCL..indent.."</link>"
   return NCL
end

function genPresentation(ele, indent)
   local NCL = indent.."<"..ele._type.." id="..ele.id..">"
   if ele.properties then
      for name, value in pairs(ele.properties) do
         NCL = NCL..indent.."   <property name="..name.." value="..value.."/>"
      end
   end
   if ele.sons then
      for _, son in pairs(ele.sons) do
         if son._type == "link" then
            NCL = NCL..genLink(son, indent.."   ")
         else
            NCL = NCL..genPresentation(son, indent.."   ")
         end
      end
   end
   NCL = NCL..indent.."</"..ele._type..">"
   return NCL
end

function genNCL()
   local NCL = ""
   local indent = "\n"
   for _, ele in pairs(gblPresTbl) do
      if ele._type and not ele.father then
         NCL = NCL..genPresentation(ele, indent)
      end
   end

   for _, ele in pairs(gblLinkTbl) do
      if not ele.father then
         NCL = NCL..genLink(ele, indent)
      end
   end

   return NCL
end

function containValue(tbl, arg)
   for _, val in pairs(tbl) do
      if val == arg then
         return true
      end
   end
   return false
end

function getIndex(tbl, arg)
   for pos, val in pairs(tbl) do
      if val == arg then
         return pos
      end
   end
   return nil
end

function genMacroSon(element, macro, arguments)
   local newEle = {properties = {}, sons={}}
   -- If the Id is a parameter, a new element have to be created
   if containValue(macro.parameters, element.id) then
      newEle.id = arguments[getIndex(macro.parameters, element.id)]
   else
      newEle.id = element.id
   end

   if gblPresTbl[newEle.id] then
      utils.printErro("Id "..newEle.id.." already declared")
      return nil
   end
   gblPresTbl[newEle.id] = newEle
   if element.properties then
      for name, value in pairs(element.properties) do
         -- If a property is a parameter, create the property
         -- with the new value
         if containValue(macro.parameters, name) then
            newEle.properties[name] = arguments[getIndex(macro.parameters, name)]
         end
      end
   end
   if element.sons then
      for _, son in pairs(element.sons) do
         local newSon = genMacroSon(son, macro, arguments)
         newSon.father = newEle
         table.insert(newEle.sons, newSon)
      end
   end
   newEle._type = element._type
   return newEle
end

function resolveMacro(macro, arguments)
   for _, son in pairs(macro.sons) do
      genMacroSon(son, macro, arguments)
   end
end

function resolveMacroCalls(tbl)
   for _, call in pairs(tbl) do
      local macro = gblMacroTbl[call.macro]
      if not macro then
         utils.printErro("Macro "..call.macro.." not declared")
         return nil
      end
      if #macro.parameters ~= #call.arguments then
         utils.printErro("Wrong number of arguments on call "..macro.id)
         return nil
      end
      resolveMacro(macro, call.arguments)
   end
end


