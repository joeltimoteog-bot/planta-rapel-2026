cd C:\planta-rapel-2026

$utf8 = [System.Text.UTF8Encoding]::new($true)

# === api.js con registrarAsistencias ===
$apiJs = @'
const API = {
  async call(accion, params = {}) {
    if (!CONFIG.API_URL || CONFIG.API_URL.startsWith('PEGAR')) {
      return { ok: false, error: 'API_URL no configurada en config.js' };
    }
    try {
      const response = await fetch(CONFIG.API_URL, {
        method: 'POST',
        mode: 'cors',
        headers: { 'Content-Type': 'text/plain;charset=utf-8' },
        body: JSON.stringify({ accion, ...params })
      });
      return await response.json();
    } catch (err) {
      console.error('API error:', err);
      return { ok: false, error: 'Error de conexion: ' + err.message };
    }
  },
  login(username, password) { return this.call('login', { username, password }); },
  validarTrabajador(dni, empresa) { return this.call('validarTrabajador', { dni, empresa }); },
  registrarAsistencias(asistencias, sesion) { return this.call('registrarAsistencias', { asistencias, sesion }); },
  ping() { return this.call('ping'); }
};
'@
[System.IO.File]::WriteAllText("C:\planta-rapel-2026\js\api.js", $apiJs, $utf8)
Write-Host "api.js OK" -ForegroundColor Green

# === config.html con Zona/Packing + Turno ===
$configHtml = @'
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <meta name="theme-color" content="#c8102e">
  <title>Configuraci&oacute;n - Planta Rapel 2026</title>
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
  <link href="css/styles.css" rel="stylesheet">
</head>
<body>
  <nav class="navbar navbar-dark" style="background:#1a3a6c;">
    <div class="container-fluid">
      <span class="navbar-brand mb-0 h6 d-flex align-items-center">
        <img src="assets/logo-unifrutti.png" alt="Unifrutti" class="logo-navbar" onerror="this.style.display='none';">
        Planta Rapel 2026
      </span>
      <button class="btn btn-sm btn-outline-light" id="btnLogout">Salir</button>
    </div>
  </nav>
  
  <div class="container py-3">
    <div class="card shadow-sm">
      <div class="card-body p-3">
        <h5 class="mb-1" style="color:#1a3a6c;">Configuraci&oacute;n de Ruta</h5>
        <p class="text-muted small mb-3">Complete los datos antes de iniciar el escaneo</p>
        
        <form id="formConfig" novalidate>
          <div class="mb-3">
            <label class="form-label small fw-bold">Zona / Packing</label>
            <select class="form-select" id="zonaPacking" required>
              <option value="">Seleccione...</option>
              <option value="PUV 01">PUV 01</option>
              <option value="PUV 02">PUV 02</option>
              <option value="PUV 03">PUV 03</option>
              <option value="PUV 04">PUV 04</option>
              <option value="PUV 05">PUV 05</option>
              <option value="PUV 06">PUV 06</option>
              <option value="PUV 07">PUV 07</option>
              <option value="PUV 08">PUV 08</option>
              <option value="ARANDANOS">ARANDANOS</option>
              <option value="PALTA">PALTA</option>
              <option value="LIMON">LIMON</option>
              <option value="BODEGA FRIGORIFICOS">BODEGA FRIGORIFICOS</option>
            </select>
          </div>
          
          <div class="mb-3">
            <label class="form-label small fw-bold">Turno</label>
            <select class="form-select" id="turno" required>
              <option value="">Seleccione...</option>
              <option value="DIA">D&Iacute;A</option>
              <option value="NOCHE">NOCHE</option>
            </select>
          </div>
          
          <div class="mb-3">
            <label class="form-label small fw-bold">Ruta</label>
            <input type="text" class="form-control" id="ruta" placeholder="Ej: CHAPAIRA" autocapitalize="characters" required>
          </div>
          
          <div class="mb-3">
            <label class="form-label small fw-bold">C&oacute;digo del Bus</label>
            <input type="text" class="form-control" id="codigoBus" placeholder="Ej: BUS-001" autocapitalize="characters" required>
          </div>
          
          <div class="mb-3">
            <label class="form-label small fw-bold">Placa del Bus</label>
            <input type="text" class="form-control" id="placa" placeholder="Ej: ABC-123" autocapitalize="characters" required>
          </div>
          
          <div class="mb-3">
            <label class="form-label small fw-bold">Cantidad de personal asistente</label>
            <input type="number" class="form-control" id="cantidad" placeholder="Ej: 50" min="1" max="200" required>
          </div>
          
          <hr class="my-3">
          
          <div class="mb-3">
            <label class="form-label small fw-bold">DNI del Encargado</label>
            <input type="text" class="form-control" id="dniEncargado" placeholder="8 d&iacute;gitos" inputmode="numeric" maxlength="8" required>
            <p class="text-muted small mt-1 mb-0">Se validar&aacute; contra la base y se registrar&aacute; como encargado</p>
          </div>
          
          <div id="msgError" class="alert alert-danger d-none py-2 small" role="alert"></div>
          
          <div id="cardEncargado" class="alert alert-success d-none py-2" role="alert">
            <p class="mb-1 small"><strong>Encargado identificado:</strong></p>
            <p class="mb-0" id="lblNombreEncargado">-</p>
          </div>
          
          <button type="submit" class="btn btn-primary btn-lg w-100 mt-2" id="btnIniciar">Iniciar Escaneo</button>
        </form>
      </div>
    </div>
  </div>
  
  <script src="js/config.js"></script>
  <script src="js/api.js"></script>
  <script src="js/auth.js"></script>
  <script src="js/config-inicial.js"></script>
