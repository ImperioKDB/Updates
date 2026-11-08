#!/usr/bin/env python3
"""Bounded, read-only runtime observations of HTMLhost public template previews.

No authentication, form submission, upload, publication, or editor mutation is used.
This script records DOM/runtime metadata only; it does not retain preview source HTML.
"""
from __future__ import annotations
import argparse
import json
import statistics
import time
from datetime import datetime, timezone
from pathlib import Path
from playwright.sync_api import sync_playwright

TEMPLATES = [
    {"id": "creative-playground", "url": "https://htmlhost.co/templates/creative-playground-landing#preview"},
    {"id": "kinetica-motion", "url": "https://htmlhost.co/templates/kinetica-motion-typography#preview"},
    {"id": "futuristic-dark", "url": "https://htmlhost.co/templates/futuristic-dark-landing#preview"},
    {"id": "full-stack-portfolio", "url": "https://htmlhost.co/templates/full-stack-designer-portfolio#preview"},
    {"id": "business-web-studio", "url": "https://htmlhost.co/templates/business-web-studio#preview"},
]

INIT_SCRIPT = r"""(() => {
  const p = window.__phase1b = { cls: 0, shifts: [], longTasks: [], lcp: [] };
  try { new PerformanceObserver(list => { for (const e of list.getEntries()) {
    if (!e.hadRecentInput) { p.cls += e.value; p.shifts.push({value:e.value, startTime:e.startTime}); }
  }}).observe({type:'layout-shift', buffered:true}); } catch(e) {}
  try { new PerformanceObserver(list => { for (const e of list.getEntries()) p.longTasks.push({startTime:e.startTime, duration:e.duration});
  }).observe({type:'longtask', buffered:true}); } catch(e) {}
  try { new PerformanceObserver(list => { for (const e of list.getEntries()) p.lcp.push({startTime:e.startTime, renderTime:e.renderTime, loadTime:e.loadTime, size:e.size, tag:e.element?.tagName||null});
  }).observe({type:'largest-contentful-paint', buffered:true}); } catch(e) {}
})();"""

OBSERVE_JS = r"""() => {
  const round = n => Number.isFinite(n) ? Math.round(n * 100) / 100 : null;
  const visible = e => { const r=e.getBoundingClientRect(), s=getComputedStyle(e); return r.width>0 && r.height>0 && s.display!=='none' && s.visibility!=='hidden' && Number(s.opacity||1)>0; };
  const brief = e => ({tag:e.tagName, text:(e.innerText||e.getAttribute('aria-label')||e.title||'').trim().replace(/\\s+/g,' ').slice(0,100), id:e.id||null, className:String(e.className||'').slice(0,160), ariaLabel:e.getAttribute('aria-label'), ariaExpanded:e.getAttribute('aria-expanded'), type:e.getAttribute('type'), rect:(()=>{const r=e.getBoundingClientRect();return {x:round(r.x),y:round(r.y),width:round(r.width),height:round(r.height)}})()});
  const anims = document.getAnimations({subtree:true}).slice(0,40).map(a=>({playState:a.playState, currentTime:round(Number(a.currentTime)), startTime:round(Number(a.startTime)), duration:round(Number(a.effect?.getTiming()?.duration)), delay:round(Number(a.effect?.getTiming()?.delay)), easing:a.effect?.getTiming()?.easing||null, iterations:a.effect?.getTiming()?.iterations||null, target:brief(a.effect?.target||document.body)}));
  const animated = [...document.querySelectorAll('body *')].filter(visible).map(e=>({e,s:getComputedStyle(e)})).filter(x=>x.s.animationName!=='none' || (x.s.transitionDuration!=='0s' && x.s.transitionProperty!=='all')).slice(0,30).map(({e,s})=>({element:brief(e), animationName:s.animationName, animationDuration:s.animationDuration, animationDelay:s.animationDelay, animationTimingFunction:s.animationTimingFunction, transitionProperty:s.transitionProperty, transitionDuration:s.transitionDuration, transitionTimingFunction:s.transitionTimingFunction, opacity:s.opacity, transform:s.transform}));
  const nav=performance.getEntriesByType('navigation')[0];
  const resources=performance.getEntriesByType('resource');
  const sized=resources.filter(e=>e.transferSize>0);
  const imgs=[...document.images].map(i=>({alt:(i.alt||'').slice(0,100), complete:i.complete, naturalWidth:i.naturalWidth, naturalHeight:i.naturalHeight, loading:i.loading, bytes:(performance.getEntriesByName(i.currentSrc||i.src).at(-1)||{}).transferSize||0}));
  const fonts=[...document.fonts].map(f=>({family:f.family, style:f.style, weight:f.weight, status:f.status})).slice(0,30);
  const canvas=[...document.querySelectorAll('canvas')].map(c=>({width:c.width,height:c.height,rect:(()=>{const r=c.getBoundingClientRect();return {x:round(r.x),y:round(r.y),width:round(r.width),height:round(r.height)}})(),style:{position:getComputedStyle(c).position,opacity:getComputedStyle(c).opacity}}));
  const perf=window.__phase1b||{};
  const body=document.body, root=document.documentElement;
  return {title:document.title, url:location.href, viewport:{width:innerWidth,height:innerHeight,dpr:devicePixelRatio}, reducedMotion:matchMedia('(prefers-reduced-motion: reduce)').matches, dimensions:{scrollWidth:root.scrollWidth,scrollHeight:root.scrollHeight,bodyWidth:body.scrollWidth,bodyHeight:body.scrollHeight}, elements:{total:document.querySelectorAll('*').length, buttons:[...document.querySelectorAll('button,[role=button]')].filter(visible).slice(0,60).map(brief), focusable:[...document.querySelectorAll('a[href],button,input,select,textarea,[tabindex]:not([tabindex="-1"])')].filter(visible).slice(0,80).map(brief)}, canvas, images:{count:imgs.length,loaded:imgs.filter(i=>i.complete&&i.naturalWidth>0).length,failed:imgs.filter(i=>i.complete&&i.naturalWidth===0).length,items:imgs.slice(0,50)}, fonts:{status:document.fonts.status,faces:fonts}, animations:{active:anims.length,items:anims}, animatedElements:animated, resources:{count:resources.length,knownTransferBytes:sized.reduce((n,e)=>n+e.transferSize,0),knownDecodedBytes:sized.reduce((n,e)=>n+e.decodedBodySize,0),sizedCount:sized.length,zeroOrOpaqueCount:resources.length-sized.length,largest:sized.slice().sort((a,b)=>b.transferSize-a.transferSize).slice(0,12).map(e=>({name:new URL(e.name,location.href).origin+new URL(e.name,location.href).pathname,initiatorType:e.initiatorType,transferSize:e.transferSize,decodedBodySize:e.decodedBodySize,duration:round(e.duration)}))}, timings:nav?{domContentLoaded:round(nav.domContentLoadedEventEnd),load:round(nav.loadEventEnd),responseEnd:round(nav.responseEnd),transferSize:nav.transferSize,encodedBodySize:nav.encodedBodySize}:null, vitals:{cls:round(perf.cls||0),shiftCount:(perf.shifts||[]).length,longTasks:(perf.longTasks||[]).map(t=>({duration:round(t.duration),startTime:round(t.startTime)})),lcp:(perf.lcp||[]).slice(-5)},
    accessibleText:(body.innerText||'').slice(0,2400)};
}"""

