$utf8 = [System.Text.UTF8Encoding]::new($true)
$nl = "`r`n"

# ============================================
# CONFIG.HTML - Zona/Packing + Boton Inicio
# ============================================
$path = "C:\planta-rapel-2026\config.html"
$c = Get-Content $path -Raw

# CAMBIO #3: ARANDANOS -> ARANDANO
$c = $c.Replace('<option value="ARANDANOS">ARANDANOS</option>', '<option value="ARANDANO">ARANDANO</option>')

# CAMBIO #3: BODEGA FRIGORIFICOS -> BODEGA + FRIGORIFICO (2 opciones separadas)
$c = $c.Replace(
  '<option value="BODEGA FRIGORIFICOS">BODEGA FRIGORIFICOS</option>',
  '<option value="BODEGA">BODEGA</option>' + $nl + '              <option value="FRIGORIFICO">FRIGORIFICO</option>'
)

# CAMBIO #2: Boton "Inicio" en navbar de config.html
if ($c -notmatch 'id="btnInicio"') {
  $c = $c.Replace(
    '<button class="btn btn-sm btn-outline-light" id="btnLogout">Salir</button>',
    '<button class="btn btn-sm btn-light me-2" id="btnInicio">Inicio</button>' + $nl + '      <button class="btn btn-sm btn-outline-light" id="btnLogout">Salir</button>'
  )
}

[System.IO.File]::WriteAllText($path, $c, $utf8)
Write-Host "config.html OK: opciones corregidas + boton Inicio" -ForegroundColor Green

# ============================================
# CONFIG-INICIAL.JS - Listener btnInicio
# ============================================
$path = "C:\planta-rapel-2026\js\config-inicial.js"
$j = Get-Content $path -Raw

if ($j -notmatch 'btnInicio') {
  $oldLog = "document.getElementById('btnLogout').addEventListener('click', () => {" + $nl + "    if (confirm('Salir de la sesion?')) Auth.cerrarSesion();" + $nl + "  });"
  $newLog = $oldLog + $nl + "  document.getElementById('btnInicio').addEventListener('click', () => {" + $nl + "    window.location.href = 'home.html';" + $nl + "  });"
  $j = $j.Replace($oldLog, $newLog)
}

[System.IO.File]::WriteAllText($path, $j, $utf8)
Write-Host "config-inicial.js OK: btnInicio listener" -ForegroundColor Green

# ============================================
# SCANNER.HTML - Boton Inicio + Finalizar Registro
# ============================================
$path = "C:\planta-rapel-2026\scanner.html"
$s = Get-Content $path -Raw

# CAMBIO #2: Boton Inicio antes de Cambiar
if ($s -notmatch 'id="btnInicio"') {
  $s = $s.Replace(
    '<button class="btn btn-sm btn-light" id="btnNuevaSesion">Cambiar</button>',
    '<button class="btn btn-sm btn-light me-1" id="btnInicio">Inicio</button>' + $nl + '    <button class="btn btn-sm btn-light" id="btnNuevaSesion">Cambiar</button>'
  )
}

# CAMBIO #4: Textos
$s = $s.Replace('Finalizar Sesi&oacute;n', 'Finalizar Registro')
$s = $s.Replace('Sesi&oacute;n Finalizada', 'Registro Finalizado')
$s = $s.Replace('Nueva Sesi&oacute;n', 'Nuevo Registro')

[System.IO.File]::WriteAllText($path, $s, $utf8)
Write-Host "scanner.html OK: boton Inicio + Finalizar Registro" -ForegroundColor Green

# ============================================
# SCANNER.JS - Listener btnInicio + texto
# ============================================
$path = "C:\planta-rapel-2026\js\scanner.js"
$sj = Get-Content $path -Raw

if ($sj -notmatch 'btnInicio') {
  $oldNS = "btnFinalizar.addEventListener('click', finalizar);" + $nl + "  document.getElementById('btnNuevaSesion').addEventListener('click', () => {"
  $newNS = "btnFinalizar.addEventListener('click', finalizar);" + $nl + "  document.getElementById('btnInicio').addEventListener('click', () => {" + $nl + "    if (asistencias.length > 0 && !confirm('Hay ' + asistencias.length + ' asistencias en curso. Volver al inicio sin perderlas?')) return;" + $nl + "    window.location.href = 'home.html';" + $nl + "  });" + $nl + "  document.getElementById('btnNuevaSesion').addEventListener('click', () => {"
  $sj = $sj.Replace($oldNS, $newNS)
}

# Textos
$sj = $sj.Replace("'Finalizar Sesion'", "'Finalizar Registro'")
$sj = $sj.Replace("'Sesion completa con ", "'Registro completo con ")

[System.IO.File]::WriteAllText($path, $sj, $utf8)
Write-Host "scanner.js OK: btnInicio listener + textos" -ForegroundColor Green

# ============================================
# Verificacion
# ============================================
Write-Host ""
Write-Host "=== VERIFICACION ===" -ForegroundColor Cyan
Write-Host "BODEGA en config.html:"
Select-String -Path "C:\planta-rapel-2026\config.html" -Pattern 'value="BODEGA"|value="FRIGORIFICO"|value="ARANDANO"'
Write-Host ""
Write-Host "btnInicio en archivos:"
Select-String -Path "C:\planta-rapel-2026\config.html","C:\planta-rapel-2026\scanner.html","C:\planta-rapel-2026\js\config-inicial.js","C:\planta-rapel-2026\js\scanner.js" -Pattern 'btnInicio'

# ============================================
# UPDATE VERSION + PUSH
# ============================================
$version = (Get-Date).ToString('yyyyMMdd-HHmmss')
[System.IO.File]::WriteAllText("C:\planta-rapel-2026\version.json", "{`"version`": `"$version`"}", $utf8)

git add .
git commit -m "Bloque A: Zona/Packing + boton Inicio + Finalizar Registro"
git push

Write-Host ""
Write-Host "===== BLOQUE A LISTO =====" -ForegroundColor Green