</body>
</html>
'@
[System.IO.File]::WriteAllText("C:\planta-rapel-2026\config.html", $configHtml, $utf8)
Write-Host "config.html OK" -ForegroundColor Green

# === config-inicial.js con turno + zonaPacking ===
$configInicialJs = @'
document.addEventListener('DOMContentLoaded', () => {
  if (!Auth.requiereLogin()) return;
  
  const form = document.getElementById('formConfig');
  const btn = document.getElementById('btnIniciar');
  const msgError = document.getElementById('msgError');
  const cardEncargado = document.getElementById('cardEncargado');
  const lblNombreEncargado = document.getElementById('lblNombreEncargado');
  const inputDni = document.getElementById('dniEncargado');
  
  let encargadoValidado = null;
  
  document.getElementById('btnLogout').addEventListener('click', () => {
    if (confirm('Salir de la sesion?')) Auth.cerrarSesion();
  });
  
  inputDni.addEventListener('blur', async () => {
    const dni = inputDni.value.trim();
    if (dni.length < 8) {
      encargadoValidado = null;
      cardEncargado.classList.add('d-none');
      return;
    }
    await validarDniEncargado(dni);
  });
  
  async function validarDniEncargado(dni) {
    const dniNorm = String(dni).trim().padStart(8, '0');
    msgError.classList.add('d-none');
    cardEncargado.classList.add('d-none');
    
    const resp = await API.validarTrabajador(dniNorm);
    
    if (!resp.ok) {
      mostrarError('DNI no encontrado en ninguna base.');
      encargadoValidado = null;
      return false;
    }
    
    encargadoValidado = resp.trabajador;
    lblNombreEncargado.textContent = resp.trabajador.nombre + ' (' + resp.trabajador.empresa + ')';
    cardEncargado.classList.remove('d-none');
    return true;
  }
  
  form.addEventListener('submit', async (e) => {
    e.preventDefault();
    msgError.classList.add('d-none');
    
    const zonaPacking = document.getElementById('zonaPacking').value;
    const turno = document.getElementById('turno').value;
    const ruta = document.getElementById('ruta').value.trim().toUpperCase();
    const codigoBus = document.getElementById('codigoBus').value.trim().toUpperCase();
    const placa = document.getElementById('placa').value.trim().toUpperCase();
    const cantidad = parseInt(document.getElementById('cantidad').value);
    const dni = inputDni.value.trim();
    
    if (!zonaPacking || !turno || !ruta || !codigoBus || !placa || !cantidad || !dni) {
      mostrarError('Complete todos los campos');
      return;
    }
    
    btn.disabled = true;
    btn.innerHTML = '<span class="spinner-border spinner-border-sm me-2"></span>Validando...';
    
    if (!encargadoValidado) {
      const ok = await validarDniEncargado(dni);
      if (!ok) {
        btn.disabled = false;
        btn.innerHTML = 'Iniciar Escaneo';
        return;
      }
    }
    
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
    
    // Limpiar asistencias previas
    sessionStorage.removeItem('planta_asistencias');
    
    window.location.href = 'scanner.html';
  });
  
  function mostrarError(msg) {
    msgError.textContent = msg;
    msgError.classList.remove('d-none');
  }
});
'@
[System.IO.File]::WriteAllText("C:\planta-rapel-2026\js\config-inicial.js", $configInicialJs, $utf8)
Write-Host "config-inicial.js OK" -ForegroundColor Green