RAF_JS = r"""async () => {
  const t0=performance.now(), ds=[]; let prev=null, count=0;
  await new Promise(resolve=>{function tick(t){ if(prev!==null) ds.push(t-prev); prev=t; count++; if(t-t0<1000) requestAnimationFrame(tick); else resolve(); } requestAnimationFrame(tick);});
  const a=ds.slice().sort((x,y)=>x-y); const q=p=>a.length?a[Math.min(a.length-1,Math.floor((a.length-1)*p))]:null;
  return {windowMs:Math.round(performance.now()-t0),callbacks:count,intervalMs:{median:q(.5),p95:q(.95),max:a.length?a[a.length-1]:null},limitation:'requestAnimationFrame callbacks are not a direct measurement of compositor/GPU presentation FPS'};
}"""


def safe_json(value):
    return json.loads(json.dumps(value, default=str))


def visible_frame(page):
    frames=[]
    for i,el in enumerate(page.locator('iframe').all()):
        try:
            if not el.is_visible(): continue
            box=el.bounding_box()
            if not box: continue
            handle=el.element_handle()
            frame=handle.content_frame() if handle else None
            if frame is None: continue
            frames.append((box['width']*box['height'],i,box,frame))
        except Exception:
            pass
    if not frames: return None, []
    frames.sort(reverse=True,key=lambda x:x[0])
    return frames[0], [{"index":i,"box":box} for _,i,box,_ in frames]


