#!/usr/bin/env python3
"""Localized App Store screenshots for Baby Light — iPhone 6.5" (1284x2778).

Renders the 6-creative set per locale with translated captions and translated
in-app control-panel labels, choosing a font that covers each locale's script
(Latin/Cyrillic -> Avenir Next, CJK -> Hiragino/Songti, KO -> Apple SD Gothic,
AR -> Geeza Pro with reshaping + bidi).

Output: AppStore/screenshots/loc/<asc-locale>/01..06.png
"""
import json, os, sys
from PIL import Image, ImageDraw, ImageFont, ImageFilter
import numpy as np
import arabic_reshaper
from bidi.algorithm import get_display

HERE = os.path.dirname(__file__)
REPO = os.path.abspath(os.path.join(HERE, "..", ".."))
TR = json.load(open(os.path.join(HERE, "translations.json"), encoding="utf-8"))
OUTROOT = os.path.join(REPO, "AppStore", "screenshots", "loc")
ICON = os.path.join(REPO, "Baby Light", "Assets.xcassets", "AppIcon.appiconset", "AppIcon.png")

W, H = 1284, 2778

INDIGO     = (23, 13, 47)
INDIGO_TOP = (38, 22, 74)
CORAL      = (244, 106, 95)
WHITE      = (255, 255, 255)
MUTE       = (190, 182, 210)
RED    = (255, 0, 0)
AMBER  = (255, 69, 0)
CANDLE = (255, 140, 0)
WARM   = (245, 222, 179)

AVENIR = "/System/Library/Fonts/Avenir Next.ttc"
HIRA   = "/System/Library/Fonts/Hiragino Sans GB.ttc"
SONGTI = "/System/Library/Fonts/Supplemental/Songti.ttc"
SDGOTH = "/System/Library/Fonts/AppleSDGothicNeo.ttc"
GEEZA  = "/System/Library/Fonts/GeezaPro.ttc"

# script -> (file, idx) for roles: head, sub, body, label(bold-ish), title
FONTS = {
    "latin":    {"file": AVENIR, "head": 8, "sub": 5, "body": 5, "label": 2, "title": 0, "cjk": False, "rtl": False},
    "cyrillic": {"file": AVENIR, "head": 8, "sub": 5, "body": 5, "label": 2, "title": 0, "cjk": False, "rtl": False},
    "cjk_sc":   {"file": HIRA,   "head": 2, "sub": 0, "body": 0, "label": 2, "title": 2, "cjk": True,  "rtl": False},
    "ja":       {"file": HIRA,   "head": 2, "sub": 0, "body": 0, "label": 2, "title": 2, "cjk": True,  "rtl": False},
    "cjk_tc":   {"file": SONGTI, "head": 2, "sub": 5, "body": 7, "label": 2, "title": 2, "cjk": True,  "rtl": False},
    "ko":       {"file": SDGOTH, "head": 6, "sub": 2, "body": 2, "label": 4, "title": 6, "cjk": True,  "rtl": False},
    "ar":       {"file": GEEZA,  "head": 1, "sub": 0, "body": 0, "label": 1, "title": 1, "cjk": False, "rtl": True},
}
LOCALE_SCRIPT = {
    "zh-Hans": "cjk_sc", "zh-Hant": "cjk_tc", "ja": "ja", "ko": "ko", "ru": "cyrillic",
    "de-DE": "latin", "fr-FR": "latin", "es-ES": "latin", "es-MX": "latin", "it": "latin",
    "pt-BR": "latin", "nl-NL": "latin", "tr": "latin", "pl": "latin", "ar-SA": "ar",
}

_cache = {}
def font(spec, role, size):
    key = (spec["file"], spec[role], size)
    if key not in _cache:
        _cache[key] = ImageFont.truetype(spec["file"], size, index=spec[role])
    return _cache[key]

def shape(s, rtl):
    if not rtl:
        return s
    return get_display(arabic_reshaper.reshape(s))

# ---------- drawing helpers ----------
def vgradient(top, bottom):
    base = Image.new("RGB", (W, H), bottom)
    top_img = Image.new("RGB", (W, H), top)
    mask = Image.new("L", (1, H))
    for y in range(H):
        mask.putpixel((0, y), int(255 * (1 - y / H) ** 1.3))
    base.paste(top_img, (0, 0), mask.resize((W, H)))
    return base

def screen_blend(a, b):
    aa = np.asarray(a).astype(np.float32); bb = np.asarray(b).astype(np.float32)
    return Image.fromarray((255 - (255-aa)*(255-bb)/255).clip(0,255).astype('uint8'))

