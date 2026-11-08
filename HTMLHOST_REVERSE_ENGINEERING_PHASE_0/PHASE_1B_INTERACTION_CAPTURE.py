#!/usr/bin/env python3
"""Run five bounded, reversible interactions on public HTMLhost template previews.

No login, publishing, form submission, template-use, download, or project mutation.
"""
import argparse, json, time
from pathlib import Path
from playwright.sync_api import sync_playwright

ITEMS = [
    {"id":"creative-playground","url":"https://htmlhost.co/templates/creative-playground-landing#preview","test":"drag"},
    {"id":"kinetica-motion","url":"https://htmlhost.co/templates/kinetica-motion-typography#preview","test":"motion-toggle"},
    {"id":"futuristic-dark","url":"https://htmlhost.co/templates/futuristic-dark-landing#preview","test":"canvas-pointer"},
    {"id":"full-stack-portfolio","url":"https://htmlhost.co/templates/full-stack-designer-portfolio#preview","test":"testimonial-next"},
    {"id":"business-web-studio","url":"https://htmlhost.co/templates/business-web-studio#preview","test":"faq-toggle"},
]

STATE_JS = r"""el => {
  const r=el.getBoundingClientRect(), s=getComputedStyle(el);
  return {tag:el.tagName,text:(el.innerText||'').trim().replace(/\\s+/g,' ').slice(0,300),id:el.id||null,className:String(el.className||'').slice(0,240),ariaLabel:el.getAttribute('aria-label'),ariaExpanded:el.getAttribute('aria-expanded'),ariaPressed:el.getAttribute('aria-pressed'),ariaControls:el.getAttribute('aria-controls'),rect:{x:r.x,y:r.y,width:r.width,height:r.height},transform:s.transform,opacity:s.opacity,transitionProperty:s.transitionProperty,transitionDuration:s.transitionDuration,animationName:s.animationName,animationDuration:s.animationDuration,tabIndex:el.tabIndex};
}"""
ANIM_JS = r"""() => document.getAnimations({subtree:true}).slice(0,50).map(a=>({playState:a.playState,currentTime:Number.isFinite(Number(a.currentTime))?Number(a.currentTime):null,duration:a.effect?.getTiming()?.duration??null,easing:a.effect?.getTiming()?.easing??null,targetTag:a.effect?.target?.tagName||null,targetClass:String(a.effect?.target?.className||'').slice(0,100)}))"""

def main_frame(page):
    frames=[]
    for i,el in enumerate(page.locator('iframe').all()):
        try:
            if not el.is_visible(): continue
            box=el.bounding_box()
            handle=el.element_handle()
            frame=handle.content_frame() if handle else None
            if box and frame: frames.append((box['width']*box['height'],i,box,frame))
        except Exception: pass
    if not frames: return None
    return sorted(frames,key=lambda x:x[0],reverse=True)[0]

def state(locator):
    return locator.evaluate(STATE_JS)

