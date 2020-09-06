local function insert_iterator(table, iterator)
   for e in iterator do
      table.insert(table, e)
   end
end

local function cmd(c)
   local fpath = os.tmpname()
   os.execute(c .. " > " .. fpath)
   local f = io.open(fpath)
   local output = f:read("*a")
   io.close(f)
   return output
end

local function get_http(u)
   return cmd("curl -s " .. u)
end

local path  = lighty.env["uri.path"]
local query = lighty.env["uri.query"]
lighty.header["Content-type"] = "text/plain"

local regex_grupo_de_sinonimos = "<p class=\"sinonimos\">(.-)</p>"
local regex_sinonimo_hyperlink = "<a href=\".-\" class=\"sinonimo\">(.-)</a>"
local regex_span = "<span>(.-)</span>"
local regex_sentido = "<div class=\"sentido\">(.-)</div>"

local function get_sentidos

local function get_sinonimos(palavra, significado)
   local url = "https://www.sinonimos.com.br/" .. palavra .. "/"
   local pagina = get_http(url)
   
   local sinonimos = {}
   local index = 1
   for grupo in pagina:gmatch(regex_grupo_de_sinonimos) do
      if significado and index ~= significado then
         goto skip
      end

      insert_iterator(sinonimos, grupo:gmatch(regex_sinonimo_hyperlink))
      insert_iterator(sinonimos, grupo:gmatch(regex_span))
      
      ::skip::
      index = index + 1
   end

   table.sort(sinonimos)
   return sinonimos
end

local request = path:match("^/scrapers/sinonimos/([^/]*)$")
if not request then return 400 end

local arg
if query then
   arg =
      query:match(".*(sentidos).*") or
      query:match("^.*(significado=[0-9]*).*$")
end

local resultado = {}

if arg == "sentidos" then
   resultado = get_significados(request) -- TODO
elseif arg:match("significado=*") then
   local index_significado = tonumber(arg:match("[0-9]*$"))
   resultado = get_sinonimos(request, index_significado)
else
   resultado = get_sinonimos(request)
end

if not resultado then return 400 end
for _, s in ipairs(resultado) do
   table.insert(lighty.content, resultado .. "\n")
end
return 200

