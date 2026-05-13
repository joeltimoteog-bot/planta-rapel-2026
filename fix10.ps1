cd C:\planta-rapel-2026
$utf8 = [System.Text.UTF8Encoding]::new($true)

# === scanner.html ===
$scannerHtml = @'
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Scanner QR - Planta Rapel 2026</title>
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
<script src="https://unpkg.com/html5-qrcode@2.3.8/html5-qrcode.min.js"></script>
<link rel="stylesheet" href="css/styles.css">
</head>
<body>
<nav class="navbar navbar-dark" style="background:#1a3a6c;">
  <div class="container-fluid">
    <span class="navbar-brand">Scanner QR</span>
    <button class="btn btn-sm btn-light" id="btnNuevaSesion">Cambiar</button>
  </div>
</nav>
<div class="container my-3" style="max-width:600px;">
  <div class="card mb-3"><div class="card-body py-2"><div class="row small">
    <div class="col-6">
      <div><strong>Ruta:</strong> <span id="lblRuta"></span></div>
      <div><strong>Placa:</strong> <span id="lblPlaca"></span></div>
      <div><strong>Zona:</strong> <span id="lblZonaPacking"></span></div>
      <div><strong>Encargado:</strong> <span id="lblEncargado"></span></div>
    </div>
    <div class="col-6">
      <div><strong>Bus:</strong> <span id="lblBus"></span></div>
      <div><strong>Turno:</strong> <span class="badge bg-primary" id="lblTurno"></span></div>
    </div>
  </div></div></div>
  <div class="card mb-3 text-white" style="background:#1a3a6c;">
    <div class="card-body text-center py-3">
      <div class="small mb-1">Asistentes escaneados</div>
      <div style="font-size:3rem; font-weight:bold; line-height:1;" id="contador">0</div>
      <div class="small mt-1">de <span id="cantidadEsperada">0</span> esperados</div>
    </div>
  </div>
  <div id="cardPreparando" class="card mb-3"><div class="card-body text-center py-3">
    <div class="spinner-border spinner-border-sm text-primary me-2"></div>Preparando scanner...
  </div></div>
  <div id="reader" style="display:none;"></div>
  <div id="cardBuscando" class="card mt-3" style="display:none;"><div class="card-body text-center py-3">
    <div class="spinner-border spinner-border-sm text-primary me-2"></div>Buscando trabajador...
  </div></div>
  <div id="cardResultado" class="card border-success mt-3" style="display:none;"><div class="card-body">
    <h5 class="card-title text-success mb-2">Trabajador registrado</h5>
    <p class="mb-1"><strong id="lblNombre"></strong></p>
    <p class="mb-1 small">DNI: <span id="lblDni"></span></p>
    <p class="mb-1 small">Oficio: <span id="lblOficio"></span></p>
    <p class="mb-1 small">Ruta: <span id="lblRutaTrab"></span> <span id="lblWarningRuta" class="badge bg-warning text-dark ms-2" style="display:none;">DISTINTA A LA RUTA DEL BUS</span></p>
    <p class="mb-1 small">Zona: <span id="lblZona"></span></p>
    <p class="mb-1 small">Empresa: <span id="lblEmpresaTrab"></span></p>
    <small id="indicadorGuardado" class="d-block mt-2 fw-bold"></small>
  </div></div>
  <div id="cardDuplicado" class="card mt-3" style="display:none; background:#fff3cd; border:3px solid #c8102e;">
    <div class="card-body text-center py-4">
      <div style="font-size:3rem; line-height:1;">&#9888;</div>
      <h3 class="text-danger fw-bold my-2">YA REGISTRADO</h3>
      <p class="mb-1 fw-bold fs-5" id="lblDuplicadoNombre"></p>
      <p class="mb-0 text-muted">DNI: <span id="lblDuplicadoDni"></span></p>
    </div>
  </div>
  <div id="cardError" class="card border-danger mt-3" style="display:none;"><div class="card-body text-danger">
    <strong>Error</strong><p id="lblErrorMsg" class="mb-0"></p>
  </div></div>
  <button id="btnFinalizar" class="btn btn-lg w-100 mt-3" style="display:none; background:#c8102e; color:white;">
    Finalizar Sesion
  </button>
</div>
<div class="modal fade" id="modalExito" tabindex="-1"><div class="modal-dialog modal-dialog-centered"><div class="modal-content">
  <div class="modal-header bg-success text-white"><h5 class="modal-title">Sesion Finalizada</h5></div>
  <div class="modal-body"><p id="lblMsgExito"></p></div>
  <div class="modal-footer"><button type="button" class="btn btn-primary" data-bs-dismiss="modal" onclick="sessionStorage.removeItem('planta_asistencias'); sessionStorage.removeItem('planta_pendientes'); window.location.href='config.html';">Nueva Sesion</button></div>
</div></div></div>
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

