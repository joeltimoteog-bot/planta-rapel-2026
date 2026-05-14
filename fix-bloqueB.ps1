$utf8 = [System.Text.UTF8Encoding]::new($true)
$nl = "`r`n"

# ============================================
# 1. CONFIG.HTML - Agregar inputs ausente + total
# ============================================
$path = "C:\planta-rapel-2026\config.html"
$c = Get-Content $path -Raw

# Replace 1: agregar inputs nuevos despues del input cantidad
$oldBlock = @'
            <label class="form-label small fw-bold">Cantidad de personal asistente</label>
            <input type="number" class="form-control" id="cantidad" placeholder="Ej: 50" min="1" max="200" required>
'@

$newBlock = @'
            <label class="form-label small fw-bold">Cantidad de personal asistente</label>
            <input type="number" class="form-control" id="cantidad" placeholder="Ej: 45" min="1" max="200" enterkeyhint="next" required>
          </div>

          <div class="mb-3">
            <label class="form-label small fw-bold">Cantidad de personal ausente</label>
            <input type="number" class="form-control" id="cantidadAusente" placeholder="0" min="0" max="100" value="0" enterkeyhint="next">
          </div>

          <div class="mb-3">
            <label class="form-label small fw-bold">Total de personal programado</label>
            <input type="number" class="form-control" id="cantidadTotal" readonly style="background:#e9ecef; font-weight:bold; font-size:1.2rem;">
'@

$c = $c.Replace($oldBlock, $newBlock)

# Replace 2-5: agregar enterkeyhint a otros inputs
$c = $c.Replace('id="ruta" placeholder="Ej: CHAPAIRA" autocapitalize="characters" required>', 'id="ruta" placeholder="Ej: CHAPAIRA" autocapitalize="characters" enterkeyhint="next" required>')
$c = $c.Replace('id="codigoBus" placeholder="Ej: BUS-001" autocapitalize="characters" required>', 'id="codigoBus" placeholder="Ej: BUS-001" autocapitalize="characters" enterkeyhint="next" required>')
$c = $c.Replace('id="placa" placeholder="Ej: ABC-123" autocapitalize="characters" required>', 'id="placa" placeholder="Ej: ABC-123" autocapitalize="characters" enterkeyhint="next" required>')
$c = $c.Replace('id="dniEncargado" placeholder="8 d&iacute;gitos" inputmode="numeric" maxlength="8" required>', 'id="dniEncargado" placeholder="8 d&iacute;gitos" inputmode="numeric" maxlength="8" enterkeyhint="done" required>')

[System.IO.File]::WriteAllText($path, $c, $utf8)
Write-Host "config.html OK: 2 inputs nuevos + enterkeyhint" -ForegroundColor Green

# ============================================
# 2. CONFIG-INICIAL.JS - Auto-focus + total + auto-submit
# ============================================
$path = "C:\planta-rapel-2026\js\config-inicial.js"
$j = Get-Content $path -Raw

# Insertar funciones de auto-focus y calcular total
$insertarBloque = @'
  let encargadoValidado = null;
'@

$nuevoBloque = @'
  let encargadoValidado = null;
  
  // ==== AUTO-FOCUS SECUENCIAL ====
  function setFocusSiguiente(currentId, nextId) {
    const el = document.getElementById(currentId);
    if (!el) return;
    if (el.tagName === 'SELECT') {
      el.addEventListener('change', () => {
        if (el.value) {
          const next = document.getElementById(nextId);
          if (next) setTimeout(() => next.focus(), 50);
        }
      });
    } else {
      el.addEventListener('keydown', (e) => {
        if (e.key === 'Enter') {
          e.preventDefault();
          if (el.value.trim()) {
            const next = document.getElementById(nextId);
            if (next) next.focus();
          }
        }
      });
    }
  }
  setFocusSiguiente('zonaPacking', 'turno');
  setFocusSiguiente('turno', 'ruta');
  setFocusSiguiente('ruta', 'codigoBus');
  setFocusSiguiente('codigoBus', 'placa');
  setFocusSiguiente('placa', 'cantidad');
  setFocusSiguiente('cantidad', 'cantidadAusente');
  setFocusSiguiente('cantidadAusente', 'dniEncargado');
  
  // ==== CALCULO AUTOMATICO DEL TOTAL ====
  function calcularTotal() {
    const a = parseInt(document.getElementById('cantidad').value) || 0;
    const u = parseInt(document.getElementById('cantidadAusente').value) || 0;
    document.getElementById('cantidadTotal').value = a + u;
  }
  document.getElementById('cantidad').addEventListener('input', calcularTotal);
  document.getElementById('cantidadAusente').addEventListener('input', calcularTotal);
'@

$j = $j.Replace($insertarBloque, $nuevoBloque)

# Cambiar listener DNI encargado: usar 'input' + auto-submit al validar OK
$oldBlur = @'
  inputDni.addEventListener('blur', async () => {
    const dni = inputDni.value.trim();
    if (dni.length < 8) {
      encargadoValidado = null;
      cardEncargado.classList.add('d-none');
      return;
    }
    await validarDniEncargado(dni);
  });
