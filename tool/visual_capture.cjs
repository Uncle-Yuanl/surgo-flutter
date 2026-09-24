// Real Chrome/CDP screenshots at 390x844 DPR1. No source H5 files are changed.
const fs=require('fs'),path=require('path'),{spawn}=require('child_process');
const ROOT=path.resolve(__dirname,'..');
const kind=process.argv[2]||'h5';
const isH5=kind==='h5'||kind==='online';
const wanted=process.argv[3];
const settleMs=Number(process.argv[4]||1500);
const revision=process.argv[5]||'';
const requested=wanted?wanted.split(','):null;
const localeFilter=['zh','en'].includes(process.argv[7])?process.argv[7]:null;
const useFontCache=process.argv.includes('--font-cache');
const bottomState=process.argv.includes('--bottom');
const subscribeClick=process.argv.includes('--subscribe');
if(subscribeClick&&(!bottomState||wanted!=='report'))throw Error('Subscribe capture requires report --bottom');
const reviewState=process.argv.find(x=>x.startsWith('--review='))?.split('=')[1]||'';
if(reviewState&&!['1-mark','2-mark','1-l1','2-l1'].includes(reviewState))throw Error('Unknown review state');
const listenAction=process.argv.find(x=>x.startsWith('--listen-action='))?.split('=')[1]||'';
if(listenAction&&!['switch2','speed'].includes(listenAction))throw Error('Unknown listening action');
const listenReview=process.argv.find(x=>x.startsWith('--listen-review='))?.split('=')[1]||'';
if(listenReview&&!/^[dm][1-4]$/.test(listenReview))throw Error('Unknown listening review');
const readReview=process.argv.find(x=>x.startsWith('--read-review='))?.split('=')[1]||'';
if(readReview&&!['daily','1','2','3'].includes(readReview))throw Error('Unknown reading review fixture');
const readType=process.argv.find(x=>x.startsWith('--read-type='))?.split('=')[1]||'';
if(readType&&!['mc','tfng','yyng','imatch','hmatch','fmatch','ematch','scomplete','summary','diagram','short'].includes(readType))throw Error('Unknown reading type');
const readIndex=process.argv.find(x=>x.startsWith('--read-index='))?.split('=')[1]||'';
if(readIndex&&!/^\d+$/.test(readIndex))throw Error('Invalid reading index');
const readAction=process.argv.find(x=>x.startsWith('--read-action='))?.split('=')[1]||'';
const videoFrame=process.argv.includes('--video-frame');
if(videoFrame&&readAction!=='overtime')throw Error('Video frame capture only supported for reading overtime');
if(readAction&&!['nav','pick','qbottom','abottom','drag','input','overtime'].includes(readAction))throw Error('Unknown reading action');
const scrollY=Number(process.argv.find(x=>x.startsWith('--scroll='))?.split('=')[1]||0);
if(!Number.isFinite(scrollY)||scrollY<0)throw Error('Invalid scroll offset');
const reportState=process.argv.find(x=>x.startsWith('--report-state='))?.split('=')[1]||'';
const reportExam=process.argv.includes('--report-toefl');
if(reportState&&!['full','early','partial','strong','no_target'].includes(reportState))throw Error('Unknown report state');
const fixture=process.argv.find(x=>x.startsWith('--fixture='))?.split('=')[1]||'';
if(fixture&&!['t1','letter','t2','email'].includes(fixture))throw Error('Unknown fixture');
const fixtureCard=fixture==='email'?'email':fixture;
const composeState=process.argv.find(x=>x.startsWith('--compose='))?.split('=')[1]||'';
if(composeState&&!['topics','essay','open','analysis','arg','para','vocab'].includes(composeState))throw Error('Unknown compose state');
const planState=process.argv.find(x=>x.startsWith('--plan='))?.split('=')[1]||'';
if(planState&&!['analysis','arg','arg-picked','para','vocab','vocab-picked'].includes(planState))throw Error('Unknown plan state');
const inputDraft=process.argv.includes('--input-draft');
if(inputDraft&&(wanted!=='writingCompose'||composeState!=='essay'))throw Error('Draft requires compose essay');
const chartZoom=process.argv.includes('--chart-zoom');
if(chartZoom&&(fixture!=='t1'||wanted!=='writingSession'))throw Error('Chart zoom requires writingSession t1');
let fontCache=null;
if(useFontCache){
 const manifest=JSON.parse(fs.readFileSync(path.join(ROOT,'artifacts/visual_audit/font_cache/manifest.json')));
 const bytes=fs.readFileSync(path.join(ROOT,'artifacts/visual_audit/font_cache/notosanssc-v36.ttf'));
 const hash=require('crypto').createHash('sha256').update(bytes).digest('hex');
 if(bytes.length!==manifest.bytes||hash!==manifest.sha256)throw Error('Cached font integrity mismatch');
 fontCache={...manifest,body:bytes.toString('base64')};
}
const rows=JSON.parse(fs.readFileSync(path.join(ROOT,'artifacts/visual_audit/routes.json'))).filter(r=>(!requested||requested.includes(r.route))&&(!localeFilter||r.locale===localeFilter));
const wait=ms=>new Promise(r=>setTimeout(r,ms));
async function main(){
 const profile=path.join(ROOT,'artifacts/visual_audit/chrome-'+kind+'-'+Date.now());fs.mkdirSync(profile,{recursive:true});
 const child=spawn('/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',[
  '--headless=new','--remote-debugging-port=0','--no-first-run','--no-default-browser-check',
  '--disable-background-timer-throttling','--disable-renderer-backgrounding','--autoplay-policy=no-user-gesture-required',
  '--user-data-dir='+profile,'about:blank'],{stdio:'ignore'});
 let ws;
 try{
  let portfile=path.join(profile,'DevToolsActivePort');
  for(let i=0;i<200&&!fs.existsSync(portfile);i++)await wait(100);
  const port=fs.readFileSync(portfile,'utf8').split('\n')[0];
  const target=await(await fetch(`http://127.0.0.1:${port}/json/new?about:blank`,{method:'PUT'})).json();
  ws=new WebSocket(target.webSocketDebuggerUrl);await new Promise((res,rej)=>{ws.onopen=res;ws.onerror=rej});
  let n=0;const pending=new Map();let errors=[];let requests=[];const requestUrls=new Map();const fontPending=new Set();let lastFontEvent=Date.now();
  ws.onmessage=e=>{const m=JSON.parse(e.data);if(m.id){const q=pending.get(m.id);if(q){pending.delete(m.id);m.error?q.reject(new Error(JSON.stringify(m.error))):q.resolve(m.result)}}else if(m.method==='Fetch.requestPaused'){
    const request=m.params;
    const action=fontCache&&request.request.url===fontCache.url?
      send('Fetch.fulfillRequest',{requestId:request.requestId,responseCode:200,responseHeaders:[{name:'Content-Type',value:'font/ttf'},{name:'Access-Control-Allow-Origin',value:'*'},{name:'Cache-Control',value:'public, max-age=31536000'}],body:fontCache.body}):send('Fetch.continueRequest',{requestId:request.requestId});
    action.catch(error=>errors.push({fontTransportError:error.message}));
  }else if(m.method==='Runtime.exceptionThrown')errors.push(m.params.exceptionDetails);else if(m.method==='Network.requestWillBeSent'){requestUrls.set(m.params.requestId,m.params.request.url);if(/fonts|\.ttf|\.woff/.test(m.params.request.url)){fontPending.add(m.params.requestId);lastFontEvent=Date.now()}}else if(m.method==='Network.loadingFinished'){if(fontPending.delete(m.params.requestId))lastFontEvent=Date.now()}else if(m.method==='Network.loadingFailed'){fontPending.delete(m.params.requestId);lastFontEvent=Date.now();requests.push({url:requestUrls.get(m.params.requestId),error:m.params.errorText})}else if(m.method==='Network.responseReceived'&&/fonts|\.ttf|\.woff/.test(m.params.response.url)){requests.push({url:m.params.response.url,status:m.params.response.status,fromDiskCache:!!m.params.response.fromDiskCache})}};
  function send(method,params={}){return new Promise((resolve,reject)=>{const id=++n;pending.set(id,{resolve,reject});ws.send(JSON.stringify({id,method,params}));setTimeout(()=>{if(pending.has(id)){pending.delete(id);reject(new Error('CDP timeout '+method))}},20000).unref()})}
  async function evaluate(expression){const r=await send('Runtime.evaluate',{expression,awaitPromise:true,returnByValue:true});if(r.exceptionDetails)throw Error(r.exceptionDetails.text+' '+JSON.stringify(r.exceptionDetails.exception));return r.result.value}
  await send('Page.enable');await send('Runtime.enable');
  await send('Emulation.setDeviceMetricsOverride',{width:390,height:844,deviceScaleFactor:1,mobile:false});
  await send('Network.enable');
  // Fresh isolated profile per batch prevents stale app cache; reuse fonts.
  await send('Network.setCacheDisabled',{cacheDisabled:false});
  await send('Network.setBypassServiceWorker',{bypass:true});
  if(fontCache)await send('Fetch.enable',{patterns:[{urlPattern:fontCache.url,requestStage:'Request'}]});
  const ledger=[];
  if(kind==='flutter'){
    const base=`http://127.0.0.1:${process.argv[6]||(revision?8953:8952)}/`;
    for(const asset of ['assets/FontManifest.json','assets/assets/data/questions.json','assets/assets/data/source_dom_translations.json']){
      const response=await fetch(base+asset);
      if(!response.ok)throw Error(`Required audit asset HTTP ${response.status}: ${base+asset}`);
      const body=await response.text();if(!body.trim())throw Error('Empty audit asset '+asset);JSON.parse(body);
    }
  }
  for(const row of rows){
   errors=[];requests=[];fontPending.clear();lastFontEvent=Date.now();const start=Date.now();let record={...row,kind,viewport:{width:390,height:844,dpr:1}};
   try{
    const url=isH5?(kind==='online'?'https://surgo-mobile.vercel.app/':`http://127.0.0.1:${process.env.H5_AUDIT_PORT||8913}/index.html`):`http://127.0.0.1:${process.argv[6]||(revision?8953:8952)}/?route=${row.route}&lang=${row.locale}${reportState?'&reportState='+reportState:''}${reportExam?'&exam=toefl':''}${listenReview?'&listenReview='+listenReview:''}${readReview?'&readReview='+readReview:''}${readAction==='overtime'?'&readSeconds=1':''}${readType?'&readType='+readType:''}${readIndex?'&readIndex='+readIndex:''}${reviewState?'&review='+reviewState:''}${composeState?'&compose='+composeState:''}${planState?'&plan='+planState:''}${fixture?`&card=${fixtureCard}&exam=${fixture==='email'?'toefl':'ielts'}`:''}`;
    const navigationUrl=url+(url.includes('?')?'&':'?')+'auditCapture='+Date.now();
    await send('Page.navigate',{url:navigationUrl});
    let ready=false;
    for(let i=0;i<200;i++){ready=await evaluate(`location.href===${JSON.stringify(navigationUrl)} && `+(isH5?"document.readyState==='complete'&&typeof go==='function'":"document.readyState==='complete'&&!!document.querySelector('flt-glass-pane')"));if(ready)break;await wait(100)}
    if(!ready)throw Error('document not ready');
    if(isH5){
     await evaluate(`(()=>{const style=document.createElement('style');style.textContent='html,body{width:390px!important;height:844px!important;min-height:0!important;margin:0!important;overflow:hidden!important}.phone{width:390px!important;height:844px!important;min-width:390px!important;transform:none!important;border:0!important;border-radius:0!important;box-shadow:none!important;flex:none!important}';document.head.appendChild(style);examType=${JSON.stringify(fixture==='email'||row.route.startsWith('tf')?'toefl':'ielts')};uiLang=${JSON.stringify(row.locale)};${listenReview?`sessionMode='${listenReview[0]==='m'?'mock':'daily'}';lisPart='s${listenReview[1]}';lfPart=${listenReview[1]};`:''}${readReview?`sessionMode=${JSON.stringify(readReview==='daily'?'daily':'mock')};raPas=${readReview==='daily'?1:readReview};`:''}${readType?`selReadType=${JSON.stringify(readType)};`:''}${readIndex?`${row.route==='typeSession'?'typeIdx':'readIdx'}=${readIndex};`:''}${reviewState?`wfTask=${reviewState[0]};wfTab=${JSON.stringify(reviewState.split('-')[1])};`:''}${fixture?`selWizCard=${JSON.stringify(fixtureCard)};`:''}${planState?`planStepCur=${JSON.stringify(planState==='arg-picked'?'arg':planState==='vocab-picked'?'vocab':planState)};planArgs.clear();planVocab.clear();${['arg-picked','para','vocab','vocab-picked'].includes(planState)?'planArgs.add(0);':''}${planState==='vocab-picked'?'planVocab.add(0);':''}`:''}${composeState?`weTab=${JSON.stringify(composeState==='essay'?'essay':'topics')};wePlanOpen=${!['essay','topics'].includes(composeState)};wePlanMod=${JSON.stringify(['analysis','arg','para','vocab'].includes(composeState)?composeState:'')};`:''}go(${JSON.stringify(row.route)});return true})()`);
    }
    if(isH5){
      // Original render uses setTimeout(...,20), not requestAnimationFrame.
      // Await the observed DOM condition before inspecting route resources.
      let active=false;
      for(let i=0;i<100;i++){
        active=await evaluate(`curPage===${JSON.stringify(row.route)} && !!document.querySelector('.screen.active:not(.leaving)')`);
        if(active)break;
        await wait(20);
      }
      if(!active)throw Error('Requested H5 route is not active');
    }
    await evaluate('document.fonts.ready.then(()=>true)');
    if(isH5){
      record.images=await evaluate(`Promise.all(Array.from(document.querySelectorAll('.screen.active img')).map(async img=>{
        await img.decode();
        if(!img.complete||img.naturalWidth===0)throw Error('Image incomplete: '+img.src);
        const r=img.getBoundingClientRect();
        return {src:img.src,naturalWidth:img.naturalWidth,naturalHeight:img.naturalHeight,width:r.width,height:r.height};
      }))`);
    }
    await wait(isH5?700:settleMs);
    await evaluate('new Promise(resolve=>requestAnimationFrame(()=>requestAnimationFrame(()=>resolve(true))))');
    if(kind==='flutter'){
      const deadline=Date.now()+90000;
      while(Date.now()<deadline&&(fontPending.size>0||Date.now()-lastFontEvent<1200))await wait(100);
      if(fontPending.size>0)throw Error('font requests still pending: '+[...fontPending].map(id=>requestUrls.get(id)).join(','));
      if(requests.some(r=>r.error&&/fonts|\.ttf|\.woff/.test(r.url||'')))throw Error('font request failed');
      await wait(300); // renderer repaints after fallback registration
    }
    if(errors.length)throw Error('Page runtime exception: '+JSON.stringify(errors.map(e=>e.exception?.description||e.text||e)));
    if(kind==='flutter'){
      const expected='SURGO visual audit — '+row.route;
      const title=await evaluate('document.title');
      if(title!==expected)throw Error('Audit app not rendered: expected '+expected+', got '+title);
    }
    record.fontsSettled=true;record.fontCachePolicy='fresh-profile-batch-cache';
    if(fontCache)record.exactFontTransportCache={url:fontCache.url,bytes:fontCache.bytes,sha256:fontCache.sha256};
    record.actual=await evaluate(isH5?"({width:innerWidth,height:innerHeight,route:curPage,lang:uiLang,active:document.querySelector('.screen.active')?.innerText.slice(0,1200),phone:{width:document.querySelector('.phone').clientWidth,height:document.querySelector('.phone').clientHeight}})":"({width:innerWidth,height:innerHeight,title:document.title,canvases:document.querySelectorAll('canvas').length})");
    if(isH5)record.layout=await evaluate(`Array.from(document.querySelectorAll('.screen.active,.screen.active *')).map(el=>{const r=el.getBoundingClientRect(),s=getComputedStyle(el);return {tag:el.tagName,cls:el.className,x:r.x,y:r.y,w:r.width,h:r.height,text:el.children.length?undefined:el.textContent,font:s.fontFamily,size:s.fontSize,weight:s.fontWeight,lineHeight:s.lineHeight,spacing:s.letterSpacing,padding:s.padding,margin:s.margin,color:s.color,background:s.backgroundColor,radius:s.borderRadius}})`);
    if(isH5&&reviewState)record.essayLines=await evaluate(`(()=>{
      const e=document.querySelector('.screen.active .wf-essay'),w=document.createTreeWalker(e,NodeFilter.SHOW_TEXT);let n,chars=[];
      while(n=w.nextNode()){for(let i=0;i<n.length;i++){const r=document.createRange();r.setStart(n,i);r.setEnd(n,i+1);const b=r.getBoundingClientRect();chars.push({c:n.data[i],x:b.x,y:b.y,tag:n.parentElement.tagName});}}
      const ys=[...new Set(chars.filter(c=>c.tag==='DIV').map(c=>c.y))].sort((a,b)=>a-b);
      return ys.map(y=>chars.filter(c=>ys.reduce((a,b)=>Math.abs(c.y-a)<Math.abs(c.y-b)?a:b)===y).sort((a,b)=>a.x-b.x).map(c=>c.c).join(''));
    })()`);
    if(listenAction){
      const delta=listenAction==='switch2'?250:850;
      if(isH5)await evaluate(`document.querySelector('.screen.active').scrollTop=${delta}`);
      else await send('Input.dispatchMouseEvent',{type:'mouseWheel',x:195,y:600,deltaX:0,deltaY:delta});
      await wait(650);
      let point;
      if(isH5)point=await evaluate(`(()=>{const e=document.querySelector('${listenAction==='switch2'?'#lf-tabs .lf-part:nth-child(2)':'.la-spd'}');const r=e.getBoundingClientRect();return {x:r.x+r.width/2,y:r.y+r.height/2}})()`);
      else point={x:listenAction==='switch2'?(row.locale==='zh'?143:122):315,y:listenAction==='switch2'?551:(row.locale==='zh'?120:100)};
      for(const type of ['mousePressed','mouseReleased'])await send('Input.dispatchMouseEvent',{type,x:point.x,y:point.y,button:'left',clickCount:1});
      await wait(700);
      if(kind==='flutter'){
        await wait(1600);
        const until=Date.now()+30000;
        while(Date.now()<until&&(fontPending.size>0||Date.now()-lastFontEvent<1200))await wait(100);
        if(fontPending.size>0)throw Error('Post-action font requests pending');
        await wait(500);
      }
      record.listeningAction=isH5?await evaluate(`({part:lfPart,scroll:document.querySelector('.screen.active').scrollTop,tab:document.querySelector('#lf-tabs')?.textContent,body:document.querySelector('#lf-body')?.textContent.slice(0,250),menu:!!document.getElementById('la-spd-menu')})`):{action:listenAction,point};
      record.capturedState='listen-'+listenAction;
    }
    if(scrollY){
      if(isH5){
        record.scrollState=await evaluate(`(()=>{const el=document.querySelector('.screen.active .read-scroll,.screen.active .we-scroll')||document.querySelector('.screen.active');el.scrollTop=${scrollY};return {scrollTop:el.scrollTop,scrollHeight:el.scrollHeight,clientHeight:el.clientHeight}})()`);
      }else{
        await send('Input.dispatchMouseEvent',{type:'mouseWheel',x:195,y:600,deltaX:0,deltaY:scrollY});
        record.scrollState={method:'native-wheel',deltaY:scrollY};
      }
      await wait(600);record.capturedState='scroll-'+scrollY;
    }
    if(bottomState){
      if(isH5){
        record.scrollState=await evaluate(`(()=>{const el=document.querySelector('.screen.active .read-scroll,.screen.active .we-scroll')||document.querySelector('.screen.active');if(!el)throw Error('No source scroll container');el.scrollTop=el.scrollHeight;return {scrollTop:el.scrollTop,scrollHeight:el.scrollHeight,clientHeight:el.clientHeight}})()`);
      }else{
        // Native CanvasKit scrolling: real wheel events, not invented DOM layout.
        for(let step=0;step<5;step++){await send('Input.dispatchMouseEvent',{type:'mouseWheel',x:195,y:600,deltaX:0,deltaY:1500});await wait(150)}
        record.scrollState={method:'native-wheel',deltaY:7500};
      }
      await wait(500);record.capturedState='scrolled-bottom';
    }
    if(chartZoom){
      if(isH5){await evaluate(`document.querySelector('.screen.active .wbc-zoomable').click()`)}
      else{
        // Observed t1 390x844 chart bounds cover x195,y560 in both locales.
        await send('Input.dispatchMouseEvent',{type:'mousePressed',button:'left',clickCount:1,x:195,y:560});
        await send('Input.dispatchMouseEvent',{type:'mouseReleased',button:'left',clickCount:1,x:195,y:560});
      }
      await wait(700);record.capturedState='chart-zoom';
      if(isH5)record.dialog=await evaluate(`(()=>{const e=document.querySelector('.cz-dlg');if(!e)throw Error('Chart dialog absent');const r=e.getBoundingClientRect();return {text:e.innerText,x:r.x,y:r.y,w:r.width,h:r.height}})()`);
    }
    if(inputDraft){
      const text="I can't re-use 2026 ideas. The evidence supports my position.";
      // Both observed essay textareas include x90,y220; use real input on canvas.
      if(isH5)await evaluate(`document.querySelector('.screen.active #we-ta').focus()`);
      else{
        await send('Input.dispatchMouseEvent',{type:'mousePressed',button:'left',clickCount:1,x:90,y:220});
        await send('Input.dispatchMouseEvent',{type:'mouseReleased',button:'left',clickCount:1,x:90,y:220});
      }
      await send('Input.insertText',{text});await wait(450);
      record.inputState={method:'CDP Input.insertText',text};
      if(isH5)record.inputState.actual=await evaluate(`({value:document.querySelector('.screen.active #we-ta').value,count:document.querySelector('.screen.active #we-wc').textContent,clock:document.querySelector('.screen.active #cd-num').textContent})`);
    }
    if(readAction==='overtime'){
      if(isH5){await evaluate('startCountdown(1)');await wait(1500);}
      else await wait(500);
      record.capturedState='read-overtime';
      record.timerFixture={seconds:1,productionDefaultChanged:false};
      if(videoFrame){
        let mediaReady=false;
        for(let i=0;i<160;i++){
          mediaReady=await evaluate(`(()=>{const v=document.querySelector('video');return !!v&&v.readyState===4&&v.videoWidth>0&&v.duration>1&&v.buffered.length>0&&v.buffered.start(0)<=1&&v.buffered.end(v.buffered.length-1)>=v.duration-.1&&v.seekable.length>0&&v.seekable.end(v.seekable.length-1)>=1;})()`);
          if(mediaReady)break;await wait(100);
        }
        if(!mediaReady)throw Error('Overtime video not decoded within 16s');
        record.videoBefore=await evaluate(`(()=>{const v=document.querySelector('video');return {currentTime:v.currentTime,paused:v.paused,muted:v.muted,loop:v.loop,filter:getComputedStyle(v).filter};})()`);
        await evaluate(`(()=>{const v=document.querySelector('video');v.pause();v.currentTime=1;})()`);
        let sought=false;
        for(let i=0;i<100;i++){
          sought=await evaluate(`(()=>{const v=document.querySelector('video');return !v.seeking&&Math.abs(v.currentTime-1)<.002&&v.readyState>=2;})()`);
          if(sought)break;await wait(50);
        }
        if(!sought)throw Error('Overtime frame seek did not settle');
        await wait(100);
        record.videoFrame=await evaluate(`(()=>{const v=document.querySelector('video');return {currentTime:v.currentTime,paused:v.paused,muted:v.muted,loop:v.loop,width:v.videoWidth,height:v.videoHeight,rect:v.getBoundingClientRect().toJSON(),filter:getComputedStyle(v).filter,source:v.currentSrc};})()`);
        record.videoFrame.note='Audit-only pause/seek to 1.000s on both original media players; pixels unmodified';
      }
      if(isH5)record.overtimeState=await evaluate(`({clock:document.querySelector('#cd-num').textContent,modal:mask.className,text:modal.innerText,video:document.querySelector('.ot-otter')?.currentTime})`);
    }else if(readAction==='drag'){
      let y=row.route==='typeSession'?490:395;
      if(isH5)y=await evaluate(`document.querySelector('.rq-top').getBoundingClientRect().y+8`);
      await send('Input.dispatchMouseEvent',{type:'mousePressed',button:'left',clickCount:1,x:195,y});
      for(let step=1;step<=10;step++){await send('Input.dispatchMouseEvent',{type:'mouseMoved',button:'left',buttons:1,x:195,y:y-step*25});await wait(25);}
      await send('Input.dispatchMouseEvent',{type:'mouseReleased',button:'left',clickCount:1,x:195,y:y-250});
      await wait(400);record.capturedState='read-drag';
    }else if(readAction==='input'){
      if(readType!=='short')throw Error('Input coordinates verified only for short reading task');
      if(isH5)await evaluate(`document.querySelector('.gap-inp-box').focus()`);
      else{await send('Input.dispatchMouseEvent',{type:'mousePressed',button:'left',clickCount:1,x:90,y:row.locale==='zh'?711:699});await send('Input.dispatchMouseEvent',{type:'mouseReleased',button:'left',clickCount:1,x:90,y:row.locale==='zh'?711:699});}
      await send('Input.insertText',{text:'sample'});
      await send('Input.dispatchMouseEvent',{type:'mousePressed',button:'left',clickCount:1,x:190,y:210});
      await send('Input.dispatchMouseEvent',{type:'mouseReleased',button:'left',clickCount:1,x:190,y:210});
      await wait(400);record.capturedState='read-input';
      if(isH5)record.readInput=await evaluate(`({value:document.querySelector('.gap-inp-box').value,progress:document.querySelector('.rq-progress').textContent})`);
    }else if(readAction){
      if(isH5){
        const expressions={nav:"document.querySelector('.rq-nav-btn').click()",pick:"document.querySelector('.mc-o,.tfng-o,.match-o').click()",qbottom:"document.querySelector('.rq-scroll').scrollTop=10000",abottom:"document.querySelector('.read-scroll').scrollTop=10000"};
        await evaluate(expressions[readAction]);
      }else{
        const y=readAction==='nav'?(row.route==='typeSession'?510:420):readAction==='pick'?(row.route==='typeSession'?640:540):readAction==='abottom'?320:650;
        if(['nav','pick'].includes(readAction)){
          await send('Input.dispatchMouseEvent',{type:'mousePressed',button:'left',clickCount:1,x:readAction==='nav'?325:195,y});
          await send('Input.dispatchMouseEvent',{type:'mouseReleased',button:'left',clickCount:1,x:readAction==='nav'?325:195,y});
        }else for(let j=0;j<5;j++){await send('Input.dispatchMouseEvent',{type:'mouseWheel',x:195,y,deltaX:0,deltaY:1200});await wait(60);}
      }
      await wait(400);record.capturedState='read-'+readAction;
      if(isH5)record.readingState=await evaluate(`({index:curPage==='typeSession'?typeIdx:readIdx,clock:document.getElementById('cd-num').textContent,question:document.querySelector('.rq-q').textContent,selected:document.querySelector('.mc-o.sel,.tfng-o.sel,.match-o.sel')?.textContent,modal:mask.classList.contains('show'),qScroll:document.querySelector('.rq-scroll').scrollTop})`);
    }
    if(subscribeClick){
      // Coordinates verified in report7 bottom captures: subscribe button center.
      if(isH5)record.subscriptionBefore=await evaluate(`document.querySelector('.rp-sub-btn').textContent`);
      if(isH5)await evaluate(`document.querySelector('.rp-sub-btn').click()`);
      else{
        const y=row.locale==='zh'?537:534;
        await send('Input.dispatchMouseEvent',{type:'mousePressed',button:'left',clickCount:1,x:318,y});
        await send('Input.dispatchMouseEvent',{type:'mouseReleased',button:'left',clickCount:1,x:318,y});
      }
      await wait(350);record.capturedState='subscribed-bottom';
      if(isH5)record.subscriptionAfter=await evaluate(`({label:document.querySelector('.rp-sub-btn').textContent,on:document.querySelector('.rp-sub-btn').classList.contains('on')})`);
    }
    const shot=await send('Page.captureScreenshot',{format:'png',captureBeyondViewport:false,clip:{x:0,y:0,width:390,height:844,scale:1}});
    let evidencePath=kind==='online'?row.h5.replace('artifacts/h5/','artifacts/online/'):revision?row[kind].replace('artifacts/flutter/','artifacts/flutter-'+revision+'/'):row[kind];
    if(reportState||reportExam)evidencePath=evidencePath.replace('.png','-'+(reportExam?'toefl-':'')+(reportState||'full')+'.png');
    if(listenAction)evidencePath=evidencePath.replace('.png','-'+listenAction+'.png');
    if(listenReview)evidencePath=evidencePath.replace('.png','-listen'+listenReview+'.png');
    if(readReview)evidencePath=evidencePath.replace('.png','-review'+readReview+'.png');
    if(readType)evidencePath=evidencePath.replace('.png','-'+readType+'.png');
    if(readIndex)evidencePath=evidencePath.replace('.png','-q'+readIndex+'.png');
    if(readAction)evidencePath=evidencePath.replace('.png','-'+readAction+'.png');
    if(videoFrame)evidencePath=evidencePath.replace('.png','-frame1.png');
    if(readType)record.readType=readType;
    if(reviewState)evidencePath=evidencePath.replace('.png','-'+reviewState+'.png');
    if(scrollY)evidencePath=evidencePath.replace('.png','-scroll'+scrollY+'.png');
    if(reviewState)record.reviewState=reviewState;
    if(fixture)evidencePath=evidencePath.replace('.png','-'+fixture+'.png');
    if(composeState)evidencePath=evidencePath.replace('.png','-'+composeState+'.png');
    if(planState)evidencePath=evidencePath.replace('.png','-'+planState+'.png');
    if(bottomState)evidencePath=evidencePath.replace('.png','-bottom.png');
    if(subscribeClick)evidencePath=evidencePath.replace('.png','-subscribed.png');
    if(inputDraft)evidencePath=evidencePath.replace('.png','-input.png');
    if(chartZoom)evidencePath=evidencePath.replace('.png','-zoom.png');
    if(composeState)record.composeState=composeState;
    if(planState)record.planState=planState;
    if(fixture)record.fixture={card:fixtureCard,exam:fixture==='email'?'toefl':'ielts'};
    record.evidencePath=evidencePath;record.sourceUrl=url;
    const dest=path.join(ROOT,evidencePath);fs.mkdirSync(path.dirname(dest),{recursive:true});fs.writeFileSync(dest,Buffer.from(shot.data,'base64'));
    record.elapsedMs=Date.now()-start;record.errors=errors;record.fontRequests=requests;record.result='captured-not-reviewed';
   }catch(e){record.result='error';record.error=e.message;record.errors=errors;record.fontRequests=requests;process.exitCode=1;console.error(row.route,row.locale,e.message)}
   ledger.push(record);fs.writeFileSync(path.join(ROOT,`artifacts/visual_audit/${kind}${revision?'-'+revision:''}${wanted?'-'+wanted:''}${localeFilter?'-'+localeFilter:''}${reportState?'-state'+reportState:''}${reportExam?'-toefl':''}${listenReview?'-listen'+listenReview:''}${listenAction?'-'+listenAction:''}${readReview?'-review'+readReview:''}${readType?'-'+readType:''}${readIndex?'-q'+readIndex:''}${readAction?'-'+readAction:''}${videoFrame?'-frame1':''}${reviewState?'-'+reviewState:''}${scrollY?'-scroll'+scrollY:''}${fixture?'-'+fixture:''}${planState?'-'+planState:''}${composeState?'-'+composeState:''}${bottomState?'-bottom':''}${subscribeClick?'-subscribed':''}${chartZoom?'-zoom':''}${inputDraft?'-input':''}-capture.json`),JSON.stringify(ledger,null,2));
   console.log(kind,row.locale,row.route,record.result);
  }
 }finally{if(ws)ws.close();child.kill('SIGTERM')}
}
main().catch(e=>{console.error(e);process.exitCode=1});
