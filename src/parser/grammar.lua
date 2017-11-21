local lpeg = require("lpeg")
local utils = require("utils")
local t = lpeg.locale()
local V, P, R, C = lpeg.V, lpeg.P, lpeg.R, lpeg.C

local SPC = V"Espacos"

gramaticaSncl = {
   "INICIAL";

   ------ Bases ------
   Espacos = t.space
   /function(str)
      if str == "\n" then
         linhaParser = linhaParser+1
      end
   end,
   Symbols = (P"@"+P"_"+P"/"+P"."+P"%"+P","+P"-"),
   AlphaNumericSymbols = (t.alnum+V"Symbols"+P"."),
   AlphaNumericSpace = (t.alnum+SPC)^1,
   AlphaNumericSymbolsSpace = (t.alnum+V"Symbols"+P" ")^1,
   ParamCharacters = (t.alnum+P"\""+P"%"+P"/"+P"."+P"-"),
   Id = (t.alnum+P"_"+P"-"),
   String = (P"\""*V"AlphaNumericSymbolsSpace"^-1*P"\""),

   End = (P"end" * SPC^0)
   /function()
      if currentElement == nil then
         utils.printErro("No element to end", linhaParser)
         return
      end
      if currentElement.tipo == "macro" then
         insideMacro = false
      end
      currentElement.temEnd = true
      if currentElement.pai == nil then
         currentElement = nil
      else
         currentElement = currentElement.pai
      end
   end,

   ------ REGION ------
   RegionId = (P"region" *P" "^1 *V"Id"^1 *SPC^0)
   /function(str)
      local newRegion = Elemento.novo("region", linhaParser)
      utils.newElement(str, newRegion)
   end,
   Region = (V"RegionId" *(V"Comentario"+V"Region"+V"Property"+V"MacroRefer")^0
   * V"End"^-1),

   ------ SWITCH ------

   ------ CONTEXT ------
   ContextId = (V"Port"^-1 * P"context"*P" "^1*V"Id"^1*SPC^0)
   /function(str)
      local newContext = Elemento.novo("context", linhaParser)
      utils.newElement(str, newContext)
   end,

   Context = (V"ContextId"
   *(V"Comentario"+V"MacroRefer"+V"Property"+ V"Media"+V"Context"+V"Link"+V"Refer")^0
   * V"End"^-1),

   ------ MEDIA ------
   MediaId = (V"Port"^-1* P"media" *P" "^1* V"Id"^1 *SPC^0)
   /function(str)
      local newMedia = Elemento.novo("media", linhaParser)
      utils.newElement(str, newMedia)
   end,
   Media = (V"MediaId" *(V"Comentario"+V"MacroRefer"+V"Area"+V"Refer"+V"Property")^0
   * V"End"^-1),

   ------ AREA ------
   AreaId = (V"Port"^-1*P"area" *P" "^1* V"Id"^1 *SPC^0)
   /function(str)
      local newArea = Elemento.novo("area", linhaParser)
      utils.newElement(str, newArea)
   end,
   Area = (V"AreaId" *(V"Comentario"+V"Property")^0* V"End"^-1),

   ------ MACRO ------
   MacroParams2 = (V"ParamCharacters"^1*P" "^0* (P","*P" "^0*V"ParamCharacters"^1*P" "^0)^0), --Parametros recebidos
   MacroRefer = (P"*" * V"AlphaNumericSymbols"^1 *P" "^0*P"("*P" "^0*V"MacroParams2"^-1*P" "^0*P")" *SPC^0)
   /function(str)
      parseMacroChamada(str)
   end,
   MacroParams = (t.alnum^1*P" "^0* (P","*P" "^0*V"ParamCharacters"^1*P" "^0)^0), -- Parametros passados
   MacroId = (P"macro" *P" "^1* V"Id"^1 *P" "^0*P"("*P" "^0*V"MacroParams"^-1*P" "^0*P")" *SPC^0)
   /function(str)
      local id, params, quant = parseIdMacro(str)
      if id == nil then
         utils.printErro("Invalid Id", linhaParser)
         return
      end
      if tabelaSimbolos[id] == nil then
         local newMacro = Macro.new(id)
         newMacro:setParams(params)
         newMacro.quantParams = quant
         tabelaSimbolos[id] = newMacro
         tabelaSimbolos.macros[id] = tabelaSimbolos[id]
         if currentElement ~= nil then
            utils.printErro("Macro can not be declared inside of another element", linhaParser)
            return
         else
            currentElement = newMacro
         end
      else
         utils.printErro("Id "..id.." already declared", linhaParser)
         return
      end
      insideMacro = true
   end,
   Macro = (V"MacroId" *(V"Comentario"+V"MacroRefer"+V"Property"+V"Media"+V"Area"+V"Context"+V"Link"+V"Region")^0* V"End"^-1),

   ------ LINK ------
   Link = (V"Condition" *SPC^0* (V"Comentario"+V"Property"+V"Action")^0 *V"End"^-1),

   ------ CONDITION ------
   Condition = (V"ConditionParse")
   /function(str)
      parseLinkCondition(str)
   end,
   ConditionParse = (V"AlphaNumericSymbols"^1 *P" "^1* V"AlphaNumericSymbols"^1* P" "^0 *V"CondTerm"*P" "^0),
   CondTerm = ((P"and" *P" "^1* V"ConditionParse") + (P"do")),

   ------ ACTION ------
   ActionMedia = (t.alnum^1 *P" "^1* V"AlphaNumericSymbols"^1 *SPC^1)
   /function(str)
      parseLinkAction(str)
   end,
   ActionParam = (t.alnum^1 *P" "^0* P":" *P" "^0* V"String"* SPC^0)
   /function(str)
      parseLinkActionParam(str)
   end,
   Action = ( V"ActionMedia"*(V"Comentario"+V"Property")^0 *V"End"^-1),
   ------ MISC ------
   Port = (P"port" *P" "^1),
   Property= (V"AlphaNumericSymbols"^1 *P" "^0* P":" *P" "^0* (V"String"+(t.alnum+V"Symbols"+P" "+P":")^1) *SPC^0)
   /function(str)
      str = str:gsub("%s+", "")
      if currentElement ~= nil then
         --print(currentElement.tipo)
         currentElement:parsePropriedade(str)
      else
         utils.printErro("Property"..str.." declared in invalid context", linhaParser)
      end
   end,
   Refer = (P"refer" *P" "^0* P":" *P" "^0* t.alnum^1 *SPC^0)
   /function(str)
      str = str:gsub("%s+", "")
      parseRefer(str)
   end,
   Comentario = (P"--"*P" "^0* (t.alnum+t.punct+t.xdigit+P"¨"+P"´"+P" ")^0 *SPC^0),

   -- START --
   INICIAL = SPC^0 * (V"Comentario"+V"Macro"+V"MacroRefer"+V"Region"+V"Media"+V"Context"+V"Link")^0,
}

