#!/usr/bin/env python3
"""
Generate App Store marketing screenshots for Baby Light at 1320x2868
(iPhone 6.9" — the size Apple wants you to lead with; auto-scales to smaller iPhones).

Design language is pulled straight from the app + icon:
  - brand indigo background  #170D2F  (sampled from the app icon)
  - coral accent             #F46A5F  (the icon line-art color)
  - app light colors         red #FF0000, amber #FF4500, candle #FF8C00, warm #F5DEB3
  - SF-style rounded numerals (Arial Rounded Bold substitute)

Each creative = branded gradient backdrop + headline/subhead + a faithful, rounded
"phone" mock of the actual app screen. The phone screens are recreated 1:1 from the
SwiftUI source (ContentView / ControlsOverlay) and cross-checked against the real
simulator captures in AppStore/raw/.
"""
import math, os
from PIL import Image, ImageDraw, ImageFont, ImageFilter

W, H = 1320, 2868
OUT = os.path.join(os.path.dirname(__file__), "screenshots")
os.makedirs(OUT, exist_ok=True)

# ---- palette ---------------------------------------------------------------
INDIGO      = (23, 13, 47)      # #170D2F brand bg
INDIGO_TOP  = (38, 22, 74)      # lighter top of gradient
CORAL       = (244, 106, 95)    # #F46A5F accent
WHITE       = (255, 255, 255)
MUTE        = (190, 182, 210)   # muted lavender text

RED    = (255, 0, 0)            # #FF0000 deep red
AMBER  = (255, 69, 0)           # #FF4500
CANDLE = (255, 140, 0)          # #FF8C00
WARM   = (245, 222, 179)        # #F5DEB3 wheat

# ---- fonts -----------------------------------------------------------------
ROUND = "/System/Library/Fonts/Supplemental/Arial Rounded Bold.ttf"
AVENIR = "/System/Library/Fonts/Avenir Next.ttc"
HELV  = "/System/Library/Fonts/HelveticaNeue.ttc"

def f(path, size, index=0):
    return ImageFont.truetype(path, size, index=index)

# Avenir Next face indices: 0 Bold, 2 Demi Bold, 5 Medium, 7 Regular, 8 Heavy
F_HEAD   = f(AVENIR, 116, index=8)   # Heavy headline
F_HEAD2  = f(AVENIR, 104, index=8)
F_SUB    = f(AVENIR, 52,  index=5)   # Medium subhead
F_TIMER  = f(ROUND, 150)             # rounded numerals
F_TIMER_BIG = f(ROUND, 200)
F_PANEL_TITLE = f(AVENIR, 58, index=0)  # Bold
F_LABEL  = f(AVENIR, 30, index=2)    # Demi Bold small-caps label
F_BODY   = f(AVENIR, 34, index=5)    # Medium
F_PILL   = f(AVENIR, 34, index=2)    # Demi Bold
F_TINY   = f(AVENIR, 27, index=5)    # Medium
F_SPEC   = f(ROUND, 40)

def lightened(rgb, amount):
    return tuple(min(255, int(c + amount * 255)) for c in rgb)

# ---- helpers ---------------------------------------------------------------
def vgradient(top, bottom):
    base = Image.new("RGB", (W, H), bottom)
    top_img = Image.new("RGB", (W, H), top)
    mask = Image.new("L", (1, H))
    for y in range(H):
        mask.putpixel((0, y), int(255 * (1 - y / H) ** 1.3))
    mask = mask.resize((W, H))
    base.paste(top_img, (0, 0), mask)
    return base

def radial_glow(img, cx, cy, radius, color, strength=0.55):
    """Soft radial glow centered at (cx,cy)."""
    glow = Image.new("RGB", (W, H), (0, 0, 0))
    gd = ImageDraw.Draw(glow)
    steps = 60
    for i in range(steps, 0, -1):
        r = int(radius * i / steps)
        a = int(255 * (i / steps) ** 2 * strength)
        gd.ellipse([cx - r, cy - r, cx + r, cy + r], fill=tuple(int(c * a / 255) for c in color))
    glow = glow.filter(ImageFilter.GaussianBlur(80))
    return Image.blend(img, Image.composite(Image.new("RGB",(W,H),color), img, glow.convert("L")) if False else img, 0) or _screen(img, glow)

