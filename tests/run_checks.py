from pathlib import Path
import os,shutil,subprocess,tempfile,html,re
r=Path(__file__).resolve().parents[1]
compiler=os.environ.get('LUAU_COMPILE_BIN') or shutil.which('luau-compile') or '/workspace/luau-check/luau-compile'
luau=os.environ.get('LUAU_BIN') or shutil.which('luau') or '/workspace/luau-check/luau'
for file in [r/'main.lua',r/'execute.lua',*list((r/'src').glob('*.lua'))]:
 subprocess.run([compiler,'--null',str(file)],capture_output=True,check=True)
s=(r/'tests/checks.luau').read_text().replace('-- STANDALONE',(r/'main.lua').read_text()).replace('-- PASS MATH',(r/'src/PassMath.lua').read_text()).replace('-- PASS PLANNER',(r/'src/PassPlanner.lua').read_text())
with tempfile.NamedTemporaryFile(mode='w',suffix='.luau') as f:
 f.write(s);f.flush();subprocess.run([luau,f.name],check=True)
page=(r/'docs/UniverseFootball_Editor.html').read_text()
assert html.unescape(re.search(r'<textarea id="source"[^>]*>(.*?)</textarea>',page,re.S).group(1))==(r/'main.lua').read_text()
with tempfile.NamedTemporaryFile(mode='w',suffix='.js') as f:
 f.write(re.search(r'<script>(.*?)</script>',page,re.S).group(1));f.flush();subprocess.run(['node','--check',f.name],check=True)
for p in (r/'src').glob('*.lua'): assert p.read_text() in (r/'main.lua').read_text()
print('PASS: source compilation, full editable-file parity, embedded modules and browser JavaScript syntax.')