def base_bg(glow_color, glow_xy, glow_r):
    img = vgradient(INDIGO_TOP, INDIGO)
    glow = Image.new("RGB", (W, H), (0,0,0)); gd = ImageDraw.Draw(glow)
    cx, cy = glow_xy
    for i in range(60, 0, -1):
        r = int(glow_r * i / 60); a = (i/60)**2
        gd.ellipse([cx-r, cy-r, cx+r, cy+r], fill=tuple(int(c*a) for c in glow_color))
    glow = glow.filter(ImageFilter.GaussianBlur(110))
    return screen_blend(img, glow)

def lightened(rgb, amount):
    return tuple(min(255, int(c + amount*255)) for c in rgb)

def wrap(d, text, fnt, max_w, cjk):
    if cjk:
        lines, cur = [], ""
        for ch in text:
            if ch == "\n":
                lines.append(cur); cur = ""; continue
            t = cur + ch
            if d.textlength(t, font=fnt) <= max_w or not cur:
                cur = t
            else:
                lines.append(cur); cur = ch
        if cur: lines.append(cur)
        return lines
    out = []
    for para in text.split("\n"):
        words = para.split(); cur = ""
        for w in words:
            t = (cur + " " + w).strip()
            if d.textlength(t, font=fnt) <= max_w or not cur:
                cur = t
            else:
                out.append(cur); cur = w
        out.append(cur)
    return out

def center_lines(d, cx, y, text, fnt, fill, max_w, rtl, cjk, gap=14):
    for ln in wrap(d, text, fnt, max_w, cjk):
        s = shape(ln, rtl)
        bb = d.textbbox((0,0), s, font=fnt)
        tw = bb[2]-bb[0]; th = bb[3]-bb[1]
        d.text((cx - tw/2 - bb[0], y - bb[1]), s, font=fnt, fill=fill)
        y += th + gap
    return y

def rounded(d, box, r, **kw):
    d.rounded_rectangle(box, radius=r, **kw)