def _screen(base, top):
    """Screen blend (lighten) base with top."""
    import numpy as np  # noqa
    return None

def draw_center_text(d, cx, y, text, font, fill, max_w=None, line_gap=14, anchor_top=True):
    lines = wrap(d, text, font, max_w) if max_w else [text]
    cur = y
    for ln in lines:
        bb = d.textbbox((0, 0), ln, font=font)
        tw = bb[2] - bb[0]; th = bb[3] - bb[1]
        d.text((cx - tw / 2, cur - bb[1]), ln, font=font, fill=fill)
        cur += th + line_gap
    return cur

def wrap(d, text, font, max_w):
    words = text.split()
    lines, cur = [], ""
    for w in words:
        test = (cur + " " + w).strip()
        if d.textbbox((0, 0), test, font=font)[2] <= max_w:
            cur = test
        else:
            if cur: lines.append(cur)
            cur = w
    if cur: lines.append(cur)
    return lines

def rounded(d, box, r, fill=None, outline=None, width=1):
    d.rounded_rectangle(box, radius=r, fill=fill, outline=outline, width=width)

# ---- phone mock ------------------------------------------------------------
def phone_screen(content_fn, scale=1.0):
    """Return an RGBA image of a phone (bezel + screen) with content drawn by
    content_fn(draw, sx, sy, sw, sh) onto the *screen* area."""
    # device proportions ~ 6.9" (19.5:9)
    sw, sh = 760, 1646
    bez = 26
    radius = 150
    dw, dh = sw + bez * 2, sh + bez * 2
    dev = Image.new("RGBA", (dw, dh), (0, 0, 0, 0))
    dd = ImageDraw.Draw(dev)
    # titanium bezel
    rounded(dd, [0, 0, dw, dh], radius + bez, fill=(18, 18, 22, 255))
    rounded(dd, [2, 2, dw - 2, dh - 2], radius + bez - 2, outline=(70, 70, 80, 255), width=3)
    # screen
    screen = Image.new("RGB", (sw, sh), (0, 0, 0))
    sd = ImageDraw.Draw(screen)
    content_fn(sd, 0, 0, sw, sh)
    # round the screen corners
    mask = Image.new("L", (sw, sh), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, sw, sh], radius=radius, fill=255)
    dev.paste(screen, (bez, bez), mask)
    # dynamic island
    isl_w, isl_h = 230, 64
    rounded(dd, [(dw - isl_w) // 2, bez + 30, (dw + isl_w) // 2, bez + 30 + isl_h],
            isl_h // 2, fill=(0, 0, 0, 255))
    if scale != 1.0:
        dev = dev.resize((int(dw * scale), int(dh * scale)), Image.LANCZOS)
    return dev

# ---- content renderers (faithful to SwiftUI source) -----------------------
def content_fullscreen(color, timer_text="0:42"):
    def fn(sd, sx, sy, sw, sh):
        sd.rectangle([sx, sy, sx + sw, sy + sh], fill=color)
        tcol = lightened(color, 0.20)
        bb = sd.textbbox((0, 0), timer_text, font=F_TIMER)
        tw = bb[2] - bb[0]
        sd.text((sx + sw / 2 - tw / 2, sy + sh * 0.46), timer_text, font=F_TIMER, fill=tcol)
    return fn

def content_controls(bg=RED, highlight=None):
    """Recreate ControlsOverlay over a colored background."""
    def fn(sd, sx, sy, sw, sh):
        sd.rectangle([sx, sy, sx + sw, sy + sh], fill=bg)
        # faint elapsed timer behind panel
        tcol = lightened(bg, 0.12)
        bb = sd.textbbox((0, 0), "0:42", font=F_TIMER)
        sd.text((sx + sw/2 - (bb[2]-bb[0])/2, sy + sh*0.42), "0:42", font=F_TIMER, fill=tcol)
        # panel
        pw = int(sw * 0.86); ph = int(sh * 0.74)
        px = sx + (sw - pw) // 2; py = sy + int(sh * 0.12)
        panel = Image.new("RGBA", (pw, ph), (0, 0, 0, 150))
        pmask = Image.new("L", (pw, ph), 0)
        ImageDraw.Draw(pmask).rounded_rectangle([0, 0, pw, ph], radius=44, fill=255)
        # composite manually via paste with alpha onto a temp
        base = Image.new("RGBA", (sw, sh))
        base.paste(panel, (px - sx, py - sy), pmask)
        # we can't easily alpha-composite onto sd's image here, so draw translucent rect
        # Approximate the 0.6 black panel by darkening:
        ov = Image.new("RGBA", (sw, sh), (0,0,0,0))
        od = ImageDraw.Draw(ov)
        od.rounded_rectangle([px - sx, py - sy, px - sx + pw, py - sy + ph], radius=44, fill=(0,0,0,150))
        return ov, (px, py, pw, ph)
    return fn

# Because PIL ImageDraw can't alpha-composite mid-callback cleanly, we render the
# controls screen with a dedicated function that returns a full RGB screen image.
def render_controls_screen(sw, sh, bg=RED, highlight=None, sel_timer=0,
                           panel_w=None, panel_h=None, vcenter=False):
    screen = Image.new("RGBA", (sw, sh), bg + (255,))
    sd = ImageDraw.Draw(screen)
    # faint elapsed timer behind the panel (same hue, slightly lighter — as in app)
    tcol = lightened(bg, 0.10)
    bb = sd.textbbox((0, 0), "0:42", font=F_TIMER)
    sd.text((sw/2 - (bb[2]-bb[0])/2, sh*0.40), "0:42", font=F_TIMER, fill=tcol)
    # translucent black panel (0.6 opacity, matches ControlsOverlay). On iPad the
    # panel is a fixed-width card floating on the colored screen (panel_w given),
    # matching the app's maxWidth-380 layout.
    pw = panel_w if panel_w else int(sw * 0.90)
    ph = panel_h if panel_h else int(sh * 0.80)
    px = (sw - pw) // 2
    py = (sh - ph) // 2 if vcenter else int(sh * 0.095)
    panel = Image.new("RGBA", (sw, sh), (0, 0, 0, 0))
    ImageDraw.Draw(panel).rounded_rectangle([px, py, px + pw, py + ph], radius=46, fill=(0, 0, 0, 153))
    screen = Image.alpha_composite(screen, panel)
    sd = ImageDraw.Draw(screen)

    cx = px + pw // 2
    lx = px + 56                 # left margin for left-aligned rows
    rx = px + pw - 56            # right margin
    y = py + 56

    def ctext(text, yy, font, fill):           # centered
        bb = sd.textbbox((0,0), text, font=font)
        sd.text((cx-(bb[2]-bb[0])/2, yy), text, font=font, fill=fill)
        return bb[3]-bb[1]
    def ltext(text, yy, font, fill):           # left aligned
        sd.text((lx, yy), text, font=font, fill=fill)
    def label(text, yy, hl=False, center=True):
        col = CORAL if hl else (214,210,224)
        if center: ctext(text, yy, F_LABEL, col)
        else: sd.text((lx, yy), text, font=F_LABEL, fill=col)

    # Title
    ctext("Baby Light", y, F_PANEL_TITLE, WHITE); y += 104
    # ---- LIGHT COLOR ----
    label("LIGHT COLOR", y, hl=(highlight=="color")); y += 78
    swatches = [RED, AMBER, CANDLE, WARM]
    sel_color = swatches.index(bg) if bg in swatches else 0
    n=len(swatches); gap=40; r=46
    total = n*2*r + (n-1)*gap
    startx = cx - total/2 + r
    cyc = y + r
    for i,c in enumerate(swatches):
        ccx = startx + i*(2*r+gap)
        sd.ellipse([ccx-r, cyc-r, ccx+r, cyc+r], fill=c, outline=WHITE, width=4)
        if i==sel_color:
            dotcol = (60,40,0) if c==WARM else WHITE
            sd.ellipse([ccx-9, cyc-9, ccx+9, cyc+9], fill=dotcol)
    y = cyc + r + 26
    ctext("Best for sleep", y, F_TINY, (210,188,188)); y += 78
    # ---- AUTO-OFF TIMER ----
    timer_label = "AUTO-OFF TIMER"
    if sel_timer > 0:
        timer_label = "AUTO-OFF TIMER  (29:58)"   # remaining time, as in app
    label(timer_label, y, hl=(highlight=="timer")); y += 70
    pills=["∞","15m","30m","1h","2h"]; ph2=70; gap=18
    widths=[max(96, sd.textbbox((0,0),p,font=F_PILL)[2]+52) for p in pills]
    total=sum(widths)+gap*(len(pills)-1)
    xx=cx-total/2
    for i,p in enumerate(pills):
        w=widths[i]; sel=(i==sel_timer)
        if sel:
            sd.rounded_rectangle([xx, y, xx+w, y+ph2], radius=ph2//2, fill=WHITE)
        else:
            sd.rounded_rectangle([xx, y, xx+w, y+ph2], radius=ph2//2,
                                  fill=(255,255,255,26), outline=(255,255,255,90), width=2)
        bb=sd.textbbox((0,0),p,font=F_PILL)
        sd.text((xx+w/2-(bb[2]-bb[0])/2, y+ph2/2-(bb[3]+bb[1])/2), p, font=F_PILL,
                fill=(0,0,0) if sel else WHITE)
        xx+=w+gap
    y += ph2 + 70
    # ---- AUTO BRIGHTNESS ----
    label("AUTO BRIGHTNESS", y, hl=(highlight=="bright"), center=False); y += 66
    def toggle_row(text, yy, on=True):
        sd.text((lx, yy), text, font=F_BODY, fill=WHITE)
        tw=92; th=54; tx=rx-tw
        sd.rounded_rectangle([tx, yy-2, tx+tw, yy-2+th], radius=th//2, fill=CORAL if on else (90,90,100))
        knob=th-12
        kx = tx+tw-knob-6 if on else tx+6
        sd.ellipse([kx, yy-2+6, kx+knob, yy-2+6+knob], fill=WHITE)
    toggle_row("Max brightness on open", y, True); y+=86
    toggle_row("Dim to black on close", y, True); y+=104
    # ---- ELAPSED TIMER + slider ----
    label("ELAPSED TIMER", y, hl=False, center=False); y += 66
    sd.text((lx, y-4), "Brightness", font=F_BODY, fill=WHITE)
    slx = lx+250; sly=y+18; slw=rx-110-slx
    sd.line([slx, sly, slx+slw, sly], fill=(255,255,255,110), width=6)
    sd.line([slx, sly, slx+int(slw*0.4), sly], fill=WHITE, width=6)
    sd.ellipse([slx+int(slw*0.4)-17, sly-17, slx+int(slw*0.4)+17, sly+17], fill=WHITE)
    prev="0:42"; bb=sd.textbbox((0,0),prev,font=F_BODY)
    sd.text((rx-(bb[2]-bb[0]), y-4), prev, font=F_BODY, fill=lightened(bg,0.28))
    y += 96
    ctext("Double-tap to hide • Swipe to adjust", y, F_TINY, (150,150,162))
    return screen.convert("RGB")

# ---- compositing a full creative ------------------------------------------
def screen_blend(a, b):
    pa, pb = a.load(), b.load()
    out = Image.new("RGB", a.size)
    po = out.load()
    for y in range(a.size[1]):
        for x in range(a.size[0]):
            ra,ga,ba = pa[x,y]; rb,gb,bb = pb[x,y]
            po[x,y] = (255-(255-ra)*(255-rb)//255, 255-(255-ga)*(255-gb)//255, 255-(255-ba)*(255-bb)//255)
    return out

# screen_blend pixel loop is slow at 1320x2868; use numpy if available
try:
    import numpy as np
    def screen_blend(a, b):
        aa = np.asarray(a).astype(np.float32); bb = np.asarray(b).astype(np.float32)
        out = 255 - (255-aa)*(255-bb)/255
        return Image.fromarray(out.clip(0,255).astype('uint8'))
except Exception:
    pass

def base_bg(glow_color=None, glow_xy=None, glow_r=900):
    img = vgradient(INDIGO_TOP, INDIGO)
    if glow_color:
        glow = Image.new("RGB", (W, H), (0, 0, 0))
        gd = ImageDraw.Draw(glow)
        cx, cy = glow_xy
        for i in range(60, 0, -1):
            r = int(glow_r * i / 60)
            a = (i / 60) ** 2
            gd.ellipse([cx - r, cy - r, cx + r, cy + r],
                       fill=tuple(int(c * a) for c in glow_color))
        glow = glow.filter(ImageFilter.GaussianBlur(120))
        img = screen_blend(img, glow)
    return img

def place_phone(img, phone, cx, cy):
    pw, ph = phone.size
    img = img.convert("RGBA")
    img.alpha_composite(phone, (int(cx-pw/2), int(cy-ph/2)))
    return img.convert("RGB")

def header(img, title, sub, color=WHITE):
    d = ImageDraw.Draw(img)
    y = 150
    y = draw_center_text(d, W/2, y, title, F_HEAD, color, max_w=W-150, line_gap=8)
    y += 36
    draw_center_text(d, W/2, y, sub, F_SUB, MUTE, max_w=W-220, line_gap=12)
    return img

def page_dots(img, idx, total=6):
    d = ImageDraw.Draw(img)
    r=9; gap=34; total_w=total*2*r+(total-1)*gap
    x=W/2-total_w/2+r; yy=H-70
    for i in range(total):
        c = CORAL if i==idx else (90,80,110)
        d.ellipse([x-r, yy-r, x+r, yy+r], fill=c); x+=2*r+gap
    return img

# =================== build the 6 screenshots ================================
def s1():
    img = base_bg(glow_color=(150,20,20), glow_xy=(W/2, H*0.62), glow_r=1100)
    img = header(img, "A red night light\nmade for babies", "See in the dark without waking anyone")
    phone = phone_screen(content_fullscreen(RED, "0:42"), scale=1.0)
    img = place_phone(img, phone, W/2, H*0.66)
    return page_dots(img, 0)

def s2():
    img = base_bg(glow_color=(120,30,20), glow_xy=(W/2, H*0.66), glow_r=900)
    img = header(img, "Light that won't\nfight melatonin", "Red & amber sit at the calm end of the spectrum")
    d = ImageDraw.Draw(img)
    # short explainer
    expl = "Bright blue & white light suppresses melatonin, the sleep hormone. Red light barely touches it."
    draw_center_text(d, W/2, int(H*0.215), expl, F_BODY, (208,200,222), max_w=W-260, line_gap=14)
    # spectrum bar
    bx0, bx1 = 130, W-130; by = int(H*0.40); bh=80
    spectrum = [(150,40,220),(40,80,255),(0,200,255),(0,220,120),(255,230,0),(255,140,0),(255,0,0)]
    grad = Image.new("RGB",(len(spectrum),1))
    for i,c in enumerate(spectrum): grad.putpixel((i,0),c)
    grad = grad.resize((bx1-bx0, bh))
    gm = Image.new("L",(bx1-bx0,bh),0); ImageDraw.Draw(gm).rounded_rectangle([0,0,bx1-bx0,bh],radius=bh//2,fill=255)
    img.paste(grad,(bx0,by),gm)
    d = ImageDraw.Draw(img)
    # end labels
    d.text((bx0, by+bh+20), "480nm blue", font=F_TINY, fill=(150,180,255))
    txt="600–700nm red"; bb=d.textbbox((0,0),txt,font=F_TINY)
    d.text((bx1-(bb[2]-bb[0]), by+bh+20), txt, font=F_TINY, fill=(255,150,140))
    # arrow above the red end (where this app lives)
    ax = bx1-46
    d.polygon([(ax-22, by-16),(ax+22, by-16),(ax, by+8)], fill=WHITE)
    d.text((ax-150, by-66), "this app", font=F_TINY, fill=WHITE)
    # two frosted comparison cards (alpha-composited so they stay translucent)
    overlay = Image.new("RGBA",(W,H),(0,0,0,0)); od=ImageDraw.Draw(overlay)
    cw=(W-130*2-44)//2; ch=420; cy=int(H*0.55)
    cards=[(130, (96,150,255), "Blue / white", "Tells the brain it's daytime — delays sleep"),
           (130+cw+44, CORAL, "Red / amber", "Lets melatonin rise — gentle for night")]
    for x,dot,title,desc in cards:
        od.rounded_rectangle([x,cy,x+cw,cy+ch], radius=40, fill=(255,255,255,20), outline=(255,255,255,55), width=2)
    img = Image.alpha_composite(img.convert("RGBA"), overlay).convert("RGB")
    d = ImageDraw.Draw(img)
    for x,dot,title,desc in cards:
        ccx=x+cw//2
        d.ellipse([ccx-46, cy+54, ccx+46, cy+146], fill=dot)
        draw_center_text(d, ccx, cy+186, title, f(AVENIR,46,index=0), WHITE, max_w=cw-50)
        draw_center_text(d, ccx, cy+266, desc, F_TINY, MUTE, max_w=cw-70, line_gap=12)
    return page_dots(img, 1)

def s3():
    img = base_bg(glow_color=(120,30,20), glow_xy=(W/2, H*0.62), glow_r=950)
    img = header(img, "Four sleep-\nfriendly colors", "Deep red, amber, candle & warm white")
    screen = render_controls_screen(760, 1646, bg=RED, highlight="color")
    img = place_phone(img, phone_with_screen(screen), W/2, H*0.66)
    return page_dots(img, 2)

def s4():
    img = base_bg(glow_color=(150,80,10), glow_xy=(W/2, H*0.62), glow_r=950)
    img = header(img, "Set it and\nlet it fade", "Auto-off after 15m, 30m, 1h or 2h")
    screen = render_controls_screen(760, 1646, bg=CANDLE, highlight="timer", sel_timer=2)
    img = place_phone(img, phone_with_screen(screen), W/2, H*0.66)
    return page_dots(img, 3)

def s5():
    img = base_bg(glow_color=(120,60,10), glow_xy=(W/2, H*0.62), glow_r=1000)
    img = header(img, "Swipe to dim.\nCloses to black.", "Bright when you open, dark when you don't")
    phone = phone_screen(content_fullscreen(AMBER, "1:07"), scale=1.0)
    img = place_phone(img, phone, W/2, H*0.66)
    # swipe hint
    d=ImageDraw.Draw(img)
    return page_dots(img, 4)

def s6():
    img = base_bg(glow_color=(120,30,20), glow_xy=(W/2, H*0.56), glow_r=1000)
    img = header(img, "No ads. No sign-up.\nNo noise.", "Just a warm glow for the 2 AM shift — free")
    # Real app icon as the brand centerpiece, rounded + soft glow
    icon_path = os.path.join(os.path.dirname(__file__), "..", "Baby Light",
                             "Assets.xcassets", "AppIcon.appiconset", "AppIcon.png")
    iconsz = 460
    cy = int(H*0.55)
    try:
        icon = Image.open(icon_path).convert("RGB").resize((iconsz, iconsz), Image.LANCZOS)
        # soft glow behind
        glow = Image.new("RGB",(W,H),(0,0,0)); gd=ImageDraw.Draw(glow)
        gr=int(iconsz*0.85)
        for i in range(40,0,-1):
            r=int(gr*i/40); a=(i/40)**2
            gd.ellipse([W/2-r, cy-r, W/2+r, cy+r], fill=tuple(int(c*a) for c in (150,40,40)))
        glow=glow.filter(ImageFilter.GaussianBlur(70))
        img = screen_blend(img, glow)
        # rounded mask (iOS superellipse-ish via large radius)
        m=Image.new("L",(iconsz,iconsz),0)
        ImageDraw.Draw(m).rounded_rectangle([0,0,iconsz,iconsz], radius=int(iconsz*0.225), fill=255)
        img = img.convert("RGBA")
        img.paste(icon, (W//2-iconsz//2, cy-iconsz//2), m)
        img = img.convert("RGB")
    except Exception as e:
        pass
    d=ImageDraw.Draw(img)
    draw_center_text(d, W/2, cy+iconsz//2+70, "Free  •  Private  •  Offline",
                     f(AVENIR,46,index=0), WHITE, max_w=W-160)
    return page_dots(img, 5)

def phone_with_screen(screen_img):
    sw, sh = screen_img.size
    bez=26; radius=150
    dw, dh = sw+bez*2, sh+bez*2
    dev = Image.new("RGBA",(dw,dh),(0,0,0,0)); dd=ImageDraw.Draw(dev)
    rounded(dd,[0,0,dw,dh],radius+bez,fill=(18,18,22,255))
    rounded(dd,[2,2,dw-2,dh-2],radius+bez-2,outline=(70,70,80,255),width=3)
    mask=Image.new("L",(sw,sh),0); ImageDraw.Draw(mask).rounded_rectangle([0,0,sw,sh],radius=radius,fill=255)
    dev.paste(screen_img,(bez,bez),mask)
    isl_w,isl_h=230,64
    rounded(dd,[(dw-isl_w)//2, bez+30,(dw+isl_w)//2, bez+30+isl_h], isl_h//2, fill=(0,0,0,255))
    return dev

# =================== iPad set (2064 x 2752) ================================
def ipad_mock(screen_img):
    sw, sh = screen_img.size
    bez = 40; radius = 92
    dw, dh = sw + bez*2, sh + bez*2
    dev = Image.new("RGBA", (dw, dh), (0,0,0,0)); dd = ImageDraw.Draw(dev)
    rounded(dd, [0,0,dw,dh], radius+bez, fill=(20,20,24,255))
    rounded(dd, [3,3,dw-3,dh-3], radius+bez-3, outline=(72,72,82,255), width=3)
    mask = Image.new("L",(sw,sh),0); ImageDraw.Draw(mask).rounded_rectangle([0,0,sw,sh],radius=radius,fill=255)
    dev.paste(screen_img, (bez,bez), mask)
    dd.ellipse([dw/2-8, bez/2-8, dw/2+8, bez/2+8], fill=(58,58,68,255))  # camera
    return dev

def ipad_header(img, title, sub):
    d = ImageDraw.Draw(img)
    fh = f(AVENIR, 150, index=8); fs = f(AVENIR, 70, index=5)
    y = draw_center_text(d, W/2, 180, title, fh, WHITE, max_w=W-260, line_gap=12)
    y += 44
    draw_center_text(d, W/2, y, sub, fs, MUTE, max_w=W-360, line_gap=16)

# iPad screen content area (3:4 portrait)
IPAD_SW, IPAD_SH = 1320, 1760

def ipad_fullscreen(color, timer):
    sc = Image.new("RGB", (IPAD_SW, IPAD_SH), color)
    d = ImageDraw.Draw(sc)
    ft = f(ROUND, 200)
    tcol = lightened(color, 0.20)
    bb = d.textbbox((0,0), timer, font=ft)
    d.text((IPAD_SW/2-(bb[2]-bb[0])/2, IPAD_SH*0.45), timer, font=ft, fill=tcol)
    return sc.convert("RGBA")

def ip1():
    img = base_bg(glow_color=(150,20,20), glow_xy=(W/2, H*0.62), glow_r=1500)
    ipad_header(img, "A red night light\nmade for babies", "See in the dark without waking anyone")
    return place_phone(img, ipad_mock(ipad_fullscreen(RED, "0:42")), W/2, H*0.62)

def ip2():
    img = base_bg(glow_color=(120,30,20), glow_xy=(W/2, H*0.62), glow_r=1400)
    ipad_header(img, "Four sleep-friendly colors", "Deep red, amber, candle & warm white")
    sc = render_controls_screen(IPAD_SW, IPAD_SH, bg=RED, highlight="color",
                                panel_w=900, panel_h=1380, vcenter=True)
    return place_phone(img, ipad_mock(sc.convert("RGBA")), W/2, H*0.62)

def ip3():
    img = base_bg(glow_color=(150,80,10), glow_xy=(W/2, H*0.62), glow_r=1400)
    ipad_header(img, "Set it and let it fade", "Auto-off after 15m, 30m, 1h or 2h")
    sc = render_controls_screen(IPAD_SW, IPAD_SH, bg=CANDLE, highlight="timer", sel_timer=2,
                                panel_w=900, panel_h=1380, vcenter=True)
    return place_phone(img, ipad_mock(sc.convert("RGBA")), W/2, H*0.62)

def ip4():
    img = base_bg(glow_color=(120,60,10), glow_xy=(W/2, H*0.62), glow_r=1500)
    ipad_header(img, "Swipe to dim.\nCloses to black.", "Bright when you open, dark when you don't")
    return place_phone(img, ipad_mock(ipad_fullscreen(AMBER, "1:07")), W/2, H*0.62)

def ip5():
    img = base_bg(glow_color=(120,30,20), glow_xy=(W/2, H*0.55), glow_r=1500)
    ipad_header(img, "No ads. No sign-up.\nNo noise.", "Just a warm glow for the 2 AM shift — free")
    icon_path = os.path.join(os.path.dirname(__file__), "..", "Baby Light",
                             "Assets.xcassets", "AppIcon.appiconset", "AppIcon.png")
    sz = 720; cy = int(H*0.56)
    try:
        icon = Image.open(icon_path).convert("RGB").resize((sz,sz), Image.LANCZOS)
        m = Image.new("L",(sz,sz),0); ImageDraw.Draw(m).rounded_rectangle([0,0,sz,sz],radius=int(sz*0.225),fill=255)
        img = img.convert("RGBA"); img.paste(icon, (W//2-sz//2, cy-sz//2), m); img = img.convert("RGB")
    except Exception:
        pass
    d = ImageDraw.Draw(img)
    draw_center_text(d, W/2, cy+sz//2+90, "Free  •  Private  •  Offline", f(AVENIR,64,index=0), WHITE, max_w=W-200)
    return img

# =================== Apple Watch set (422 x 514, Ultra) ====================
def watch_creative(color, timer, caption):
    sc = Image.new("RGB", (W, H), color)
    d = ImageDraw.Draw(sc)
    # count-up feed timer, lightened hue (as in the watch app)
    ft = f(ROUND, 96)
    tcol = lightened(color, 0.22)
    bb = d.textbbox((0,0), timer, font=ft)
    d.text((W/2-(bb[2]-bb[0])/2, H*0.34), timer, font=ft, fill=tcol)
    # bottom scrim + caption
    scrim = Image.new("RGBA",(W,H),(0,0,0,0))
    sd = ImageDraw.Draw(scrim)
    for i in range(160):
        a = int(150 * (i/160))
        sd.line([(0, H-160+i),(W, H-160+i)], fill=(0,0,0,a))
    sc = Image.alpha_composite(sc.convert("RGBA"), scrim).convert("RGB")
    d = ImageDraw.Draw(sc)
    draw_center_text(d, W/2, H-118, caption, f(AVENIR,40,index=0), WHITE, max_w=W-60, line_gap=6)
    return sc

# =================== run all device sets ====================================
def build_iphone():
    global W, H
    W, H = 1320, 2868
    sets = [(s1,"01_hero_red"),(s2,"02_science"),(s3,"03_colors"),
            (s4,"04_timer"),(s5,"05_brightness"),(s6,"06_closing")]
    for fn, nm in sets:
        out = fn()
        if out.size != (W,H): out = out.resize((W,H), Image.LANCZOS)
        out.save(os.path.join(OUT, nm + ".png")); print("iphone:", nm, out.size)

def build_ipad():
    global W, H
    W, H = 2064, 2752
    d = os.path.join(OUT, "ipad"); os.makedirs(d, exist_ok=True)
    sets = [(ip1,"01_hero_red"),(ip2,"02_colors"),(ip3,"03_timer"),
            (ip4,"04_brightness"),(ip5,"05_closing")]
    for fn, nm in sets:
        out = fn()
        if out.size != (W,H): out = out.resize((W,H), Image.LANCZOS)
        out.save(os.path.join(d, nm + ".png")); print("ipad:", nm, out.size)

def build_watch():
    global W, H
    W, H = 422, 514
    d = os.path.join(OUT, "watch"); os.makedirs(d, exist_ok=True)
    sets = [(RED, "0:42", "A night light on your wrist", "01_red"),
            (AMBER, "1:07", "Tap to change the color", "02_amber"),
            (CANDLE, "2:18", "Turn the Crown to dim", "03_candle")]
    for color, timer, cap, nm in sets:
        out = watch_creative(color, timer, cap)
        if out.size != (W,H): out = out.resize((W,H), Image.LANCZOS)
        out.save(os.path.join(d, nm + ".png")); print("watch:", nm, out.size)

build_iphone()
build_ipad()
build_watch()
print("done")