def run_one(browser,item,outdir):
    motion='reduce' if item['test']=='canvas-pointer' else 'no-preference'
    context=browser.new_context(viewport={"width":1440,"height":900},device_scale_factor=1,reduced_motion=motion,locale='en-US')
    page=context.new_page(); page.set_default_timeout(15000)
    errors=[]; page.on('pageerror',lambda e: errors.append(str(e)[:500]))
    rec={"template":item['id'],"route":item['url'].split('#')[0],"interaction":item['test'],"viewport":{"width":1440,"height":900},"reduced_motion":motion,"result":"not run"}
    try:
        response=page.goto(item['url'],wait_until='domcontentloaded',timeout=45000)
        page.wait_for_function("document.querySelectorAll('iframe').length >= 3",timeout=15000)
        page.wait_for_timeout(1000)
        rec['http_status']=response.status if response else None
        chosen=main_frame(page)
        if not chosen: raise RuntimeError('No visible preview iframe found')
        _,idx,box,frame=chosen
        frame.locator('body').wait_for(state='visible',timeout=10000)
        rec['iframe']={"index":idx,"box":box}
        before_time=time.monotonic()
        if item['test']=='drag':
            target=frame.get_by_role('button',name='Drag the orange blob')
            if target.count()!=1: raise RuntimeError(f'Expected one orange blob handle; found {target.count()}')
            rec['target_before']=state(target)
            bbox=target.bounding_box()
            if not bbox: raise RuntimeError('Drag target has no measurable box')
            x=bbox['x']+bbox['width']/2; y=bbox['y']+bbox['height']/2
            page.mouse.move(x,y); page.mouse.down()
            page.mouse.move(x+72,y+46,steps=8)
            page.mouse.up(); page.wait_for_timeout(450)
            rec['target_after']=state(target)
            rec['result']='completed pointer drag of 72×46 CSS px; no form or navigation action'
        elif item['test']=='motion-toggle':
            target=frame.locator('button[aria-label="Pause page motion"]')
            if target.count()!=1: raise RuntimeError(f'Expected one pause control; found {target.count()}')
            rec['animations_before']=frame.evaluate(ANIM_JS)
            rec['control_before']=state(target)
            target.click(); page.wait_for_timeout(350)
            resume=frame.locator('button[aria-label="Resume page motion"]')
            rec['pause_state']={"control":state(resume) if resume.count()==1 else None,"animations":frame.evaluate(ANIM_JS)}
            if resume.count()==1:
                resume.click(); page.wait_for_timeout(350)
                rec['resume_state']={"control":state(frame.locator('button[aria-label="Pause page motion"]')) if frame.locator('button[aria-label="Pause page motion"]').count()==1 else None,"animations":frame.evaluate(ANIM_JS)}
            rec['result']='completed pause and resume toggle'
        elif item['test']=='canvas-pointer':
            canvas=frame.locator('canvas').first
            if canvas.count()!=1: raise RuntimeError(f'Expected a canvas; found {canvas.count()}')
            rec['canvas_before']=state(canvas)
            rec['active_animations_before']=frame.evaluate(ANIM_JS)
            canvas.evaluate("e=>{window.__phase1bPointer={count:0,last:null};e.addEventListener('pointermove',ev=>{window.__phase1bPointer.count++;window.__phase1bPointer.last={x:ev.clientX,y:ev.clientY,pointerType:ev.pointerType}},true)}")
            outdir.mkdir(parents=True,exist_ok=True)
            before=outdir/f'{item["id"]}-reduced-motion-before.png'; idle=outdir/f'{item["id"]}-reduced-motion-idle.png'; after=outdir/f'{item["id"]}-reduced-motion-after-pointer.png'
            canvas.screenshot(path=str(before))
            box=canvas.bounding_box()
            if not box: raise RuntimeError('Canvas has no measurable box')
            page.wait_for_timeout(600)
            canvas.screenshot(path=str(idle))
            page.mouse.move(box['x']+box['width']*.72,box['y']+box['height']*.35,steps=12)
            page.wait_for_timeout(600)
            canvas.screenshot(path=str(after))
            rec['canvas_after']=state(canvas)
            rec['active_animations_after']=frame.evaluate(ANIM_JS)
            rec['pointer_event_observation']=frame.evaluate('window.__phase1bPointer||null')
            import hashlib
            rec['screenshots']={"before":str(before),"idle":str(idle),"after_pointer":str(after),"sha256":{p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in (before,idle,after)}}
            rec['result']='completed reduced-motion pointer test with timed idle and post-pointer screenshots'
        elif item['test']=='testimonial-next':
            target=frame.locator('button[aria-label="Next testimonial"]')
            if target.count()!=1: raise RuntimeError(f'Expected one Next testimonial control; found {target.count()}')
            slider=frame.locator('#testimonial-slider')
            rec['slides_before']=slider.locator('.testimonial-slide').evaluate_all("els=>els.map(e=>({class:e.className,text:(e.innerText||'').trim().slice(0,200),opacity:getComputedStyle(e).opacity,transform:getComputedStyle(e).transform}))")
            rec['control_before']=state(target)
            rec['animations_before']=frame.evaluate(ANIM_JS)
            target.click(); page.wait_for_timeout(1000)
            rec['slides_after']=slider.locator('.testimonial-slide').evaluate_all("els=>els.map(e=>({class:e.className,text:(e.innerText||'').trim().slice(0,200),opacity:getComputedStyle(e).opacity,transform:getComputedStyle(e).transform}))")
            rec['control_after']=state(target)
            rec['animations_after']=frame.evaluate(ANIM_JS)
            rec['result']='completed one next-testimonial activation'
        elif item['test']=='faq-toggle':
            target=frame.get_by_role('button',name='How long does a website take?')
            if target.count()!=1: raise RuntimeError(f'Expected one FAQ disclosure; found {target.count()}')
            rec['control_before']=state(target)
            panel_id=target.get_attribute('aria-controls')
            panel=frame.locator('#'+panel_id) if panel_id else None
            panel_state=lambda: panel.evaluate("e=>{const s=getComputedStyle(e),r=e.getBoundingClientRect();return {className:e.className,text:(e.innerText||'').trim().slice(0,800),height:r.height,maxHeight:s.maxHeight,opacity:s.opacity,transitionProperty:s.transitionProperty,transitionDuration:s.transitionDuration,transitionTimingFunction:s.transitionTimingFunction}}") if panel else None
            rec['controlled_panel_before']=panel_state()
            target.click(); page.wait_for_timeout(350)
            rec['open_state']={"control":state(target),"panel":panel_state(),"animations":frame.evaluate(ANIM_JS)}
            target.click(); page.wait_for_timeout(250)
            rec['closed_state']={"control":state(target),"panel":panel_state()}
            rec['result']='completed FAQ open and close'
        rec['elapsed_seconds']=round(time.monotonic()-before_time,3)
    except Exception as e:
        rec['result']='interaction test failed; no conclusion'
        rec['error']=type(e).__name__+': '+str(e)[:700]
    rec['page_errors']=errors[:20]
    context.close()
    return rec

def main():
    ap=argparse.ArgumentParser(); ap.add_argument('--output',required=True); ap.add_argument('--evidence-dir',required=True); a=ap.parse_args()
    evidence_dir=Path(a.evidence_dir)
    with sync_playwright() as p:
        browser=p.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox'])
        records=[]
        for item in ITEMS:
            print('interact',item['id'],item['test'],flush=True)
            records.append(run_one(browser,item,evidence_dir))
        browser.close()
    doc={"capture_date":"2026-11-08","tool":"Python Playwright with Chromium 156.0.8078.73","conditions":{"headless":True,"viewport":"1440×900 CSS px","reduced_motion":"no-preference except the Futuristic Dark canvas test, which uses reduce","wait":"DOMContentLoaded + preview iframe stabilization + 1s before interaction","actions":"one reversible action per template, except pause/resume and FAQ open/close; no submissions or external navigation"},"records":records,"limitations":["The behaviors are observed in public sandboxed template previews, not published generated sites.","A DOM state change or screenshot difference is not a direct measurement of compositor FPS or GPU cost.","No formal performance trace, Lighthouse run, or real-device test is included in this interaction pass."]}
    out=Path(a.output); out.parent.mkdir(parents=True,exist_ok=True); out.write_text(json.dumps(doc,indent=2,ensure_ascii=False)+'\n'); print('wrote',out,out.stat().st_size,'bytes')
if __name__=='__main__': main()
