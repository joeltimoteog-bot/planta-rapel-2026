cd C:\planta-rapel-2026

$utf8 = [System.Text.UTF8Encoding]::new($true)

# === js/api.js con metodo validarTrabajador ===
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
  ping() { return this.call('ping'); }
};
'@
[System.IO.File]::WriteAllText("C:\planta-rapel-2026\js\api.js", $apiJs, $utf8)
Write-Host "api.js OK" -ForegroundColor Green

# === scanner.html con tarjeta de info del trabajador ===
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
      <a href="home.html" class="btn btn-sm btn-outline-light">Volver</a>
    </div>
  </nav>
  
  <div class="container py-3">
    <div class="alert alert-warning py-2 mb-3">
      <small><strong>Fase A:</strong> el scanner busca el trabajador en la base. A&uacute;n no registra asistencia.</small>
    </div>
    
    <div id="reader" style="width: 100%;"></div>
    
    <!-- Card de resultado -->
    <div class="card mt-3 shadow-sm" id="cardResultado" style="display:none;">
      <div class="card-body py-3">
        <div class="d-flex justify-content-between align-items-start mb-2">
          <h5 class="mb-0" id="lblNombre" style="color:#1a3a6c;">-</h5>
          <span class="badge" id="lblEmpresaTrab" style="background:#c8102e;">-</span>
        </div>
        <p class="mb-1 small"><strong>DNI:</strong> <span id="lblDni">-</span></p>
        <p class="mb-1 small"><strong>C&oacute;digo:</strong> <span id="lblCodigo">-</span></p>
        <p class="mb-1 small"><strong>Oficio:</strong> <span id="lblOficio">-</span></p>
        <p class="mb-1 small"><strong>R&eacute;gimen:</strong> <span id="lblRegimen">-</span></p>
        <p class="mb-1 small"><strong>Ruta:</strong> <span class="badge bg-primary" id="lblRuta">-</span></p>
        <p class="mb-1 small"><strong>Sector:</strong> <span id="lblZona">-</span></p>
        <p class="mb-0 small text-muted"><strong>Contrato:</strong> <span id="lblFechas">-</span></p>
      </div>
    </div>
    
    <!-- Card de error -->
    <div class="card mt-3 shadow-sm border-danger" id="cardError" style="display:none;">
      <div class="card-body py-3">
        <h5 class="mb-2 text-danger">No encontrado</h5>
        <p class="mb-0 small" id="lblErrorMsg">-</p>
      </div>
    </div>
    
    <div class="card mt-3">
      <div class="card-body py-2">
        <p class="mb-0 small text-muted">Escaneados en esta sesi&oacute;n: <strong id="contador">0</strong></p>
      </div>
    </div>
  </div>
  
  <script src="js/config.js"></script>
  <script src="js/api.js"></script>
  <script src="js/auth.js"></script>
  <script src="js/scanner.js"></script>
</body>
</html>
'@
[System.IO.File]::WriteAllText("C:\planta-rapel-2026\scanner.html", $scannerHtml, $utf8)
Write-Host "scanner.html OK" -ForegroundColor Green

# === scanner.js con llamada a validarTrabajador ===
$scannerJs = @'
document.addEventListener('DOMContentLoaded', () => {
  if (!Auth.requiereLogin()) return;
  
  const usuario = Auth.obtenerSesion();
  const empresa = usuario.empresa || 'RAPEL';
  
  let contador = 0;
  let ultimoDni = null;
  let ultimoTimestamp = 0;
  let procesando = false;
  
  const cardResultado = document.getElementById('cardResultado');
  const cardError = document.getElementById('cardError');
  const lblContador = document.getElementById('contador');
  
  const html5QrCode = new Html5Qrcode("reader");
  const config = { 
    fps: 10, 
    qrbox: { width: 250, height: 250 },
    aspectRatio: 1.0
  };
  
  html5QrCode.start(
    { facingMode: "environment" },
    config,
    onScanSuccess,
    onScanError
  ).catch(err => {
    console.error('Error camara:', err);
    alert('No se pudo iniciar la camara. Verifica que diste permisos.');
  });
  
  async function onScanSuccess(decodedText) {
    if (procesando) return;
    
    const dni = String(decodedText).trim().padStart(8, '0');
    const ahora = Date.now();
    
    // Debounce: ignorar mismo DNI en menos de 3 segundos
    if (dni === ultimoDni && (ahora - ultimoTimestamp) < 3000) return;
    
    ultimoDni = dni;
    ultimoTimestamp = ahora;
    procesando = true;
    
    if (navigator.vibrate) navigator.vibrate(100);
    
    // Llamar al backend
    const resp = await API.validarTrabajador(dni, empresa);
    
    if (resp.ok) {
      mostrarTrabajador(resp.trabajador);
      contador++;
      lblContador.textContent = contador;
    } else {
      mostrarError(resp.error || 'No encontrado');
    }
    
    procesando = false;
  }
  
  function mostrarTrabajador(t) {
    cardError.style.display = 'none';
    cardResultado.style.display = 'block';
    document.getElementById('lblNombre').textContent = t.nombre || '-';
    document.getElementById('lblDni').textContent = t.dni || '-';
    document.getElementById('lblCodigo').textContent = t.codigo || '-';
    document.getElementById('lblOficio').textContent = t.oficio || '-';
    document.getElementById('lblRegimen').textContent = t.regimen || '-';
    document.getElementById('lblRuta').textContent = t.ruta || 'SIN RUTA';
    document.getElementById('lblZona').textContent = t.zona || '-';
    document.getElementById('lblEmpresaTrab').textContent = t.empresa || '-';
    document.getElementById('lblFechas').textContent = 
      (t.fechaInicio || '?') + ' - ' + (t.fechaTermino || '?');
  }
  
  function mostrarError(msg) {
    cardResultado.style.display = 'none';
    cardError.style.display = 'block';
    document.getElementById('lblErrorMsg').textContent = msg;
  }
  
  function onScanError(err) { /* ignorar */ }
});
'@
[System.IO.File]::WriteAllText("C:\planta-rapel-2026\js\scanner.js", $scannerJs, $utf8)
Write-Host "scanner.js OK" -ForegroundColor Green

# === Commit y push ===
git add .
git commit -m "Dia 2 Fase A: scanner conectado a base de trabajadores"
git push

Write-Host ""
Write-Host "===== LISTO =====" -ForegroundColor Green
Write-Host "1. Asegurate de haber redesplegado el Apps Script (Nueva version)" -ForegroundColor Cyan
Write-Host "2. Espera 1-2 min y refresca scanner.html con Ctrl+F5" -ForegroundColor Cyan
Write-Host "3. Escanea un fotocheck y deberia mostrar los datos del trabajador" -ForegroundColor Cyan