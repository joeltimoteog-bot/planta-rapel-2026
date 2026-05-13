cd C:\planta-rapel-2026
$utf8 = [System.Text.UTF8Encoding]::new($true)

# === Modificar scanner.html: agregar botón manual + modal + contador desglosado ===
$htmlPath = "C:\planta-rapel-2026\scanner.html"
$h = Get-Content $htmlPath -Raw

# 1. Reemplazar el card del contador con uno que muestre QR + Manual
$oldContador = '<div class="card mb-3 text-white" style="background:#1a3a6c;">'
if ($h.IndexOf($oldContador) -ge 0) {
  # Encontrar el cierre del card del contador y reemplazar
  $cardContadorOld = '<div class="card mb-3 text-white" style="background:#1a3a6c;">'
  $cardContadorNew = @'
<div class="card mb-3 text-white" style="background:#1a3a6c;" id="cardContador">
'@
  $h = $h.Replace($cardContadorOld, $cardContadorNew)
}

# Reemplazar el contador interno
$contadorOld = '<div class="small mb-1">Asistentes escaneados</div>'
$contadorNew = '<div class="small mb-1">Asistentes registrados</div>'
$h = $h.Replace($contadorOld, $contadorNew)

# Agregar desglose despues del "de X esperados"
$desgloseOld = '<div class="small mt-1">de <span id="cantidadEsperada">0</span> esperados</div>'
$desgloseNew = @'
<div class="small mt-1">de <span id="cantidadEsperada">0</span> esperados</div>
      <div class="mt-2">
        <span class="badge bg-success me-1">QR: <span id="contadorQR">0</span></span>
        <span class="badge bg-warning text-dark">Manual: <span id="contadorManual">0</span></span>
      </div>
'@
$h = $h.Replace($desgloseOld, $desgloseNew)

# Agregar boton "Buscar DNI manualmente" antes del btnFinalizar
$btnFinalizarOld = '<button id="btnFinalizar" class="btn btn-lg w-100 mt-3"'
$btnManualHtml = @'
<button class="btn btn-warning w-100 mt-2" id="btnBuscarManual">
    <strong>+</strong> Ingresar DNI manualmente (fotocheck danado)
  </button>
  
  <!-- Modal busqueda manual -->
  <div class="modal fade" id="modalManual" tabindex="-1">
    <div class="modal-dialog modal-dialog-centered">
      <div class="modal-content">
        <div class="modal-header" style="background:#ffc107;">
          <h5 class="modal-title">Buscar DNI manualmente</h5>
          <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
        </div>
        <div class="modal-body">
          <label class="form-label">DNI del trabajador (8 digitos)</label>
          <input type="text" inputmode="numeric" pattern="[0-9]*" maxlength="8" 
                 class="form-control form-control-lg text-center fs-3" id="inputDniManual"
                 placeholder="00000000" style="letter-spacing:5px;">
          <div id="msgManual" class="mt-2 small"></div>
          <div id="resultadoManual" class="mt-3" style="display:none;"></div>
        </div>
        <div class="modal-footer">
          <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancelar</button>
          <button type="button" class="btn btn-warning" id="btnBuscarDniManual">Buscar</button>
        </div>
      </div>
    </div>
  </div>
  
  <button id="btnFinalizar" class="btn btn-lg w-100 mt-3"
'@
$h = $h.Replace($btnFinalizarOld, $btnManualHtml)

[System.IO.File]::WriteAllText($htmlPath, $h, $utf8)
Write-Host "scanner.html: boton manual + contador desglosado" -ForegroundColor Green

# === Modificar scanner.js: agregar logica de busqueda manual ===
$jsPath = "C:\planta-rapel-2026\js\scanner.js"
$j = Get-Content $jsPath -Raw

# Insertar contador QR/Manual + listener del boton manual al final del DOMContentLoaded
# La idea: cargar contadores al inicio, contar en cada scan (QR vs Manual), y agregar boton manual

# 1. Cambiar actualizarContador para que muestre desglose
$actualOld = @'
  function actualizarContador() {
    document.getElementById('contador').textContent = asistencias.length;
    btnFinalizar.style.display = asistencias.length > 0 ? 'block' : 'none';
  }
'@

$actualNew = @'
  function actualizarContador() {
    document.getElementById('contador').textContent = asistencias.length;
    btnFinalizar.style.display = asistencias.length > 0 ? 'block' : 'none';
    
    // Contar QR vs Manual
    let qr = 0, manual = 0;
    for (const a of asistencias) {
      if (a.tipoRegistro === 'MANUAL') manual++;
      else qr++;
    }
    const elQR = document.getElementById('contadorQR');
    const elMan = document.getElementById('contadorManual');
    if (elQR) elQR.textContent = qr;
    if (elMan) elMan.textContent = manual;
  }
