#!/usr/bin/env python3
"""Bounded, public-only Phase 1C validation for three unresolved preview behaviors.
No authentication, publication, form submission, private endpoint, or source mutation.
"""
from __future__ import annotations
import argparse, hashlib, json, time
from datetime import datetime, timezone
from pathlib import Path
from playwright.sync_api import sync_playwright

BASE = "https://htmlhost.co/templates/"
URLS = {
    "portfolio": BASE + "full-stack-designer-portfolio#preview",
    "futuristic-dark": BASE + "futuristic-dark-landing#preview",
    "business": BASE + "business-web-studio#preview",
}


def iso_now():
    return datetime.now(timezone.utc).isoformat()


def choose_frame(page):
    choices = []
    for i, el in enumerate(page.locator("iframe").all()):
        try:
            if not el.is_visible():
                continue
            box = el.bounding_box()
            handle = el.element_handle()
            frame = handle.content_frame() if handle else None
            if box and frame:
                choices.append((box["width"] * box["height"], i, box, frame))
        except Exception:
            pass
    return max(choices, key=lambda x: x[0]) if choices else None


def state(locator):
    return locator.evaluate("""e => {
      const r=e.getBoundingClientRect(), s=getComputedStyle(e);
      return {tag:e.tagName, id:e.id||null, className:String(e.className||'').slice(0,240),
        text:(e.innerText||'').trim().replace(/\\s+/g,' ').slice(0,220),
        ariaExpanded:e.getAttribute('aria-expanded'), ariaControls:e.getAttribute('aria-controls'),
        ariaPressed:e.getAttribute('aria-pressed'), ariaLabel:e.getAttribute('aria-label'),
        role:e.getAttribute('role'), tabIndex:e.tabIndex,
        rect:{x:r.x,y:r.y,width:r.width,height:r.height}, opacity:s.opacity,
        transform:s.transform, transitionProperty:s.transitionProperty,
        transitionDuration:s.transitionDuration, transitionTimingFunction:s.transitionTimingFunction,
        gridTemplateRows:s.gridTemplateRows, visibility:s.visibility, display:s.display};
    }""")


def slide_state(frame):
    return frame.locator("#testimonial-slider .testimonial-slide").evaluate_all("""els => els.map((e,i) => {
      const r=e.getBoundingClientRect(), s=getComputedStyle(e);
      return {index:i, id:e.id||null, className:e.className, text:(e.innerText||'').trim().replace(/\\s+/g,' ').slice(0,180),
        opacity:s.opacity, transform:s.transform, display:s.display, rect:{x:r.x,y:r.y,width:r.width,height:r.height}};
    })""")


def active_slides(items):
    return [x for x in items if "active" in x["className"].split() or (x["opacity"] == "1" and x["display"] != "none")]


def new_page(browser, motion):
    context = browser.new_context(viewport={"width":1440,"height":900}, device_scale_factor=1,
                                   reduced_motion=motion, locale="en-US")
    page = context.new_page(); page.set_default_timeout(15000)
    errors=[]; failed=[]
    page.on("pageerror", lambda e: errors.append(str(e)[:500]))
    page.on("console", lambda m: errors.append("console:"+m.type+":"+m.text[:400]) if m.type=="error" else None)
    page.on("requestfailed", lambda r: failed.append({"url":r.url.split('?')[0],"failure":r.failure}))
    return context, page, errors, failed


def ready(page, url):
    resp = page.goto(url, wait_until="domcontentloaded", timeout=45000)
    page.wait_for_function("document.querySelectorAll('iframe').length >= 3", timeout=15000)
    page.wait_for_timeout(1000)
    chosen = choose_frame(page)
    if not chosen:
        raise RuntimeError("No visible preview iframe")
    _, index, box, frame = chosen
    frame.locator("body").wait_for(state="visible", timeout=10000)
    return resp.status if resp else None, {"index":index,"box":box}, frame