keywordTable = {
   action = (P"start"+P"stop"+P"abort"+P"pause"+P"resume"+P"set"),

   condition = (P"onBegin"+P"onEnd"+P"onAbort"+P"onPause"+P"onResume"+P"onSelection"+
   P"onBeginSelection"+P"onEndSelection"+P"onAbortSelection"+P"onPauseSelection"+
   P"onResumeSelection"+P"onBeginAttribution"+P"onEndAttribution"+P"onPauseAttribution"+
   P"onResumeAttribution"+P"onAbortAttribution"),

   properties = (P"background"+P"balanceLevel"+P"bassLevel"+P"bottom"+P"bounds"+
   P"explicitDur"+P"fit"+P"focusIndex"+P"fontColor"+P"fontFamily"+P"fontSize"+
   P"fontStyle"+P"fontVariant"+P"fontWeight"+P"height"+P"left"+P"location"+
   P"plan"+P"playerLife"+P"reusePlayer"+P"rgbChromakey"+P"right"+P"scroll"+
   P"size"+P"soundLevel"+P"style"+P"top"+P"transparency"+P"trebleLevel"+
   P"visible"+P"width"+P"zIndex"),

   areaProperties = (P"coords"+P"begin"+P"end"+P"beginText"+P"endText"+P"beginPosition"+P"endPosition"+P"first"+P"last"+P"label"+P"clip"),
}