'@

$j = $j.Replace($actualOld, $actualNew)

# 2. Agregar listener del boton manual y la funcion buscarDniManual
# Lo agregamos al final del DOMContentLoaded, antes del }) final
$inicioCamaraOld = 'cardPreparando.style.display = ''none'';
  iniciarCamara();'

$inicioCamaraNew = @'
cardPreparando.style.display = 'none';
  iniciarCamara();
  
  // ===== BUSQUEDA MANUAL =====
  document.getElementById('btnBuscarManual').addEventListener('click', () => {
    document.getElementById('inputDniManual').value = '';
    document.getElementById('msgManual').textContent = '';
    document.getElementById('msgManual').className = 'mt-2 small';
    document.getElementById('resultadoManual').style.display = 'none';
    const modal = new bootstrap.Modal(document.getElementById('modalManual'));
    modal.show();
    setTimeout(() => document.getElementById('inputDniManual').focus(), 300);
  });
  
  document.getElementById('inputDniManual').addEventListener('keydown', (e) => {
    if (e.key === 'Enter') {
      e.preventDefault();
      buscarDniManual();
    }
  });
  
  document.getElementById('btnBuscarDniManual').addEventListener('click', buscarDniManual);
  
  async function buscarDniManual() {
    const input = document.getElementById('inputDniManual');
    const msg = document.getElementById('msgManual');
    const resultado = document.getElementById('resultadoManual');
    
    const dni = String(input.value).trim().padStart(8, '0');
    if (dni.length !== 8 || !/^\d{8}$/.test(dni)) {
      msg.textContent = 'DNI invalido. Ingresa 8 digitos numericos.';
      msg.className = 'mt-2 small text-danger';
      return;
    }
    
    if (dnisRegistrados.has(dni)) {
      msg.textContent = 'Este DNI ya fue registrado en esta sesion';
      msg.className = 'mt-2 small text-warning fw-bold';
      return;
    }
    
    msg.textContent = 'Buscando...';
    msg.className = 'mt-2 small text-muted';
    
    const resp = await API.validarTrabajador(dni);
    
    if (!resp.ok) {
      msg.textContent = 'No encontrado: ' + (resp.error || dni);
      msg.className = 'mt-2 small text-danger';
      return;
    }
    
    // Mostrar info encontrada
    const t = resp.trabajador;
    resultado.style.display = 'block';
    resultado.innerHTML = '<div class="card border-success"><div class="card-body py-2">' +
      '<strong>' + (t.nombre || '-') + '</strong><br>' +
      '<small>DNI: ' + t.dni + ' | Ruta: ' + (t.ruta || '-') + ' | Empresa: ' + t.empresa + '</small><br>' +
      '<button class="btn btn-success btn-sm mt-2" id="btnConfirmarManual">Confirmar y registrar</button>' +
      '</div></div>';
    msg.textContent = '';
    
    document.getElementById('btnConfirmarManual').addEventListener('click', () => {
      const nuevaAsist = {
        dni: t.dni,
        nombre: t.nombre,
        empresa: t.empresa,
        ruta_trabajador: t.ruta,
        tipoRegistro: 'MANUAL'
      };
      dnisRegistrados.add(t.dni);
      asistencias.push(nuevaAsist);
      sessionStorage.setItem('planta_asistencias', JSON.stringify(asistencias));
      actualizarContador();
      beep(880, 120, 0.2);
      if (navigator.vibrate) navigator.vibrate(80);
      guardarAsistenciaIndividual(nuevaAsist);
      
      // Cerrar modal
      bootstrap.Modal.getInstance(document.getElementById('modalManual')).hide();
    });
  }
'@

$j = $j.Replace($inicioCamaraOld, $inicioCamaraNew)

[System.IO.File]::WriteAllText($jsPath, $j, $utf8)
Write-Host "scanner.js: logica de busqueda manual agregada" -ForegroundColor Green

# Verificar
Write-Host ""
Write-Host "Verificacion:" -ForegroundColor Cyan
Select-String -Path $jsPath -Pattern "buscarDniManual|contadorQR|tipoRegistro.*MANUAL"

# Update version
$version = (Get-Date).ToString('yyyyMMdd-HHmmss')
[System.IO.File]::WriteAllText("C:\planta-rapel-2026\version.json", "{`"version`": `"$version`"}", $utf8)

git add .
git commit -m "Scanner: busqueda manual de DNI + contador desglosado QR/Manual"
git push

Write-Host ""
Write-Host "===== LISTO =====" -ForegroundColor Green