'@

$newInput = @'
  // Validar DNI al llegar a 8 digitos + auto-submit si OK
  inputDni.addEventListener('input', async (e) => {
    const dni = e.target.value.replace(/\D/g, '');
    e.target.value = dni;
    if (dni.length < 8) {
      encargadoValidado = null;
      cardEncargado.classList.add('d-none');
      return;
    }
    if (dni.length === 8) {
      const ok = await validarDniEncargado(dni);
      if (ok && form.checkValidity()) {
        // Auto-submit despues de 600ms (deja ver la confirmacion)
        setTimeout(() => btn.click(), 600);
      }
    }
  });
'@

$j = $j.Replace($oldBlur, $newInput)

# Cambiar BusConfig.guardar para incluir cantidadAusente y cantidadTotal
$oldGuardar = @'
    BusConfig.guardar({
      zonaPacking: zonaPacking,
      turno: turno,
      ruta: ruta,
      codigoBus: codigoBus,
      placa: placa,
      cantidadAsistente: cantidad,
      encargadoDni: encargadoValidado.dni,
      encargadoNombre: encargadoValidado.nombre,
      encargadoEmpresa: encargadoValidado.empresa,
      iniciadoAt: new Date().toISOString()
    });
'@

$newGuardar = @'
    const cantidadAusente = parseInt(document.getElementById('cantidadAusente').value) || 0;
    const cantidadTotal = cantidad + cantidadAusente;
    BusConfig.guardar({
      zonaPacking: zonaPacking,
      turno: turno,
      ruta: ruta,
      codigoBus: codigoBus,
      placa: placa,
      cantidadAsistente: cantidad,
      cantidadAusente: cantidadAusente,
      cantidadTotal: cantidadTotal,
      encargadoDni: encargadoValidado.dni,
      encargadoNombre: encargadoValidado.nombre,
      encargadoEmpresa: encargadoValidado.empresa,
      iniciadoAt: new Date().toISOString()
    });
'@

$j = $j.Replace($oldGuardar, $newGuardar)

[System.IO.File]::WriteAllText($path, $j, $utf8)
Write-Host "config-inicial.js OK: auto-focus + total + auto-submit" -ForegroundColor Green

# ============================================
# 3. SCANNER.HTML - Mostrar ausentes + total
# ============================================
$path = "C:\planta-rapel-2026\scanner.html"
$s = Get-Content $path -Raw

$s = $s.Replace(
  '<div class="small mt-1">de <span id="cantidadEsperada">0</span> esperados</div>',
  '<div class="small mt-1">de <span id="cantidadEsperada">0</span> esperados</div>' + $nl + '      <div class="small" style="color:#ffc107;">Ausentes: <span id="lblCantAusente">0</span> | Total Programado: <span id="lblCantTotal">0</span></div>'
)

[System.IO.File]::WriteAllText($path, $s, $utf8)
Write-Host "scanner.html OK: info ausentes/total" -ForegroundColor Green

# ============================================
# 4. SCANNER.JS - mostrar info + logica finalizar
# ============================================
$path = "C:\planta-rapel-2026\js\scanner.js"
$sj = Get-Content $path -Raw

# Mostrar lblCantAusente y lblCantTotal
$oldShow = "document.getElementById('cantidadEsperada').textContent = config.cantidadAsistente;"
$newShow = @'
document.getElementById('cantidadEsperada').textContent = config.cantidadAsistente;
  const elAus = document.getElementById('lblCantAusente');
  const elTot = document.getElementById('lblCantTotal');
  if (elAus) elAus.textContent = config.cantidadAusente || 0;
  if (elTot) elTot.textContent = config.cantidadTotal || config.cantidadAsistente;
'@
$sj = $sj.Replace($oldShow, $newShow.TrimEnd())