-- TODO: Add check for Id

dataType = {
   -- TODO:Add Second's
   time = ( ((R"01"*R"09")+(P"2"*R"03"))*P":"*(R"05"*R"09")*P":"*(R"05"*R"09")*(P"."*R"09"^1)^-1*(P"."*R"09"^1)^-1 ),
   percent = ((P"100"*(P"."*P"0"^1)^-1*P"%") + (R"09"*R"09"^-1*(P"."*R"09"^1)^-1*P"%")),
   seconds = (R"09"*R"09"*P"s"),
   pixel = ((R"09"^1*P"px"^-1) ),
   integer = (t.digit^1),
   color = (P"\""*(P"white"+P"black"+P"silver"+P"gray"+P"red"+P"maroon"+P"fuchsia"+
      P"purple"+P"lime"+P"green"+P"yellow"+P"olive"+P"blue"+P"navy"+P"aqua"+
      P"transparent")*P"\""),
   -- TODO: Fix Id
   id = (t.alnum+P"_"+P"-")^1,
   string = (P"\"" *(t.alnum+P"@"+P"_"+P"/"+P"."+P"%"+P","+P"-"+P" ")^1* P"\""),
   mime = (P"\""*t.alpha^1*P"/"*t.alpha^1*P"\""),
   rgb = (""),-- #XXXXXX
}

propertiesValues = {
   --[[ 
   ["style"]       = nil,
   ["playerLife"]  = nil,
   ["deviceClass"] = nil,
   ["fit"] = nil,
   ["scroll"] = nil,
   ["focusSrc"] = nil,
   ["focusSelSrc"] = nil,
   ["plan"] = nil,
   ]]
   ["src"]                     = {1, dataType.string},
   ["type"]                    = {1, dataType.mime},
   ["rg"]                      = {1, dataType.id},
   ["player"]                  = {1, dataType.string},
   ["reusePlayer"]             = {1, dataType.boolean},
   ["explicitDur"]             = {1, dataType.time+dataType.seconds},
   ["focusIndex"]              = {1, dataType.integer},
   ["moveLeft"]                = {1, dataType.integer},
   ["moveRight"]               = {1, dataType.integer},
   ["moveUp"]                  = {1, dataType.integer},
   ["moveDown"]                = {1, dataType.integer},
   ["top"]                     = {1, dataType.percent + dataType.pixel},
   ["bottom"]                  = {1, dataType.percent + dataType.pixel},
   ["left"]                    = {1, dataType.percent + dataType.pixel},
   ["right"]                   = {1, dataType.percent + dataType.pixel},
   ["width"]                   = {1, dataType.percent + dataType.pixel},
   ["height"]                  = {1, dataType.percent + dataType.pixel},
   ["location"]                = {2, dataType.percent + dataType.pixel},
   ["size"]                    = {2, dataType.percent + dataType.pixel},
   ["bounds"]                  = {4, dataType.percent + dataType.pixel},
   ["background"]              = {1, dataType.color},
   ["rgbChromaKey"]            = {1, dataType.color + dataType.rgb},
   ["visible"]                 = {1, dataType.boolean},
   ["transparency"]            = {1, dataType.percent},
   ["zIndex"]                  = {1, dataType.integer},
   ["focusBorderColor"]        = {1, dataType.color},
   ["selBorderColor"]          = {1, dataType.color},
   ["focusBorderWidth"]        = {1, dataType.integer},
   ["focusBorderTransparency"] = {1, dataType.percent},
   ["freeze"]                  = {1, dataType.boolean1},
   ["coords"]                  = {4, dataType.percent+dataType.pixel},
   ["begin"]                   = {1, dataType.time+dataType.seconds},
   ["end"]                     = {1, dataType.time+dataType.seconds},
   ["beginText"]               = {1, dataType.string},
   ["endText"]                 = {1, dataType.string},
   ["beginPosition"]           = {1, dataType.integer},
   ["endPosition"]             = {1, dataType.integer},
   --["first"] = 
   --["last"] = 
   ["label"]                   = {1, dataType.string},
   ["clip"]                    = {1, dataType.string},
}
