from pathlib import Path
import html
r=Path(__file__).parent
s='''-- RiftHub-Entry: universe-football
-- Rift Hub / Universe Football / 1.4
local env=type(getgenv)=="function" and getgenv() or _G
local prior=env.RiftUniverseFootball
if type(prior)=="table" and type(prior.Unload)=="function" then pcall(prior.Unload) end
local Kit={}
function Kit.create(class,props,parent)
 local obj=Instance.new(class)
 for k,v in pairs(props) do obj[k]=v end
 if parent then obj.Parent=parent end
 return obj
end
'''
for module in ['Brand','Interface','PassMath','PassPlanner','Assists','Movement','Runtime']:
 s+='local '+module+'=(function()\n'+(r/'src'/f'{module}.lua').read_text()+'\nend)()\n'
s+='''local brand=Brand("https://raw.githubusercontent.com/copperpoppercms-sys/rift-hub-universe-football/main/assets/rift_logo.jpg")
local app=Runtime(Kit,brand,Interface,Assists,Movement,PassPlanner,PassMath)
app.OnUnload=function() if env.RiftUniverseFootball==app then env.RiftUniverseFootball=nil end end
env.RiftUniverseFootball=app
return app
'''
(r/'main.lua').write_text(s)
(r/'execute.lua').write_text('''local source=game:HttpGet("https://raw.githubusercontent.com/copperpoppercms-sys/rift-hub-universe-football/main/main.lua?cb="..tostring(os.time()))
local header="-- RiftHub-Entry: universe-football"
assert(type(source)=="string" and source:sub(1,#header)==header,"Wrong Universe Football response")
local chunk,err=loadstring(source,"=RiftUniverseFootball/main.lua")
assert(chunk,err)
local app=chunk()
assert(type(app)=="table" and app.Game=="Universe Football" and app.Gui and app.Gui.Parent,"Universe Football did not finish opening")
return app
''')
page=(r/'docs/editor_template.html').read_text().replace('{{SOURCE}}',html.escape(s))
(r/'docs/UniverseFootball_Editor.html').write_text(page)
print('Built standalone and editable file:',len(s),'characters')