# Nueva logica de finalizar (incluye ausentes + faltantes del bus)
$oldFinalizar = @'
    const faltan = config.cantidadAsistente - asistencias.length;

    if (faltan > 0) {
      const msg = 'Asistencias: ' + asistencias.length + '\n' +
                  'Esperados: ' + config.cantidadAsistente + '\n' +
                  'Faltan: ' + faltan + '\n\n' +
                  'Ir a registrar los faltantes?';
      if (!confirm(msg)) return;
      window.location.href = 'faltantes.html?faltan=' + faltan;
    } else {
'@

$newFinalizar = @'
    const faltantesDelBus = Math.max(0, config.cantidadAsistente - asistencias.length);
    const ausentesConfig = parseInt(config.cantidadAusente) || 0;
    const totalFaltantesRegistrar = faltantesDelBus + ausentesConfig;

    if (totalFaltantesRegistrar > 0) {
      const msg = 'Asistencias registradas: ' + asistencias.length + '\n' +
                  'Esperados (asistentes): ' + config.cantidadAsistente + '\n' +
                  'Faltantes del bus: ' + faltantesDelBus + '\n' +
                  'Ausentes conocidos: ' + ausentesConfig + '\n' +
                  'Total a registrar (DNI + motivo): ' + totalFaltantesRegistrar + '\n\n' +
                  'Ir a registrar los faltantes?';
      if (!confirm(msg)) return;
      window.location.href = 'faltantes.html?faltan=' + totalFaltantesRegistrar;
    } else {
'@

$sj = $sj.Replace($oldFinalizar, $newFinalizar)

[System.IO.File]::WriteAllText($path, $sj, $utf8)
Write-Host "scanner.js OK: info y logica finalizar actualizadas" -ForegroundColor Green

# ============================================
# 5. DASHBOARD.HTML - Select rutas + Total Programado card
# ============================================
$path = "C:\planta-rapel-2026\dashboard.html"
$d = Get-Content $path -Raw

# Cambiar input texto a select para rutas
$d = $d.Replace(
  '<input type="text" class="form-control form-control-sm" id="filtroRuta" placeholder="Todas">',
  '<select class="form-select form-select-sm" id="filtroRuta"><option value="">Todas</option></select>'
)

# Reemplazar card Periodo por Total Programado (mover periodo arriba)
$oldPeriodoCard = @'
    <div class="col-md-3">
      <div class="card text-white bg-secondary">
        <div class="card-body py-3 text-center">
          <div class="small">Periodo</div>
          <div style="font-size:1rem; font-weight:bold; padding-top:18px;" id="periodo">-</div>
        </div>
      </div>
    </div>
'@

$newProgramadoCard = @'
    <div class="col-md-3">
      <div class="card text-white" style="background:#6c757d;">
        <div class="card-body py-3 text-center">
          <div class="small">Total Programado</div>
          <div style="font-size:2.5rem; font-weight:bold;" id="totalProgramado">-</div>
        </div>
      </div>
    </div>
'@

$d = $d.Replace($oldPeriodoCard, $newProgramadoCard)

# Agregar periodo arriba de las cards (mas chico)
$d = $d.Replace(
  '<!-- Resumen -->',
  '<div class="small text-muted text-end mb-2">Periodo: <span id="periodo" class="fw-bold">-</span></div>' + $nl + '  <!-- Resumen -->'
)

[System.IO.File]::WriteAllText($path, $d, $utf8)
Write-Host "dashboard.html OK: select rutas + Total Programado" -ForegroundColor Green

# ============================================
# 6. DASHBOARD.JS - poblar rutas + totalProgramado
# ============================================
$path = "C:\planta-rapel-2026\js\dashboard.js"
$dj = Get-Content $path -Raw

# Calcular y mostrar Total Programado en cargarDashboard
$oldStats = "document.getElementById('periodo').textContent = r.fechaInicio + ' al ' + r.fechaFin;"
$newStats = @'
document.getElementById('periodo').textContent = r.fechaInicio + ' al ' + r.fechaFin;
    
    // Total Programado = Asistencias + Faltantes
    const totalProg = r.totalAsistencias + r.totalFaltantes;
    const elTP = document.getElementById('totalProgramado');
    if (elTP) elTP.textContent = totalProg;
    
    // Poblar select de rutas dinamicamente
    poblarRutasDinamicas();
'@
$dj = $dj.Replace($oldStats, $newStats.TrimEnd())

# Agregar funcion poblarRutasDinamicas al final si no existe
if ($dj -notmatch 'poblarRutasDinamicas') {
  $funcionRutas = @'


function poblarRutasDinamicas() {
  const select = document.getElementById('filtroRuta');
  if (!select || select.tagName !== 'SELECT') return;
  const rutaActual = select.value;
  
  const rutas = new Set();
  asistenciasData.forEach(a => { if (a.ruta_sesion) rutas.add(String(a.ruta_sesion).toUpperCase()); });
  faltantesData.forEach(f => { if (f.ruta) rutas.add(String(f.ruta).toUpperCase()); });
  
  let html = '<option value="">Todas</option>';
  Array.from(rutas).sort().forEach(r => {
    const sel = (r === rutaActual) ? ' selected' : '';
    html += '<option value="' + r + '"' + sel + '>' + r + '</option>';
  });
  select.innerHTML = html;
}
'@
  $dj = $dj + $funcionRutas
}

[System.IO.File]::WriteAllText($path, $dj, $utf8)
Write-Host "dashboard.js OK: totalProgramado + poblarRutasDinamicas" -ForegroundColor Green

# ============================================
# VERIFICACION
# ============================================
Write-Host ""
Write-Host "=== Verificacion ===" -ForegroundColor Cyan
Write-Host "config.html (nuevos inputs):"
Select-String -Path "C:\planta-rapel-2026\config.html" -Pattern "cantidadAusente|cantidadTotal"
Write-Host ""
Write-Host "scanner.html (nuevos labels):"
Select-String -Path "C:\planta-rapel-2026\scanner.html" -Pattern "lblCantAusente|lblCantTotal"
Write-Host ""
Write-Host "dashboard.html (totalProgramado):"
Select-String -Path "C:\planta-rapel-2026\dashboard.html" -Pattern "totalProgramado|filtroRuta"

# ============================================
# UPDATE VERSION + PUSH
# ============================================
$version = (Get-Date).ToString('yyyyMMdd-HHmms