# ---------- phone mock ----------
def phone(screen_img):
    sw, sh = screen_img.size
    bez, radius = 24, 130
    dw, dh = sw+bez*2, sh+bez*2
    dev = Image.new("RGBA",(dw,dh),(0,0,0,0)); dd = ImageDraw.Draw(dev)
    rounded(dd,[0,0,dw,dh],radius+bez,fill=(18,18,22,255))
    rounded(dd,[2,2,dw-2,dh-2],radius+bez-2,outline=(70,70,80,255),width=3)
    mask = Image.new("L",(sw,sh),0); ImageDraw.Draw(mask).rounded_rectangle([0,0,sw,sh],radius=radius,fill=255)
    dev.paste(screen_img.convert("RGB"),(bez,bez),mask)
    iw,ih = 210,58
    rounded(dd,[(dw-iw)//2,bez+28,(dw+iw)//2,bez+28+ih],ih//2,fill=(0,0,0,255))
    return dev

def place(img, dev, cx, cy):
    pw,ph = dev.size
    img = img.convert("RGBA")
    img.alpha_composite(dev,(int(cx-pw/2),int(cy-ph/2)))
    return img.convert("RGB")

SW, SH = 720, 1556  # phone screen content size

def screen_fullscreen(color, timer):
    sc = Image.new("RGB",(SW,SH),color); d = ImageDraw.Draw(sc)
    ft = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial Rounded Bold.ttf", 140)
    tcol = lightened(color, 0.20)
    tw = d.textlength(timer, font=ft)
    d.text((SW/2-tw/2, SH*0.45), timer, font=ft, fill=tcol)
    return sc

def screen_controls(spec, ui, bg, highlight):
    rtl = spec["rtl"]
    sc = Image.new("RGBA",(SW,SH),bg+(255,)); d = ImageDraw.Draw(sc)
    ftimer = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial Rounded Bold.ttf", 120)
    tcol = lightened(bg,0.10); tw = d.textlength("0:42",font=ftimer)
    d.text((SW/2-tw/2, SH*0.36), "0:42", font=ftimer, fill=tcol)
    pw, ph = int(SW*0.90), int(SH*0.80)
    px, py = (SW-pw)//2, int(SH*0.085)
    panel = Image.new("RGBA",(SW,SH),(0,0,0,0))
    ImageDraw.Draw(panel).rounded_rectangle([px,py,px+pw,py+ph],radius=42,fill=(0,0,0,150))
    sc = Image.alpha_composite(sc, panel); d = ImageDraw.Draw(sc)
    cx = SW//2; lx = px+44; rx = px+pw-44; y = py+44
    F_TITLE = font(spec,"title",46); F_LABEL = font(spec,"label",27)
    F_BODY = font(spec,"body",28); F_PILL = font(spec,"body",30); F_TINY = font(spec,"body",24)
    def ctext(s, yy, fnt, fill):
        ss = shape(s, rtl); w = d.textlength(ss,font=fnt)
        d.text((cx-w/2, yy), ss, font=fnt, fill=fill);
    def hl(name): return CORAL if highlight==name else (214,210,224)
    ctext("Baby Light", y, F_TITLE, WHITE); y += 92
    ctext(ui["light_color"], y, F_LABEL, hl("color")); y += 60
    swatches=[RED,AMBER,CANDLE,WARM]; sel=swatches.index(bg) if bg in swatches else 0
    n=4; r=42; gap=36; total=n*2*r+(n-1)*gap; sx=cx-total/2+r; cyc=y+r
    for i,c in enumerate(swatches):
        ccx=sx+i*(2*r+gap)
        d.ellipse([ccx-r,cyc-r,ccx+r,cyc+r],fill=c,outline=WHITE,width=4)
        if i==sel:
            d.ellipse([ccx-8,cyc-8,ccx+8,cyc+8],fill=(60,40,0) if c==WARM else WHITE)
    y=cyc+r+22; ctext(ui["desc_best_sleep"], y, F_TINY, (210,188,188)); y+=70
    ctext(ui["auto_off_timer"], y, F_LABEL, hl("timer")); y+=58
    pills=["∞","15m","30m","1h","2h"]; selp=2 if highlight=="timer" else -1
    widths=[max(86,d.textlength(p,font=F_PILL)+46) for p in pills]; tot=sum(widths)+16*4; xx=cx-tot/2
    for i,p in enumerate(pills):
        w=widths[i]; on=(i==selp)
        if on: d.rounded_rectangle([xx,y,xx+w,y+62],radius=31,fill=WHITE)
        else: d.rounded_rectangle([xx,y,xx+w,y+62],radius=31,outline=(255,255,255,90),width=2)
        pw2=d.textlength(p,font=F_PILL); d.text((xx+w/2-pw2/2,y+13),p,font=F_PILL,fill=(0,0,0) if on else WHITE)
        xx+=w+16
    y+=62+58
    # toggles
    def toggle(label_s, yy, on=True):
        s = shape(label_s, rtl); tw_=92; th=50
        if rtl:
            d.text((rx-d.textlength(s,font=F_BODY), yy), s, font=F_BODY, fill=WHITE)
            tx=lx
        else:
            d.text((lx, yy), s, font=F_BODY, fill=WHITE); tx=rx-tw_
        d.rounded_rectangle([tx,yy-2,tx+tw_,yy-2+th],radius=th//2,fill=CORAL if on else (90,90,100))
        knob=th-12; kx=tx+tw_-knob-6 if on else tx+6
        d.ellipse([kx,yy-2+6,kx+knob,yy-2+6+knob],fill=WHITE)
    ctext(ui["auto_brightness"], y, F_LABEL, hl("bright")); y+=56
    toggle(ui["max_bright_open"], y); y+=78
    toggle(ui["dim_close"], y); y+=92
    ctext(ui["elapsed_timer"], y, F_LABEL, (214,210,224)); y+=54
    hint = ui.get("hint_short") or ui.get("hint")
    ctext(hint, y, F_TINY, (160,160,172))
    return sc.convert("RGB")

def page_dots(img, idx, total=6):
    d = ImageDraw.Draw(img); r=8; gap=30; tw=total*2*r+(total-1)*gap
    x=W/2-tw/2+r; yy=H-66
    for i in range(total):
        d.ellipse([x-r,yy-r,x+r,yy+r],fill=CORAL if i==idx else (90,80,110)); x+=2*r+gap
    return img

def header(img, spec, headline, sub):
    d = ImageDraw.Draw(img)
    cjk = spec["cjk"]; rtl = spec["rtl"]
    hsz = 96 if cjk else (100 if spec["file"] in (SDGOTH,GEEZA) else 104)
    fh = font(spec,"head",hsz); fs = font(spec,"sub",46)
    y = center_lines(d, W/2, 150, headline, fh, WHITE, W-150, rtl, cjk, gap=8)
    y += 30
    center_lines(d, W/2, y, sub, fs, MUTE, W-200, rtl, cjk, gap=12)

def tagline_icon(img, spec, tagline):
    cy = int(H*0.55); sz = 430
    try:
        icon = Image.open(ICON).convert("RGB").resize((sz,sz), Image.LANCZOS)
        glow = Image.new("RGB",(W,H),(0,0,0)); gd=ImageDraw.Draw(glow); gr=int(sz*0.85)
        for i in range(40,0,-1):
            r=int(gr*i/40); a=(i/40)**2
            gd.ellipse([W/2-r,cy-r,W/2+r,cy+r],fill=tuple(int(c*a) for c in (150,40,40)))
        img = screen_blend(img, glow.filter(ImageFilter.GaussianBlur(70)))
        m=Image.new("L",(sz,sz),0); ImageDraw.Draw(m).rounded_rectangle([0,0,sz,sz],radius=int(sz*0.225),fill=255)
        img=img.convert("RGBA"); img.paste(icon,(W//2-sz//2,cy-sz//2),m); img=img.convert("RGB")
    except Exception as e:
        print("icon err", e)
    d=ImageDraw.Draw(img)
    center_lines(d, W/2, cy+sz//2+64, tagline, font(spec,"title",46), WHITE, W-160, spec["rtl"], spec["cjk"])
    return img

def spectrum(img, spec, line):
    d = ImageDraw.Draw(img)
    center_lines(d, W/2, int(H*0.20), line, font(spec,"body",34), (208,200,222), W-220, spec["rtl"], spec["cjk"], gap=12)
    bx0,bx1 = 120,W-120; by=int(H*0.40); bh=78
    cols=[(150,40,220),(40,80,255),(0,200,255),(0,220,120),(255,230,0),(255,140,0),(255,0,0)]
    grad=Image.new("RGB",(len(cols),1))
    for i,c in enumerate(cols): grad.putpixel((i,0),c)
    grad=grad.resize((bx1-bx0,bh))
    gm=Image.new("L",(bx1-bx0,bh),0); ImageDraw.Draw(gm).rounded_rectangle([0,0,bx1-bx0,bh],radius=bh//2,fill=255)
    img.paste(grad,(bx0,by),gm)
    return img

# ---------- compose 6 creatives ----------
def build_locale(asc):
    spec = FONTS[LOCALE_SCRIPT[asc]]
    data = TR[asc]; caps = data["captions"]; ui = data["ui"]
    outdir = os.path.join(OUTROOT, asc); os.makedirs(outdir, exist_ok=True)

    def hero(color, timer, cap_i, glow):
        img = base_bg(glow, (W/2, H*0.66), 1050)
        header(img, spec, caps[cap_i][0], caps[cap_i][1])
        img = place(img, phone(screen_fullscreen(color, timer)), W/2, H*0.66)
        return img

    # 1 hero red
    s1 = page_dots(hero(RED, "0:42", 0, (150,20,20)), 0)
    s1.save(os.path.join(outdir,"01_hero_red.png"))
    # 2 science / spectrum
    img = base_bg((120,30,20),(W/2,H*0.66),900)
    header(img, spec, caps[1][0], caps[1][1])
    img = spectrum(img, spec, caps[1][1])
    s2 = page_dots(img, 1); s2.save(os.path.join(outdir,"02_science.png"))
    # 3 colors (controls)
    img = base_bg((120,30,20),(W/2,H*0.66),950)
    header(img, spec, caps[2][0], caps[2][1])
    img = place(img, phone(screen_controls(spec, ui, RED, "color")), W/2, H*0.665)
    s3 = page_dots(img, 2); s3.save(os.path.join(outdir,"03_colors.png"))
    # 4 timer (controls)
    img = base_bg((150,80,10),(W/2,H*0.66),950)
    header(img, spec, caps[3][0], caps[3][1])
    img = place(img, phone(screen_controls(spec, ui, CANDLE, "timer")), W/2, H*0.665)
    s4 = page_dots(img, 3); s4.save(os.path.join(outdir,"04_timer.png"))
    # 5 hero amber
    s5 = page_dots(hero(AMBER, "1:07", 4, (120,60,10)), 4)
    s5.save(os.path.join(outdir,"05_brightness.png"))
    # 6 closing icon
    img = base_bg((120,30,20),(W/2,H*0.56),1000)
    header(img, spec, caps[5][0], caps[5][1])
    img = tagline_icon(img, spec, ui.get("desc_best_sleep") and caps[5][1] or caps[5][1])
    s6 = page_dots(img, 5); s6.save(os.path.join(outdir,"06_closing.png"))
    print("built", asc, "->", outdir)

if __name__ == "__main__":
    locs = sys.argv[1:] or list(LOCALE_SCRIPT.keys())
    for a in locs:
        build_locale(a)
    print("done")
