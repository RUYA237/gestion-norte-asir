# Iconos vectoriales propios (SVG), sin fotos de producto.
def pc(x,y,s=1.0):
    return f'''<g transform="translate({x},{y}) scale({s})">
<rect x="0" y="0" width="54" height="36" rx="4" fill="#2b2f36"/>
<rect x="4" y="4" width="46" height="26" rx="2" fill="url(#scr)"/>
<rect x="22" y="36" width="10" height="8" fill="#555"/>
<rect x="14" y="44" width="26" height="4" rx="2" fill="#2b2f36"/></g>'''
def switch(x,y,w=150,s=1.0):
    ports="".join(f'<rect x="{12+i*((w-24)/12)}" y="14" width="{(w-24)/12-4:.1f}" height="8" fill="#9aa4b2"/>' for i in range(12))
    leds="".join(f'<circle cx="{14+i*((w-28)/6)}" cy="30" r="2.2" fill="#3ddc84"/>' for i in range(6))
    return f'''<g transform="translate({x},{y}) scale({s})">
<rect x="0" y="0" width="{w}" height="40" rx="4" fill="url(#sw)"/>{ports}{leds}</g>'''
def router(x,y,s=1.0):
    return f'''<g transform="translate({x},{y}) scale({s})">
<line x1="18" y1="2" x2="10" y2="-22" stroke="#444" stroke-width="3"/>
<line x1="52" y1="2" x2="60" y2="-22" stroke="#444" stroke-width="3"/>
<rect x="0" y="0" width="70" height="26" rx="10" fill="url(#rt)"/>
<circle cx="14" cy="13" r="3" fill="#3ddc84"/><circle cx="26" cy="13" r="3" fill="#3ddc84"/>
<rect x="40" y="9" width="22" height="8" fill="#9aa4b2"/></g>'''
def firewall(x,y,s=1.0):
    return f'''<g transform="translate({x},{y}) scale({s})">
<rect x="0" y="0" width="44" height="60" rx="4" fill="url(#fw)"/>
<rect x="6" y="8" width="32" height="6" fill="#ff9f43"/><rect x="6" y="22" width="32" height="6" fill="#ff9f43"/>
<rect x="6" y="36" width="32" height="6" fill="#ff9f43"/>
<circle cx="10" cy="52" r="2.5" fill="#3ddc84"/><circle cx="20" cy="52" r="2.5" fill="#3ddc84"/></g>'''
def server(x,y,s=1.0):
    return f'''<g transform="translate({x},{y}) scale({s})">
<rect x="0" y="0" width="30" height="50" rx="3" fill="url(#srv)"/>
<rect x="5" y="7" width="20" height="5" fill="#8ea0b8"/><rect x="5" y="18" width="20" height="5" fill="#8ea0b8"/>
<rect x="5" y="29" width="20" height="5" fill="#8ea0b8"/>
<circle cx="8" cy="42" r="2" fill="#3ddc84"/><circle cx="15" cy="42" r="2" fill="#3ddc84"/></g>'''
def ap(x,y,s=1.0):
    return f'''<g transform="translate({x},{y}) scale({s})">
<line x1="8" y1="14" x2="2" y2="-6" stroke="#444" stroke-width="2.5"/>
<line x1="22" y1="14" x2="28" y2="-6" stroke="#444" stroke-width="2.5"/>
<ellipse cx="15" cy="20" rx="16" ry="8" fill="url(#ap)"/>
<circle cx="15" cy="19" r="2" fill="#3ddc84"/></g>'''
def printer(x,y,s=1.0):
    return f'''<g transform="translate({x},{y}) scale({s})">
<rect x="10" y="0" width="30" height="14" fill="#fff" stroke="#666"/>
<rect x="0" y="14" width="50" height="22" rx="4" fill="url(#pr)"/>
<rect x="10" y="30" width="30" height="12" fill="#fff" stroke="#666"/></g>'''
def cloud(x,y,w,h,label):
    return f'''<g transform="translate({x},{y})">
<ellipse cx="{w/2}" cy="{h/2}" rx="{w/2}" ry="{h/2}" fill="#eef2f7" stroke="#6b7a90" stroke-width="2"/>
<text x="{w/2}" y="{h/2+6}" text-anchor="middle" font-family="Arial" font-size="20" font-weight="bold" fill="#222">{label}</text></g>'''
DEFS='''<defs>
<linearGradient id="scr" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#7ec8ff"/><stop offset="1" stop-color="#1d6fd6"/></linearGradient>
<linearGradient id="sw" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#4a5566"/><stop offset="1" stop-color="#252b36"/></linearGradient>
<linearGradient id="rt" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#e8edf4"/><stop offset="1" stop-color="#b9c3d1"/></linearGradient>
<linearGradient id="fw" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#3b4452"/><stop offset="1" stop-color="#1c212a"/></linearGradient>
<linearGradient id="srv" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#5b6779"/><stop offset="1" stop-color="#2c3440"/></linearGradient>
<linearGradient id="ap" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#ffffff"/><stop offset="1" stop-color="#d5dde8"/></linearGradient>
<linearGradient id="pr" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#d0d6e0"/><stop offset="1" stop-color="#8a95a6"/></linearGradient>
</defs>'''
