local source=game:HttpGet("https://raw.githubusercontent.com/copperpoppercms-sys/rift-hub-universe-football/main/main.lua?cb="..tostring(os.time()))
local header="-- RiftHub-Entry: universe-football"
assert(type(source)=="string" and source:sub(1,#header)==header,"Wrong Universe Football response")
local chunk,err=loadstring(source,"=RiftUniverseFootball/main.lua")
assert(chunk,err)
local app=chunk()
assert(type(app)=="table" and app.Game=="Universe Football" and app.Gui and app.Gui.Parent,"Universe Football did not finish opening")
return app