# === scanner.js ===
$scannerJs = @'
function beep(freq, duration, volume) {
  try {
    const ctx = new (window.AudioContext || window.webkitAudioContext)();
    const osc = ctx.createOscillator();
    const gain = ctx.createGain();
    osc.connect(gain); gain.connect(ctx.destination);
    osc.frequency.value = freq || 880; osc.type = 'sine';
    gain.gain.value = volume || 0.2;
    osc.start();
    setTimeout(() => { osc.stop(); ctx.close(); }, duration || 120);
  } catch (e) {}
}

document.addEventListener('DOMContentLoaded', () => {
  if (!Auth.requiereLogin()) return;
  const config = BusConfig.obtener();
  if (!config) { window.location.href = 'config.html'; return; }
  
  let ultimoDni = null, ultimoTimestamp = 0, procesando = false;
  let dnisRegistrados = new Set();
  let asistencias = [];
  let pendientesGuardado = [];
  
  const previas = sessionStorage.getItem('planta_asistencias');
  if (previas) {
    try { asistencias = JSON.parse(previas); asistencias.forEach(a => dnisRegistrados.add(a.dni)); } catch (e) {}
  }
  const previasPendientes = sessionStorage.getItem('planta_pendientes');
  if (previasPendientes) {
    try { pendientesGuardado = JSON.parse(previasPendientes); } catch (e) {}
  }
  
  document.getElementById('lblRuta').textContent = config.ruta;
  document.getElementById('lblBus').textContent = config.codigoBus;
  document.getElementById('lblPlaca').textContent = config.placa;
  document.getElementById('lblTurno').textContent = config.turno;
  document.getElementById('lblZonaPacking').textContent = config.zonaPacking;
  document.getElementById('lblEncargado').textContent = config.encargadoNombre;
  document.getElementById('cantidadEsperada').textContent = config.cantidadAsistente;
  
  const cardPreparando = document.getElementById('cardPreparando');
  const cardBuscando = document.getElementById('cardBuscando');
  const cardResultado = document.getElementById('cardResultado');
  const cardDuplicado = document.getElementById('cardDuplicado');
  const cardError = document.getElementById('cardError');
  const reader = document.getElementById('reader');
  const btnFinalizar = document.getElementById('btnFinalizar');
  
  actualizarContador();
  
  btnFinalizar.addEventListener('click', finalizar);
  document.getElementById('btnNuevaSesion').addEventListener('click', () => {
    if (asistencias.length > 0 && !confirm('Hay ' + asistencias.length + ' asistencias en curso. Cambiar de sesion?')) return;
    sessionStorage.removeItem('planta_asistencias');
    sessionStorage.removeItem('planta_pendientes');
    BusConfig.limpiar();
    window.location.href = 'config.html';
  });
  
  API.ping().catch(e => console.warn('Warm-up fallo:', e));
  cardPreparando.style.display = 'none';
  iniciarCamara();
  
  function iniciarCamara() {
    reader.style.display = 'block';
    try {
      const html5QrCode = new Html5Qrcode("reader");
      html5QrCode.start(
        { facingMode: "environment" },
        { fps: 10, qrbox: { width: 250, height: 250 }, aspectRatio: 1.0 },
        onScanSuccess,
        function() {}
      ).catch(err => { console.error(err); alert('Error camara: ' + err); });
    } catch (e) { alert('Error: la libreria de QR no cargo. Recarga (Ctrl+F5).'); }
  }
  
  async function onScanSuccess(decodedText) {
    if (procesando) return;
    const dni = String(decodedText).trim().padStart(8, '0');
    const ahora = Date.now();
    if (dni === ultimoDni && (ahora - ultimoTimestamp) < 3000) return;
    
    ultimoDni = dni; ultimoTimestamp = ahora; procesando = true;
    if (navigator.vibrate) navigator.vibrate(80);
    
    cardResultado.style.display = 'none';
    cardDuplicado.style.display = 'none';
    cardError.style.display = 'none';
    cardBuscando.style.display = 'block';
    
    const timeoutPromise = new Promise(r => setTimeout(() => r({ ok: false, error: 'Timeout' }), 8000));
    const resp = await Promise.race([API.validarTrabajador(dni), timeoutPromise]);
    
    cardBuscando.style.display = 'none';
    
    if (resp.ok) {
      if (dnisRegistrados.has(resp.trabajador.dni)) {
        mostrarDuplicado(resp.trabajador);
        beep(440, 400, 0.3);
        if (navigator.vibrate) navigator.vibrate([100, 50, 100, 50, 100]);
      } else {
        const nuevaAsistencia = {
          dni: resp.trabajador.dni,
          nombre: resp.trabajador.nombre,
          empresa: resp.trabajador.empresa,
          ruta_trabajador: resp.trabajador.ruta,
          tipoRegistro: 'QR'
        };
        dnisRegistrados.add(resp.trabajador.dni);
        asistencias.push(nuevaAsistencia);
        sessionStorage.setItem('planta_asistencias', JSON.stringify(asistencias));
        mostrarTrabajador(resp.trabajador);
        actualizarContador();
        beep(880, 120, 0.2);
        guardarAsistenciaIndividual(nuevaAsistencia);
      }
    } else {
      mostrarError(resp.error || 'No encontrado');
      beep(220, 300, 0.2);
    }
    procesando = false;
  }
  
  async function guardarAsistenciaIndividual(asistencia) {
    actualizarIndicador('guardando');
    try {
      const resp = await API.registrarAsistencias([asistencia], config);
      if (resp.ok) {
        actualizarIndicador('ok');
      } else {
        pendientesGuardado.push(asistencia);
        sessionStorage.setItem('planta_pendientes', JSON.stringify(pendientesGuardado));
        actualizarIndicador('pendiente');
      }
    } catch (e) {
      pendientesGuardado.push(asistencia);
      sessionStorage.setItem('planta_pendientes', JSON.stringify(pendientesGuardado));
      actualizarIndicador('pendiente');
    }
  }
  
  function actualizarIndicador(estado) {
    const ind = document.getElementById('indicadorGuardado');
    if (!ind) return;
    if (estado === 'guardando') { ind.textContent = 'Guardando en servidor...'; ind.style.color = '#6c757d'; }
    else if (estado === 'ok') { ind.textContent = 'Guardado en servidor'; ind.style.color = '#28a745'; }
    else if (estado === 'pendiente') { ind.textContent = 'Pendiente (se reintentara al finalizar)'; ind.style.color = '#dc3545'; }
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
    warning.style.display = (t.ruta && t.ruta.toUpperCase() !== config.ruta.toUpperCase()) ? 'inline' : 'none';
  }
  
  function mostrarDuplicado(t) {
    cardDuplicado.style.display = 'block';
    document.getElementById('lblDuplicadoNombre').textContent = t.nombre || '-';
    document.getElementById('lblDuplicadoDni').textContent = t.dni || '-';
  }
  
  function mostrarError(msg) {
    cardError.style.display = 'block';
    document.getElementById('lblErrorMsg').textContent = msg;
  }
  
  async function finalizar() {
    if (!asistencias.length) return;
    
    if (pendientesGuardado.length > 0) {
      if (!confirm('Hay ' + pendientesGuardado.length + ' pendientes de guardar. Reintentar?')) return;
      btnFinalizar.disabled = true;
      btnFinalizar.innerHTML = '<span class="spinner-border spinner-border-sm me-2"></span>Reintentando...';
      const resp = await API.registrarAsistencias(pendientesGuardado, config);
      if (resp.ok) {
        pendientesGuardado = [];
        sessionStorage.removeItem('planta_pendientes');
      } else {
        alert('Error al reintentar: ' + (resp.error || 'desconocido'));
        btnFinalizar.disabled = false;
        btnFinalizar.innerHTML = 'Finalizar Sesion';
        return;
      }
    }
    
    const faltan = config.cantidadAsistente - asistencias.length;
    let msg = 'Finalizar sesion?\n\nAsistencias: ' + asistencias.length + '\nEsperados: ' + config.cantidadAsistente;
    if (faltan > 0) msg += '\nFaltan: ' + faltan + ' (se pediran en el siguiente paso)';
    if (!confirm(msg)) return;
    
    const fechaHoy = new Date().toLocaleDateString('es-PE');
    const msgFinal = 'Has registrado ' + asistencias.length + ' asistencias de la ruta ' + 
                config.ruta + ' - codigo ' + config.codigoBus + ' - fecha ' + fechaHoy +
                (faltan > 0 ? '\n\nQuedan ' + faltan + ' por registrar como faltantes (proximo modulo).' : '');
    document.getElementById('lblMsgExito').textContent = msgFinal;
    
    sessionStorage.removeItem('planta_asistencias');
    sessionStorage.removeItem('planta_pendientes');
    
    const modal = new bootstrap.Modal(document.getElementById('modalExito'));
    modal.show();
  }
});
'@
[System.IO.File]::WriteAllText("C:\planta-rapel-2026\js\scanner.js", $scannerJs, $utf8)
Write-Host "scanner.js OK" -ForegroundColor Green

git add .
git commit -m "Fase 1: Guardado automatico + mensaje duplicado mejorado"
git push

Write-Host ""
Write-Host "===== FASE 1 LISTA =====" -ForegroundColor Green
Write-Host "1. Espera 30 seg para GitHub Pages" -ForegroundColor Cyan
Write-Host "2. Ctrl+Shift+R en navegador" -ForegroundColor Cyan
Write-Host "3. Prueba escanear el MISMO DNI 2 veces" -ForegroundColor Cyan