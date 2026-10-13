# Super Mario World — Web (SNES)

Un sitio que ejecuta **Super Mario World (SNES)** directamente en el navegador, inspirado en
[SM64-PC-Port-WebGL](https://github.com/notan127/SM64-PC-Port-WebGL).

## ¿Qué es (y qué no es)?

- **Sí es:** un emulador de SNES (**snes9x**) compilado a **WebAssembly** mediante
  [EmulatorJS](https://emulatorjs.org), empaquetado en una página web lista para publicar.
- **No es:** una recompilación/port nativo del juego. SM64 tiene una decompilación que se puede
  recompilar; SMW no tiene un port nativo al navegador, así que la vía realista es emular.

## Estructura

```
SMW-Web/
├─ index.html                  # Página + configuración de EmulatorJS
├─ style.css                   # Estilos
├─ rom/
│  └─ super-mario-world-usa.sfc  # Tu ROM (NO subir a un repo público)
├─ .nojekyll                   # Evita el procesado de Jekyll en GitHub Pages
├─ serve.ps1                   # Servidor local (para probar sin Python/Node)
└─ .github/workflows/deploy-pages.yml
```

## Probar en local

EmulatorJS carga la ROM con `fetch`, así que **no funciona abriendo `index.html` con doble clic**
(protocolo `file://`). Necesitas servirlo por HTTP.

Con el script incluido (PowerShell):

```powershell
powershell -ExecutionPolicy Bypass -File .\serve.ps1
# luego abre http://localhost:8080/
```

Cualquier otro servidor estático sirve (Live Server de VS Code, `python -m http.server`, etc.).

## Publicar en GitHub Pages

### Opción A — GitHub Actions (incluida)

1. Crea el repo y sube el contenido:
   ```bash
   git init
   git add .
   git commit -m "Super Mario World web"
   git branch -M main
   git remote add origin https://github.com/TU_USUARIO/SMW-Web.git
   git push -u origin main
   ```
2. En GitHub: **Settings → Pages → Build and deployment → Source = `GitHub Actions`**.
3. El workflow `deploy-pages.yml` publica en cada push a `main`.

### Opción B — Desde la rama (sin Actions)

**Settings → Pages → Source = `Deploy from a branch` → Branch = `main` / `root`.**
El archivo `.nojekyll` ya está incluido.

La web quedará en `https://TU_USUARIO.github.io/SMW-Web/`.

## Controles

| Tecla | Botón SNES |
|-------|------------|
| Flechas | D-Pad |
| Z | Saltar (B) |
| X | Correr (A) |
| A | Y |
| S | X |
| Enter | Start |
| V | Select |
| Q / E | L / R |

En móvil se muestran controles táctiles automáticamente. Los mandos USB/Bluetooth también funcionan.

## Cambiar la ROM o el core

- ROM: reemplaza el archivo en `rom/` y actualiza `EJS_gameUrl` en `index.html`.
- Otro core de SNES: `EJS_core = 'bsnes'`.
- Usar el CDN o auto-hospedar EmulatorJS: edita `EJS_pathtodata` (por defecto, el CDN oficial).

## Modo "trae tu propia ROM" (recomendado si publicas)

Si no quieres subir la ROM al repositorio público:

1. Descomenta `rom/*.sfc` en `.gitignore` (o borra la carpeta `rom/`).
2. En `index.html`, **borra** la línea:
   ```js
   EJS_gameUrl = 'rom/super-mario-world-usa.sfc';
   ```
   Sin `EJS_gameUrl`, EmulatorJS muestra su **selector de archivos** en la pantalla
   de inicio, así cada persona usa su propia copia del juego.
3. El resto del sitio funciona igual.

## Aviso legal

Super Mario World © Nintendo. Este proyecto es de aficionado, sin ánimo de lucro ni afiliación.
**No distribuyas la ROM**: usa tu propia copia. Si publicas el sitio en GitHub Pages,
GitHub puede eliminar el repositorio por DMCA si incluye la ROM; por eso se recomienda el
**modo "trae tu propia ROM"** de arriba.