def portfolio(browser, repetitions, output):
    records=[]
    for motion in ("no-preference", "reduce"):
        context, page, errors, failed = new_page(browser, motion)
        rec={"target":"full-stack-portfolio", "url":URLS["portfolio"], "motion":motion,
             "started_at":iso_now(), "repetitions":[], "http_status":None}
        try:
            rec["http_status"], rec["iframe"], frame = ready(page, URLS["portfolio"])
            button=frame.locator('button[aria-label="Next testimonial"]')
            if button.count()!=1: raise RuntimeError(f"Expected one Next button, found {button.count()}")
            for n in range(1, repetitions+1):
                before_time=performance_time(page)
                before=slide_state(frame)
                button_state=state(button)
                clicked_at=iso_now(); button.click()
                time.sleep(0.9)
                during=slide_state(frame)
                time.sleep(0.7)
                after=slide_state(frame)
                rec["repetitions"].append({"repetition":n,"before_timestamp_ms":before_time,
                    "clicked_at":clicked_at,"after_timestamp":iso_now(),
                    "button_before":button_state,"before":before,"during_0_9s":during,
                    "after_settled":after,"active_before":active_slides(before),
                    "active_after":active_slides(after)})
                # Reset to a stable starting point by reloading; this avoids assuming slide order.
                if n < repetitions:
                    page.reload(wait_until="domcontentloaded", timeout=45000)
                    page.wait_for_function("document.querySelectorAll('iframe').length >= 3", timeout=15000)
                    page.wait_for_timeout(1000)
                    chosen=choose_frame(page)
                    frame=chosen[3]
                    frame.locator("body").wait_for(state="visible", timeout=10000)
                    button=frame.locator('button[aria-label="Next testimonial"]')
            rec["result"]="completed"
        except Exception as e:
            rec["result"]="failed"
            rec["error"]=type(e).__name__+": "+str(e)[:700]
        rec["page_errors"]=errors[:30]; rec["request_failures"]=failed[:30]; rec["finished_at"]=iso_now()
        records.append(rec); context.close()
    output["portfolio"]=records


def performance_time(page):
    try: return page.evaluate("performance.now()")
    except Exception: return None


def canvas_contexts(frame, canvas):
    return canvas.evaluate("""c => {
      const out={width:c.width,height:c.height};
      for (const kind of ['webgl2','webgl','experimental-webgl','2d']) {
        try { const x=c.getContext(kind); out[kind]=!!x; if (x && kind !== '2d') out[kind+'_renderer']=String(x.getParameter(x.RENDERER)||''); }
        catch(e){ out[kind]='error:'+String(e).slice(0,160); }
      }
      return out;
    }""")


def futuristic(browser, output_dir, out):
    records=[]
    for motion in ("no-preference", "reduce"):
        context, page, errors, failed = new_page(browser, motion)
        rec={"target":"futuristic-dark", "url":URLS["futuristic-dark"], "motion":motion,
             "started_at":iso_now(), "http_status":None}
        try:
            rec["http_status"], rec["iframe"], frame=ready(page, URLS["futuristic-dark"])
            canvas=frame.locator("canvas").first
            if canvas.count()!=1: raise RuntimeError(f"Expected one canvas, found {canvas.count()}")
            rec["canvas_before"]=state(canvas); rec["contexts"]=canvas_contexts(frame, canvas)
            rec["raf_probe"]=frame.evaluate("""async () => { const t=performance.now(); let n=0, last=null;
              await new Promise(resolve => { const f=x => {n++; last=x; if (x-t<1000) requestAnimationFrame(f); else resolve();}; requestAnimationFrame(f); });
              return {callbacks:n, duration_ms:last-t}; }""")
            rec["event_probe"]=frame.evaluate("""() => { const c=document.querySelector('canvas'); window.__phase1cEvents=[];
              const add=(where,e)=>window.__phase1cEvents.push({where,eventType:e.type,target:e.target?.tagName||null,current:e.currentTarget?.tagName||null,x:e.clientX,y:e.clientY});
              for (const [where,el] of [['canvas',c],['body',document.body],['window',window]]) for (const t of ['pointermove','mousemove','touchmove']) el.addEventListener(t,e=>add(where,e),{capture:true,passive:true});
              return {armed:!!c}; }""")
            box=canvas.bounding_box();
            if not box: raise RuntimeError("Canvas has no bounding box")
            before=output_dir/f"futuristic-dark-{motion}-before.png"; canvas.screenshot(path=str(before))
            page.mouse.move(box['x']+box['width']*.25,box['y']+box['height']*.30,steps=12)
            page.wait_for_timeout(650)
            after=output_dir/f"futuristic-dark-{motion}-after-pointer.png"; canvas.screenshot(path=str(after))
            rec["event_log"]=frame.evaluate("""() => ({count:(window.__phase1cEvents||[]).length, events:(window.__phase1cEvents||[]).slice(0,100)})""")
            rec["canvas_after"]=state(canvas)
            rec["screenshots"]={"before":str(before),"after_pointer":str(after),
                "sha256":{str(before.name):hashlib.sha256(before.read_bytes()).hexdigest(),str(after.name):hashlib.sha256(after.read_bytes()).hexdigest()}}
            rec["result"]="completed"
        except Exception as e:
            rec["result"]="failed"; rec["error"]=type(e).__name__+": "+str(e)[:700]
        rec["page_errors"]=errors[:30]; rec["request_failures"]=failed[:30]; rec["finished_at"]=iso_now()
        records.append(rec); context.close()
    out["futuristic_dark"]=records