def capture_one(browser, template, width, height, motion):
    context=browser.new_context(viewport={"width":width,"height":height},device_scale_factor=1,reduced_motion=motion,locale='en-US')
    page=context.new_page()
    page.add_init_script(INIT_SCRIPT)
    page.set_default_timeout(12000)
    errors=[]; failed=[]; responses=[]
    page.on('pageerror',lambda e: errors.append(str(e)[:500]))
    page.on('console',lambda m: errors.append('console:'+m.type+':'+m.text[:400]) if m.type=='error' else None)
    page.on('requestfailed',lambda r: failed.append({"url":r.url.split('?')[0],"failure":r.failure}))
    page.on('response',lambda r: responses.append({"url":r.url.split('?')[0],"status":r.status,"resourceType":r.request.resource_type}) if r.status>=400 else None)
    result={"template":template["id"],"route":template["url"].split('#')[0],"viewport":{"width":width,"height":height},"reduced_motion_setting":motion,"evidence_class":"VERIFIED runtime observation when populated; UNKNOWN if capture failed","load_state":None}
    t=time.monotonic()
    try:
        resp=page.goto(template["url"],wait_until='domcontentloaded',timeout=45000)
        result["http_status"]=resp.status if resp else None
        result["page_title"]=page.title()
        result["landing_url"]=page.url
        # The preview is public and exposed by the #preview state. Do not click any account, template-use, or publish controls.
        page.wait_for_function("document.querySelectorAll('iframe').length >= 3",timeout=15000)
        page.wait_for_timeout(1000)
        chosen,frames=visible_frame(page)
        result["visible_iframes"]=frames
        if chosen is None:
            result["load_state"]="preview iframe not visible"
            result["host_visible_text"]=(page.locator('body').inner_text() or '')[:1800]
        else:
            _,idx,box,frame=chosen
            result["primary_iframe_index"]=idx
            result["primary_iframe_box"]=box
            try:
                frame.locator('body').wait_for(state='visible',timeout=10000)
                page.wait_for_timeout(700)
                result["load_state"]="preview iframe body visible"
                result["runtime"]=safe_json(frame.evaluate(OBSERVE_JS))
                # Approximate rAF callback cadence in the actual main preview frame, not a monitor/GPU FPS measurement.
                if motion=='no-preference':
                    result["raf_sample"]=safe_json(frame.evaluate(RAF_JS))
                    # Capture a second state to see whether exposed Web Animations time advanced.
                    result["animation_resample"]=safe_json(frame.evaluate("() => document.getAnimations({subtree:true}).slice(0,20).map(a=>({playState:a.playState,currentTime:Number.isFinite(Number(a.currentTime))?Number(a.currentTime):null,targetTag:a.effect?.target?.tagName||null,targetClass:String(a.effect?.target?.className||'').slice(0,100)}))"))
            except Exception as e:
                result["load_state"]="iframe access failed"
                result["frame_error"]=type(e).__name__+': '+str(e)[:500]
        result["elapsed_seconds"]=round(time.monotonic()-t,3)
        result["page_errors"]=errors[:30]
        result["request_failures"]=failed[:30]
        result["http_error_responses"]=responses[:30]
    except Exception as e:
        result["load_state"]="capture failed"
        result["elapsed_seconds"]=round(time.monotonic()-t,3)
        result["fatal_error"]=type(e).__name__+': '+str(e)[:700]
        result["page_errors"]=errors[:30]
        result["request_failures"]=failed[:30]
        result["http_error_responses"]=responses[:30]
    finally:
        context.close()
    return result


def main():
    ap=argparse.ArgumentParser()
    ap.add_argument('--output',required=True)
    args=ap.parse_args()
    records=[]
    with sync_playwright() as p:
        browser=p.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox'])
        # Matched desktop load under both motion preferences for each template.
        for template in TEMPLATES:
            for motion in ('no-preference','reduce'):
                print(f"capture {template['id']} 1440x900 {motion}",flush=True)
                records.append(capture_one(browser,template,1440,900,motion))
        # Three representative high-motion previews also get a mobile runtime sample.
        for template_id in ('creative-playground','kinetica-motion','futuristic-dark'):
            template=next(x for x in TEMPLATES if x['id']==template_id)
            print(f"capture {template_id} 390x844 no-preference",flush=True)
            records.append(capture_one(browser,template,390,844,'no-preference'))
        browser.close()
    doc={"capture_date":"2026-11-08","tool":"Python Playwright with /usr/bin/chromium","chromium_version":"156.0.8078.73","playwright_version":"1.64.1","conditions":{"headless":True,"locale":"en-US","device_scale_factor":1,"cache":"fresh browser context per run; cache persisted only within the lifetime of a context","wait":"DOMContentLoaded + 1.0s host preview stabilization + 0.7s after primary iframe body visibility","measurements":"single-run observations; not a Lighthouse lab run or field Core Web Vitals measurement"},"records":records,"method_limitations":["Template preview documents are public sandboxed srcdoc iframes, not published generated websites.","Resource Timing transferSize totals omit cross-origin or TAO-restricted bytes; report known sizes only, not whole-site transfer size.","requestAnimationFrame callback cadence is not equivalent to compositor/GPU presentation FPS.","CLS/LCP entries may be unavailable because capture begins after initial page scripts; an absent value is not zero.","A single run cannot establish repeatable performance or real-device behavior.","No form, download, publish, upload, template-use, authenticated, or account-scoped action was taken."]}
    out=Path(args.output); out.parent.mkdir(parents=True,exist_ok=True); out.write_text(json.dumps(doc,indent=2,ensure_ascii=False)+'\n')
    print(f"wrote {out} ({out.stat().st_size} bytes)")

if __name__=='__main__': main()
