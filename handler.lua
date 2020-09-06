-- local http = require("socket.http")
-- local ltn12 = require("ltn12")

REGEX_GRUPO_DE_SINONIMOS = "<p class=\"sinonimos\">(.-)</p>"
REGEX_SINONIMO_HYPERLINK = "<a href=\".-\" class=\"sinonimo\">(.-)</a>"
REGEX_SINONIMO_SPAN      = "<span>(.-)</span>"

local function cmd(c)
   local fpath = os.tmpname()
   os.execute(c .. " > " .. fpath)
   local f = io.open(fpath)
   local output = f:read("*a")
   io.close(f)
   return output
end

--[[
local function get_http(u)
   local t = {}
   http.request{
      url = u,
      sink = ltn12.sink.table(t)
   }
   return table.concat(t)
end
--]]

---[[
local function get_http(u)
   return cmd("curl -s " .. u)
end
--]]

local function get_sinonimos(palavra, significado)
   local url = "https://www.sinonimos.com.br/" .. palavra .. "/"
   local pagina = get_http(url)
   
   local sinonimos = {}
   local index = 1
   for grupo in pagina:gmatch(REGEX_GRUPO_DE_SINONIMOS) do
      if index == significado then 
         for sinonimo in grupo:gmatch(REGEX_SINONIMO_HYPERLINK) do
            table.insert(sinonimos, sinonimo)
         end
         for sinonimo in grupo:gmatch(REGEX_SINONIMO_SPAN) do
            table.insert(sinonimos, sinonimo)
         end
      end
      index = index + 1
   end

   table.sort(sinonimos)
   return sinonimos
end

local valid_request = lighty.env["uri.path"]:match("^/scrapers/sinonimos/([^/]*)$")
local valid_query = lighty.env["uri.query"]:match("^significado=[0-9]*$")

if not (valid_request and valid_query) then
   return 400
end

local palavra = valid_request
local significado = tonumber(valid_query:match("[0-9]*$"))
local sinonimos = get_sinonimos(palavra, significado)

if sinonimos then
   lighty.header["Content-type"] = "text/plain"
   for _, sinonimo in ipairs(sinonimos) do
      table.insert(lighty.content, sinonimo .. "\n")
   end
   return 200
end

