cd C:\planta-rapel-2026
$utf8 = [System.Text.UTF8Encoding]::new($true)

# === Agregar columna Fecha en dashboard.html ===
$htmlPath = "C:\planta-rapel-2026\dashboard.html"
$h = Get-Content $htmlPath -Raw

# Tabla Asistencias: agregar Fecha antes de Hora
$oldAsist = "<th>Hora</th><th>DNI</th><th>Nombre</th><th>Empresa</th><th>Ruta</th>`r`n              <th>Bus</th><th>Turno</th><th>Zona</th><th>Encargado</th>"
$newAsist = "<th>Fecha</th><th>Hora</th><th>DNI</th><th>Nombre</th><th>Empresa</th><th>Ruta</th><th>Bus</th><th>Turno</th><th>Zona</th><th>Encargado</th>"
$h = $h.Replace($oldAsist, $newAsist)

# Tabla Faltantes: agregar Fecha antes de Hora
$oldFalt = "<th>Hora</th><th>DNI</th><th>Nombre</th><th>Empresa</th><th>Ruta</th>`r`n              <th>Bus</th><th>Motivo</th><th>Observacion</th><th>Encargado</th>"
$newFalt = "<th>Fecha</th><th>Hora</th><th>DNI</th><th>Nombre</th><th>Empresa</th><th>Ruta</th><th>Bus</th><th>Motivo</th><th>Observacion</th><th>Encargado</th>"
$h = $h.Replace($oldFalt, $newFalt)

# Por si las lineas estan unidas sin newlines, intentar tambien sin \r\n
$h = $h.Replace("<th>Hora</th><th>DNI</th><th>Nombre</th><th>Empresa</th><th>Ruta</th><th>Bus</th><th>Turno</th><th>Zona</th><th>Encargado</th>", "<th>Fecha</th><th>Hora</th><th>DNI</th><th>Nombre</th><th>Empresa</th><th>Ruta</th><th>Bus</th><th>Turno</th><th>Zona</th><th>Encargado</th>")
$h = $h.Replace("<th>Hora</th><th>DNI</th><th>Nombre</th><th>Empresa</th><th>Ruta</th><th>Bus</th><th>Motivo</th><th>Observacion</th><th>Encargado</th>", "<th>Fecha</th><th>Hora</th><th>DNI</th><th>Nombre</th><th>Empresa</th><th>Ruta</th><th>Bus</th><th>Motivo</th><th>Observacion</th><th>Encargado</th>")

[System.IO.File]::WriteAllText($htmlPath, $h, $utf8)
Write-Host "dashboard.html: columna Fecha agregada" -ForegroundColor Green

# === Agregar fecha en dashboard.js (renderTablaAsist y renderTablaFalt) ===
$jsPath = "C:\planta-rapel-2026\js\dashboard.js"
$j = Get-Content $jsPath -Raw

# renderTablaAsist: agregar td fecha
$j = $j.Replace("'<tr>' +`r`n    '<td>' + escapeHtml(a.hora) + '</td>'", "'<tr>' + '<td>' + escapeHtml(a.fecha) + '</td>' + '<td>' + escapeHtml(a.hora) + '</td>'")
# Por si esta en una sola linea
$j = $j.Replace("'<tr>' + '<td>' + escapeHtml(a.hora)", "'<tr>' + '<td>' + escapeHtml(a.fecha) + '</td>' + '<td>' + escapeHtml(a.hora)")

# renderTablaFalt: agregar td fecha
$j = $j.Replace("'<tr>' + '<td>' + escapeHtml(f.hora)", "'<tr>' + '<td>' + escapeHtml(f.fecha) + '</td>' + '<td>' + escapeHtml(f.hora)")

# Ajustar colspan de "sin datos" de 9 a 10
$j = $j.Replace("colspan=`"9`" class=`"text-center text-muted py-3`">Sin asistencias", "colspan=`"10`" class=`"text-center text-muted py-3`">Sin asistencias")
$j = $j.Replace("colspan=`"9`" class=`"text-center text-muted py-3`">Sin faltantes", "colspan=`"10`" class=`"text-center text-muted py-3`">Sin faltantes")

[System.IO.File]::WriteAllText($jsPath, $j, $utf8)
Write-Host "dashboard.js: render con columna Fecha" -ForegroundColor Green

# Verificacion
Write-Host ""
Write-Host "Verificacion:" -ForegroundColor Cyan
Select-String -Path $jsPath -Pattern "escapeHtml\(a\.fecha\)|escapeHtml\(f\.fecha\)"

# Actualizar version
$version = (Get-Date).ToString('yyyyMMdd-HHmmss')
[System.IO.File]::WriteAllText("C:\planta-rapel-2026\version.json", "{`"version`": `"$version`"}", $utf8)

git add .
git commit -m "Dashboard: agregar columna Fecha y formatear Hora correctamente"
git push

Write-Host ""
Write-Host "===== LISTO =====" -ForegroundColor Green