# === scanner.html con contador grande + boton guardar ===
$scannerHtml = @'
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <meta name="theme-color" content="#c8102e">
  <title>Scanner QR - Planta Rapel 2026</title>
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
  <link href="css/styles.css" rel="stylesheet">
  <script src="https://unpkg.com/html5-qrcode@2.3.8/html5-qrcode.min.js"></script>
</head>
<body>
  <nav class="navbar navbar-dark" style="background:#1a3a6c;">
    <div class="container-fluid">
      <span class="navbar-brand mb-0 h6 d-flex align-items-center">
        <img src="assets/logo-unifrutti.png" alt="Unifrutti" class="logo-navbar" onerror="this.style.display='none';">
        Scanner QR
      </span>
      <a href="config.html" class="btn btn-sm btn-outline-light">Cambiar</a>
    </div>
  </nav>
  
  <div class="container py-3">
    
    <!-- Tarjeta info de la ruta -->
    <div class="card mb-3 shadow-sm" style="background:#f8f9fa;">
      <div class="card-body py-2">
        <div class="row g-1 small">
          <div class="col-6"><strong>Ruta:</strong> <span id="lblRuta">-</span></div>
          <div class="col-6"><strong>Bus:</strong> <span id="lblBus">-</span></div>
          <div class="col-6"><strong>Placa:</strong> <span id="lblPlaca">-</span></div>
          <div class="col-6"><strong>Turno:</strong> <span class="badge bg-dark" id="lblTurno">-</span></div>
          <div class="col-12 mt-1"><strong>Zona:</strong> <span id="lblZonaPacking">-</span></div>
          <div class="col-12 mt-1 text-muted"><small><strong>Encargado:</strong> <span id="lblEncargado">-</span></small></div>
        </div>
      </div>
    </div>
    
    <!-- Contador GRANDE -->
    <div class="card mb-3 shadow-sm" style="background:#1a3a6c; color:white;">
      <div class="card-body text-center py-3">
        <p class="mb-1 small">Asistentes escaneados</p>
        <h1 class="mb-0 display-3 fw-bold" id="contador">0</h1>
        <p class="mb-0 small opacity-75">de <span id="cantidadEsperada">0</span> esperados</p>
      </div>
    </div>
    
    <div id="cardPreparando" class="card mb-3 shadow-sm">
      <div class="card-body text-center py-3">
        <div class="spinner-border spinner-border-sm text-primary me-2" role="status"></div>
        <span>Preparando scanner...</span>
      </div>
    </div>
    
    <div id="reader" style="width: 100%; display:none;"></div>
    
    <div class="card mt-3 shadow-sm" id="cardBuscando" style="display:none;">
      <div class="card-body py-2 text-center">
        <div class="spinner-border spinner-border-sm text-primary me-2" role="status"></div>
        <span class="small">Buscando trabajador...</span>
      </div>
    </div>
    
    <div class="card mt-3 shadow-sm" id="cardResultado" style="display:none;">
      <div class="card-body py-3">
        <div class="d-flex justify-content-between align-items-start mb-2">
          <h5 class="mb-0" id="lblNombre" style="color:#1a3a6c;">-</h5>
          <span class="badge" id="lblEmpresaTrab" style="background:#c8102e;">-</span>
        </div>
        <p class="mb-1 small"><strong>DNI:</strong> <span id="lblDni">-</span></p>
        <p class="mb-1 small"><strong>Oficio:</strong> <span id="lblOficio">-</span></p>
        <p class="mb-1 small"><strong>Ruta asignada:</strong> <span class="badge bg-primary" id="lblRutaTrab">-</span> <span class="badge bg-warning ms-1" id="lblWarningRuta" style="display:none;">!= sesion</span></p>
        <p class="mb-0 small text-muted"><strong>Sector:</strong> <span id="lblZona">-</span></p>
      </div>
    </div>
    
    <div class="card mt-3 shadow-sm border-danger" id="cardError" style="display:none;">
      <div class="card-body py-3">
        <h5 class="mb-2 text-danger">No encontrado</h5>
        <p class="mb-0 small" id="lblErrorMsg">-</p>
      </div>
    </div>
    
    <!-- Boton finalizar -->
    <button class="btn btn-success btn-lg w-100 mt-3" id="btnFinalizar" style="display:none;">
      Finalizar y Guardar Asistencias
    </button>
    
  </div>
  
  <!-- Modal de exito -->
  <div class="modal fade" id="modalExito" tabindex="-1" data-bs-backdrop="static">
    <div class="modal-dialog modal-dialog-centered">
      <div class="modal-content">
        <div class="modal-header bg-success text-white">
          <h5 class="modal-title">Asistencias Registradas</h5>
        </div>
        <div class="modal-body">
          <p class="mb-2" id="lblMsgExito">-</p>
        </div>
        <div class="modal-footer">
          <button type="button" class="btn btn-primary" id="btnNuevaSesion">Nueva Sesi&oacute;n</button>
        </div>
      </div>
    </div>
  </div>
  
  <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"></script>
  <script src="js/config.js"></script>
  <script src="js/api.js"></script>
  <script src="js/auth.js"></script>
  <script src="js/scanner.js"></script>
