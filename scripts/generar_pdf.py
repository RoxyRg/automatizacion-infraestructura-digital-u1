#!/usr/bin/env python3
"""Genera el PDF académico desde el README, usando pandoc y WeasyPrint.
Requiere: pandoc y Python package weasyprint/beautifulsoup4.
Las evidencias no se inventan; solo se incluyen imágenes de capturas presentes.
"""
from pathlib import Path
from bs4 import BeautifulSoup
from tempfile import TemporaryDirectory
import subprocess
import sys

project = Path(__file__).resolve().parents[1]
readme = project / 'README.MD'
out = project / 'Reporte_Unidad_I.pdf'

with TemporaryDirectory() as tmp:
    html = Path(tmp)/'reporte.html'
    subprocess.run(['pandoc','-f','gfm','-t','html5','--standalone','--metadata', 'title=Unidad I - Automatización de Infraestructura Digital',str(readme),'-o',str(html)],check=True)
    soup = BeautifulSoup(html.read_text(encoding='utf-8'),'html.parser')
    body = soup.body
    cover = soup.new_tag('section', **{'class':'cover'})
    logo_path = project / 'evidencias' / 'logo_utng_oficial.png'
    if logo_path.is_file():
        logo = soup.new_tag('img', src=logo_path.as_uri(), alt='Logotipo oficial de UTNG', **{'class':'logo-utng'})
    else:
        logo = soup.new_tag('div', **{'class':'logo-placeholder'})
        logo.string = 'PENDIENTE: INSERTAR LOGOTIPO OFICIAL DE UTNG'
    cover.append(logo)
    for ch in list(body.children):
        if getattr(ch,'name',None)=='hr':
            ch.extract()
            break
        if getattr(ch,'name',None):cover.append(ch.extract())
    body.insert(0,cover)

    imgs = sorted((project/'evidencias'/'capturas').glob('*.png'))
    if imgs:
        heading = next((h for h in body.find_all('h2') if h.get_text(' ',strip=True).startswith('7. Lista')),None)
        if heading:
            section = soup.new_tag('section', **{'class':'capturas'})
            title = soup.new_tag('h3'); title.string='6.7 Capturas de evidencia de ejecución'; section.append(title)
            for path in imgs:
                figure=soup.new_tag('figure')
                img=soup.new_tag('img',src=path.as_uri(),alt=path.name)
                figure.append(img)
                caption=soup.new_tag('figcaption');caption.string=path.name;figure.append(caption)
                section.append(figure)
            heading.insert_before(section)

    for h in soup.find_all('h2'):
        if h.get_text(' ',strip=True).startswith('10. Referencias'):
            h['class'] = h.get('class',[])+['bibliography-head']
            notice = h.find_next_sibling('blockquote')
            if notice:
                notice.decompose()  # La instrucción sobre el PDF pertenece al README, no al PDF.
            for p in h.find_next_siblings('p'):
                if 'Docker, Inc.' not in p.get_text():continue
                fragments=p.decode_contents().split('<br/>')
                for frag in fragments:
                    frag=frag.strip()
                    if not frag:continue
                    line=BeautifulSoup('<p class="apa-entry">'+frag+'</p>','html.parser').p
                    p.insert_before(line)
                p.decompose()
                break
            break

    status=soup.new_tag('div', **{'class':'statusbar'})
    status.string='BORRADOR - COMPLETAR GRUPO, NÚMERO DE CONTROL, LOGO Y EVIDENCIAS REALES ANTES DE ENTREGA'
    body.insert(1,status)
    style=soup.new_tag('style')
    style.string='''
@page {size:A4; margin: 2cm 2.1cm 2cm 2.3cm; @bottom-center {content:"Página " counter(page); color:#526074; font-size:9pt;} }
@page:first { @bottom-center {content: "";} }
body { font: 10.8pt/1.15 "Lato", "Noto Sans", Arial, sans-serif; color:#1b293a; }
p {text-align:justify; margin:0.43em 0;}
h1 {font-size:20pt;color:#223c5c;}
h2 {font-size:14pt;margin:1.15em 0 0.5em;color:#203e60;break-after:avoid;}
h3 {font-size:11.8pt;color:#294e73;break-after:avoid;}
pre {background:#f3f6f8;border-left:3px solid #426992;padding:7px 10px;font-size:8pt;line-height:1.18;white-space:pre-wrap;overflow-wrap:anywhere;}
code {font-family:"DejaVu Sans Mono",monospace;font-size:8.6pt;overflow-wrap:anywhere;}
pre code {font-size:8pt;}
blockquote {border-left:3px solid #d69a31;padding:6px 12px;margin-left:0;background:#fff9e9;color:#674f22;}
table {border-collapse:collapse;width:100%;font-size:9.1pt;margin:0.6em 0;}
th,td {border:1px solid #bcc9d6;padding:5px 6px;text-align:left;vertical-align:top;}
th{background:#e8eff6;color:#1e3a58;}
li{margin:0.15em 0;}
img{max-width:100%;}
.cover {height:25cm;box-sizing:border-box;padding-top:2.5cm;text-align:center;page-break-after:always;}
.cover *{text-align:center;}
.cover h1{font-size:17pt;margin-top:1cm;}
.cover h2{font-size:13pt;}
.cover p{font-size:12pt;line-height:1.45;}
.logo-utng{max-height:4cm;max-width:60%;margin:0 auto 1cm;}
.cover .logo-placeholder{border:2px dashed #b7c4d3;padding:35px 20px;font-size:10pt;color:#697b8d;width:66%;margin:0 auto 1.4cm;}
.cover blockquote{margin-top:1.5cm;text-align:left;font-size:9pt;}
.statusbar{background:#fff2d8;color:#845323;padding:10px;font-size:9pt;margin:0.6cm 0;}
.bibliography-head{break-before:page;}
.apa-entry{margin:0; padding-left:1.2cm; text-indent:-1.2cm; line-height:1.15;}
figure{max-width:95%; margin:0.3cm auto; page-break-inside:avoid;}
figure img{max-height:15cm;object-fit:contain;}
figcaption{text-align:center;font-size:9pt;font-style:italic;}
'''
    soup.head.append(style)
    html.write_text(str(soup), encoding='utf-8')
    subprocess.run(['weasyprint',str(html),str(out)],check=True)
print('PDF generado:',out)