def business(browser, repetitions, output):
    records=[]
    for motion in ("no-preference", "reduce"):
        context, page, errors, failed = new_page(browser, motion)
        rec={"target":"business-web-studio", "url":URLS["business"], "motion":motion,
             "started_at":iso_now(), "repetitions":[], "http_status":None}
        try:
            rec["http_status"], rec["iframe"], frame=ready(page, URLS["business"])
            button=frame.get_by_role("button", name="How long does a website take?")
            if button.count()!=1: raise RuntimeError(f"Expected one FAQ button, found {button.count()}")
            aria_controls=button.get_attribute("aria-controls")
            if not aria_controls: raise RuntimeError("FAQ button has no aria-controls")
            panel=frame.locator("#"+aria_controls)
            for n in range(1, repetitions+1):
                before=state(button); panel_before=state(panel)
                # keyboard open on odd repetitions, click close/open on even repetitions.
                method="keyboard" if n%2 else "click"
                if method=="keyboard": button.focus(); button.press("Enter")
                else: button.click()
                during=state(panel); button_open=state(button); time.sleep(0.8); settled_open=state(panel)
                if method=="keyboard": button.focus(); button.press("Space")
                else: button.click()
                closing=state(panel); button_closed=state(button); time.sleep(0.8); settled_closed=state(panel)
                rec["repetitions"].append({"repetition":n,"method":method,"before":before,
                    "panel_before":panel_before,"open_immediate":{"button":button_open,"panel":during},
                    "open_settled":settled_open,"close_immediate":{"button":button_closed,"panel":closing},
                    "close_settled":settled_closed,"timestamp":iso_now()})
            rec["association"]={"button_aria_controls":aria_controls,"panel_id":panel.get_attribute("id"),
                                 "panel_role":panel.get_attribute("role"),"button_tag":button.evaluate("e=>e.tagName")}
            rec["result"]="completed"
        except Exception as e:
            rec["result"]="failed"; rec["error"]=type(e).__name__+": "+str(e)[:700]
        rec["page_errors"]=errors[:30]; rec["request_failures"]=failed[:30]; rec["finished_at"]=iso_now()
        records.append(rec); context.close()
    output["business"]=records


def main():
    ap=argparse.ArgumentParser(); ap.add_argument("--output", required=True); ap.add_argument("--evidence-dir", required=True); ap.add_argument("--repetitions", type=int, default=5)
    args=ap.parse_args(); out_dir=Path(args.evidence_dir); out_dir.mkdir(parents=True, exist_ok=True)
    out={"capture_date":datetime.now(timezone.utc).date().isoformat(),"tool":"Python Playwright with /usr/bin/chromium",
         "chromium":"156.0.8078.73","scope":"Public sandboxed preview iframes only; no published customer site",
         "conditions":{"viewport":"1440x900","fresh_context_per_motion_cell":True,"portfolio_repetitions":args.repetitions,"business_repetitions":args.repetitions,
                      "settle_wait_ms":800,"classification":"Raw observation; interpretation belongs in report"}}
    with sync_playwright() as p:
        browser=p.chromium.launch(executable_path="/usr/bin/chromium", headless=True, args=["--no-sandbox"])
        print("portfolio", flush=True); portfolio(browser,args.repetitions,out)
        print("futuristic-dark", flush=True); futuristic(browser,out_dir,out)
        print("business", flush=True); business(browser,args.repetitions,out)
        browser.close()
    path=Path(args.output); path.parent.mkdir(parents=True,exist_ok=True); path.write_text(json.dumps(out,indent=2,ensure_ascii=False)+"\n"); print(f"wrote {path} ({path.stat().st_size} bytes)")

if __name__ == "__main__": main()