</body>
</html>
'@
[System.IO.File]::WriteAllText("C:\planta-rapel-2026\scanner.html", $scannerHtml, $utf8)
Write-Host "scanner.html OK" -ForegroundColor Green

# === scanner.js con beep + acumulacion + guardado batch ===
$scannerJs = @'
// Helper para beep de feedback al escanear
function beep(freq, duration, volume) {
  try {
    const ctx = new (window.AudioContext || window.webkitAudioContext)();
    const osc = ctx.createOscillator();
    const gain = ctx.createGain();
    osc.connect(gain);
    gain.connect(ctx.destination);
    osc.frequency.value = freq || 880;
    osc.type = 'sine';
    gain.gain.value = volume || 0.2;
    osc.start();
    setTimeout(() => {
      osc.stop();
      ctx.close();
    }, duration || 120);
  } catch (e) {
    console.warn('Beep no soportado:', e);
  }
}

document.addEventListener('DOMContentLoaded', async () => {
  if (!Auth.requiereLogin()) return;
  
  const config = BusConfig.obtener();
  if (!config) {
    window.location.href = 'config.html';
    return;
  }
  
  let ultimoDni = null;
  let ultimoTimestamp = 0;
  let procesando = false;
  let dnisRegistrados = new Set();
  let asistencias = [];
  
  // Recuperar asistencias previas si hay (sobrevive refresh)
  const previas = sessionStorage.getItem('planta_asistencias');
  if (previas) {
    try {
      asistencias = JSON.parse(previas);
      asistencias.forEach(a => dnisRegistrados.add(a.dni));
    } catch (e) {}
  }
  
  // Mostrar info de la sesion
  document.getElementById('lblRuta').textContent = config.ruta;
  document.getElementById('lblBus').textContent = config.codigoBus;
  document.getElementById('lblPlaca').textContent = config.placa;
  document.getElementById('lblTurno').textContent = config.turno;
  document.getElementById('lblZonaPacking').textContent = config.zonaPacking;
  document.getElementById('lblEncargado').textContent = config.encargadoNombre;
  document.getElementById('cantidadEsperada').textContent = config.cantidadAsistente;
  actualizarContador();
  
  const cardPreparando = document.getElementById('cardPreparando');
  const cardBuscando = document.getElementById('cardBuscando');
  const cardResultado = document.getElementById('cardResultado');
  const cardError = document.getElementById('cardError');
  const reader = document.getElementById('reader');
  const btnFinalizar = document.getElementById('btnFinalizar');
  
  btnFinalizar.addEventListener('click', finalizar);
  document.getElementById('btnNuevaSesion').addEventListener('click', () => {
    sessionStorage.removeItem('planta_asistencias');
    BusConfig.limpiar();
    window.location.href = 'config.html';
  });
  
  await API.ping();
  cardPreparando.style.display = 'none';
  iniciarCamara();
  
  function iniciarCamara() {
    reader.style.display = 'block';
    const html5QrCode = new Html5Qrcode("reader");
    const cfgQr = { fps: 10, qrbox: { width: 250, height: 250 }, aspectRatio: 1.0 };
    html5QrCode.start(
      { facingMode: "environment" },
      cfgQr,
      onScanSuccess,
      function() {}
    ).catch(err => alert('Error camara: ' + err));
  }
  
  async function onScanSuccess(decodedText) {
    if (procesando) return;
    
    const dni = String(decodedText).trim().padStart(8, '0');
    const ahora = Date.now();
    
    if (dni === ultimoDni && (ahora - ultimoTimestamp) < 3000) return;
    
    ultimoDni = dni;
    ultimoTimestamp = ahora;
    procesando = true;
    
    if (navigator.vibrate) navigator.vibrate(80);
    
    cardResultado.style.display = 'none';
    cardError.style.display = 'none';
    cardBuscando.style.display = 'block';
    
    const resp = await API.validarTrabajador(dni);
    cardBuscando.style.display = 'none';
    
    if (resp.ok) {
      // Si ya estaba registrado, avisar pero no duplicar
      if (dnisRegistrados.has(resp.trabajador.dni)) {
        mostrarError('Este trabajador ya fue escaneado en esta sesion');
        beep(440, 200, 0.15); // tono mas grave (advertencia)
      } else {
        dnisRegistrados.add(resp.trabajador.dni);
        asistencias.push({
          dni: resp.trabajador.dni,
          nombre: resp.trabajador.nombre,
          empresa: resp.trabajador.empresa,
          ruta_trabajador: resp.trabajador.ruta,
          tipoRegistro: 'QR'
        });
        sessionStorage.setItem('planta_asistencias', JSON.stringify(asistencias));
        mostrarTrabajador(resp.trabajador);
        actualizarContador();
        beep(880, 120, 0.2); // tono OK
      }
    } else {
      mostrarError(resp.error || 'No encontrado');
      beep(220, 300, 0.2); // tono error grave
    }
    
    procesando = false;
  }
  
  function actualizarContador() {
    document.getElementById('contador').textContent = asistencias.length;
    btnFinalizar.style.display = asistencias.length > 0 ? 'block' : 'none';
  }
  
  function mostrarTrabajador(t) {
    cardResultado.style.display = 'block';
    document.getElementById('lblNombre').textContent = t.nombre || '-';
    document.getElementById('lblDni').textContent = t.dni || '-';
    document.getElementById('lblOficio').textContent = t.oficio || '-';
    document.getElementById('lblRutaTrab').textContent = t.ruta || 'SIN RUTA';
    document.getElementById('lblZona').textContent = t.zona || '-';
    document.getElementById('lblEmpresaTrab').textContent = t.empresa || '-';
    
    const warning = document.getElementById('lblWarningRuta');
    if (t.ruta && t.ruta.toUpperCase() !== config.ruta.toUpperCase()) {
      warning.style.display = 'inline';
    } else {
      warning.style.display = 'none';
    }
  }
  
  function mostrarError(msg) {
    cardError.style.display = 'block';
    document.getElementById('lblErrorMsg').textContent = msg;
  }
  
  async function finalizar() {
    if (!asistencias.length) return;
    if (!confirm('Guardar ' + asistencias.length + ' asistencias?')) return;
    
    btnFinalizar.disabled = true;
    btnFinalizar.innerHTML = '<span class="spinner-border spinner-border-sm me-2"></span>Guardando...';
    
    const resp = await API.registrarAsistencias(asistencias, config);
    
    if (!resp.ok) {
      alert('Error al guardar: ' + (resp.error || 'desconocido'));
      btnFinalizar.disabled = false;
      btnFinalizar.innerHTML = 'Finalizar y Guardar Asistencias';
      return;
    }
    
    // Limpiar local
    sessionStorage.removeItem('planta_asistencias');
    
    // Mensaje de exito
    const msg = 'Has registrado ' + resp.cantidad + ' asistencias de la ruta ' + 
                resp.ruta + ' - codigo ' + resp.codigoBus + ' - fecha ' + resp.fecha;
    document.getElementById('lblMsgExito').textContent = msg;
    
    const modal = new bootstrap.Modal(document.getElementById('modalExito'));
    modal.show();
  }
});
'@
[System.IO.File]::WriteAllText("C:\planta-rapel-2026\js\scanner.js", $scannerJs, $utf8)
Write-Host "scanner.js OK" -ForegroundColor Green

git add .
git commit -m "Asistencias: zona/packing, turno, beep, contador grande, guardado batch a Sheets"
git push

Write-Host ""
Write-Host "===== LISTO =====" -ForegroundColor Green
Write-Host "1. Verifica que ejecutaste actualizarSchemaAsistencias en Apps Script" -ForegroundColor Cyan
Write-Host "2. Verifica que redesplegaste la Nueva version" -ForegroundColor Cyan
Write-Host "3. Ctrl+F5 en el navegador" -ForegroundColor Cyan