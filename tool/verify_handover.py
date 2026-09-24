"""Local-only reproducible checks; no deploy, commit or source rewriting."""
from pathlib import Path
import datetime,json,os,subprocess,sys,time,hashlib
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'docs/verification'
OUT.mkdir(parents=True,exist_ok=True)
env=os.environ.copy()
for key in ['HTTP_PROXY','HTTPS_PROXY','ALL_PROXY','http_proxy','https_proxy','all_proxy']:
    env[key]=''
env['NO_PROXY']='localhost,127.0.0.1'
results=[]
def run(name,cmd):
    start=time.monotonic()
    p=subprocess.run(cmd,cwd=ROOT,env=env,capture_output=True,text=True)
    (OUT/(name+'.log')).write_text(p.stdout+p.stderr)
    result={'name':name,'command':cmd,'exit':p.returncode,'seconds':round(time.monotonic()-start,2),'log':name+'.log'}
    results.append(result)
    print(name,'PASS' if p.returncode==0 else 'FAIL',flush=True)
    return p.returncode==0
for path in sorted((ROOT/'tool').glob('export_*.cjs')):
    if '--check' in path.read_text():run(path.stem,['node',str(path),'--check'])
run('source_dom_translations',[sys.executable,str(ROOT/'tool/export_dom_translation.py'),'--check'])
run('analyze',['flutter','analyze'])
passed=run('test',['flutter','test','--reporter','expanded'])
if passed:run('route_mapping',[sys.executable,str(ROOT/'tool/generate_route_mapping.py')])
run('build_web',['flutter','build','web','--release','--no-web-resources-cdn'])
original={p:hashlib.sha256((ROOT/'../surgo-mobile-new'/p).read_bytes()).hexdigest() for p in ['app.js','index.html','questions.js','i18n.js']}
summary={'generated':datetime.datetime.now().astimezone().isoformat(),'allPassed':all(x['exit']==0 for x in results),'originalHashes':original,'checks':results}
(OUT/'summary.json').write_text(json.dumps(summary,indent=2)+'\n')
print(json.dumps({'allPassed':summary['allPassed'],'checks':len(results),'directory':str(OUT)}),flush=True)
sys.exit(0 if summary['allPassed'] else 1)
