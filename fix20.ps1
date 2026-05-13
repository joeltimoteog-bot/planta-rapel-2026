cd C:\planta-rapel-2026
$utf8 = [System.Text.UTF8Encoding]::new($true)

# ============================================================
# === LOGIN CON PIN ===
# ============================================================

# Reescribir index.html con tabs Admin / Encargado
$indexHtml = @'
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Login - Planta Rapel 2026</title>
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
<link rel="stylesheet" href="css/styles.css">
<script src="js/version-check.js"></script>
</head>
<body style="background:#f8f9fa;">
<div class="container py-4" style="max-width:480px;">
  <div class="logo-login">
    <img src="assets/logo-unifrutti.png" alt="Unifrutti" onerror="this.style.display='none'; this.nextElementSibling.style.display='inline-block';">
    <span class="logo-login-fallback" style="display:none;">UNIFRUTTI</span>
  </div>
  <h4 class="text-center mb-3" style="color:#1a3a6c;">Planta Rapel 2026</h4>
  
  <div class="card shadow-sm">
    <ul class="nav nav-tabs nav-fill" id="loginTabs">
      <li class="nav-item">
        <a class="nav-link active" data-bs-toggle="tab" href="#tabEnc">Encargado (PIN)</a>
      </li>
      <li class="nav-item">
        <a class="nav-link" data-bs-toggle="tab" href="#tabAdmin">Admin / Coordinador</a>
      </li>
    </ul>
    <div class="tab-content">
      
      <!-- TAB ENCARGADO (PIN) -->
      <div class="tab-pane fade show active p-3" id="tabEnc">
        <p class="text-muted small mb-2 text-center">Ingresa tu PIN de 4 digitos</p>
        <input type="text" inputmode="numeric" pattern="[0-9]*" maxlength="4"
               class="form-control form-control-lg text-center fs-1" 
               id="inputPin" placeholder="0000" 
               style="letter-spacing:15px; font-weight:bold;">
        <button class="btn w-100 mt-3 btn-lg" style="background:#c8102e; color:white;" id="btnLoginPin">
          Ingresar
        </button>
        <div id="msgPin" class="mt-2 small text-center"></div>
      </div>
      
      <!-- TAB ADMIN -->
      <div class="tab-pane fade p-3" id="tabAdmin">
        <div class="mb-2">
          <label class="form-label small">Usuario</label>
          <input type="text" class="form-control" id="inputUser" placeholder="ej: jtimoteo">
        </div>
        <div class="mb-2">
          <label class="form-label small">Contrasena</label>
          <input type="password" class="form-control" id="inputPass">
        </div>
        <button class="btn btn-primary w-100 mt-2" id="btnLogin">Ingresar</button>
        <div id="msgLogin" class="mt-2 small text-center"></div>
      </div>
      
    </div>
  </div>
  
  <p class="text-center text-muted small mt-3">v0.5.0 - Unifrutti / Rapel SAC</p>
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"></script>
<script src="js/config.js"></script>
<script src="js/api.js"></script>
<script src="js/auth.js"></script>
<script src="js/login.js"></script>
</body>
</html>
'@
[System.IO.File]::WriteAllText("C:\planta-rapel-2026\index.html", $indexHtml, $utf8)
Write-Host "index.html con tabs Admin / PIN" -ForegroundColor Green

# Reescribir login.js para manejar PIN + Admin login
$loginJs = @'
document.addEventListener('DOMContentLoaded', () => {
  // Warm-up Apps Script en background
  API.ping().catch(() => {});
  API.validarTrabajador('00000000').catch(() => {});
  
  const inputPin = document.getElementById('inputPin');
  const inputUser = document.getElementById('inputUser');
  const inputPass = document.getElementById('inputPass');
  
  // Login con PIN
  document.getElementById('btnLoginPin').addEventListener('click', loginConPin);
  inputPin.addEventListener('keydown', (e) => {
    if (e.key === 'Enter') { e.preventDefault(); loginConPin(); }
  });
  // Auto-enviar al llegar a 4 digitos
  inputPin.addEventListener('input', (e) => {
    const v = e.target.value.replace(/\D/g, '');
    e.target.value = v;
    if (v.length === 4) loginConPin();
  });
  
  // Login admin tradicional
  document.getElementById('btnLogin').addEventListener('click', loginAdmin);
  inputPass.addEventListener('keydown', (e) => {
    if (e.key === 'Enter') { e.preventDefault(); loginAdmin(); }
  });
  
  setTimeout(() => inputPin.focus(), 100);
});

async function loginConPin() {
  const pin = document.getElementById('inputPin').value.trim();
  const msg = document.getElementById('msgPin');
  
  if (pin.length !== 4) {
    msg.textContent = 'El PIN debe tener 4 digitos';
    msg.className = 'mt-2 small text-center text-danger';
    return;
  }
  
  msg.textContent = 'Verificando...';
  msg.className = 'mt-2 small text-center text-muted';
  
  const resp = await API.loginPin(pin);
  procesarRespLogin(resp, msg);
}

async function loginAdmin() {
  const username = document.getElementById('inputUser').value.trim();
  const password = document.getElementById('inputPass').value;
  const msg = document.getElementById('msgLogin');
  
  if (!username || !password) {
    msg.textContent = 'Completa usuario y contrasena';
    msg.className = 'mt-2 small text-center text-danger';
    return;
  }
  
  msg.textContent = 'Verificando...';
  msg.className = 'mt-2 small text-center text-muted';
  
  const resp = await API.login(username, password);
  procesarRespLogin(resp, msg);
}

function procesarRespLogin(resp, msg) {
  if (!resp.ok) {
    msg.textContent = resp.error || 'Error de autenticacion';
    msg.className = 'mt-2 small text-center text-danger';
    document.getElementById('inputPin').value = '';
    return;
  }
  
  // Guardar usuario
  localStorage.setItem('planta_usuario', JSON.stringify(resp.usuario));
  
  msg.textContent = 'Bienvenido, ' + (resp.usuario.nombre_completo || resp.usuario.username);
  msg.className = 'mt-2 small text-center text-success fw-bold';
  
  // Redirigir segun rol
  setTimeout(() => {
    if (resp.usuario.rol === 'admin') {
      window.location.href = 'home.html';
    } else {
      window.location.href = 'config.html';
    }
  }, 600);
}
'@
[System.IO.File]::WriteAllText("C:\planta-rapel-2026\js\login.js", $loginJs, $utf8)
Write-Host "login.js con soporte PIN y Admin" -ForegroundColor Green

# Agregar API.loginPin en api.js
$apiPath = "C:\planta-rapel-2026\js\api.js"
$a = Get-Content $apiPath -Raw
if ($a -notmatch 'loginPin') {
  $old = "login: (username, password) => post({ accion: 'login', username, password }),"
  $new = "login: (username, password) => post({ accion: 'login', username, password }),`n  loginPin: (pin) => post({ accion: 'loginPin', pin }),`n  actualizarPinUsuario: (id, pin) => post({ accion: 'actualizarPinUsuario', id, pin }),"
  $a = $a.Replace($old, $new)
  [System.IO.File]::WriteAllText($apiPath, $a, $utf8)
  Write-Host "api.js: loginPin agregado" -ForegroundColor Green
}

# Agregar boton PIN en usuarios.js (para asignar PIN desde gestion de usuarios)
$usuariosJsPath = "C:\planta-rapel-2026\js\usuarios.js"
$u = Get-Content $usuariosJsPath -Raw

# Agregar columna PIN en la tabla y boton para asignar
$oldRender = "      '<td>' + btn + '</td>' +`n      '</tr>';"
$newRender = @'
      '<td>' + btn + ' <button class="btn btn-sm btn-outline-warning ms-1" onclick="asignarPin(' + u.id + ', \'' + escapeHtml(u.username) + '\')">PIN</button></td>' +
      '</tr>';
'@
$u = $u.Replace($oldRender, $newRender)

# Agregar funcion asignarPin al final
if ($u -notmatch 'function asignarPin') {
  $u += @'

async function asignarPin(id, username) {
  const pin = prompt('Asignar PIN de 4 digitos para "' + username + '":\n\n(Sera usado para que el encargado entre rapido al scanner)');
  if (!pin) return;
  if (!/^\d{4}$/.test(pin)) {
    alert('PIN invalido. Deben ser 4 digitos numericos.');
    return;
  }
  const resp = await API.actualizarPinUsuario(id, pin);
  if (resp.ok) {
    alert('PIN asignado correctamente a ' + username + '\nPIN: ' + pin);
  } else {
    alert('Error: ' + resp.error);
  }
}
'@
}
[System.IO.File]::WriteAllText($usuariosJsPath, $u, $utf8)
Write-Host "usuarios.js: boton asignar PIN" -ForegroundColor Green

# ============================================================
# === GRAFICOS EN DASHBOARD ===
# ============================================================

$dashHtmlPath = "C:\planta-rapel-2026\dashboard.html"
$d = Get-Content $dashHtmlPath -Raw

# Agregar Chart.js CDN antes del cierre </head>
if ($d -notmatch 'chart\.umd') {
  $d = $d.Replace('</head>', '<script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js"></script>' + "`n</head>")
  Write-Host "dashboard.html: Chart.js CDN agregado" -ForegroundColor Green
}

# Agregar bloque de graficos despues del resumen detallado, antes de los tabs
$insertarAntes = '<!-- Tabs -->'
$bloqueCharts = @'
<!-- Graficos -->
  <div class="row g-2 mb-3">
    <div class="col-md-6">
      <div class="card">
        <div class="card-body">
          <h6 class="fw-bold mb-2">Asistencias por Ruta</h6>
          <canvas id="chartRuta" height="200"></canvas>
        </div>
      </div>
    </div>
    <div class="col-md-6">
      <div class="card">
        <div class="card-body">
          <h6 class="fw-bold mb-2">Faltantes por Motivo</h6>
          <canvas id="chartFaltMotivo" height="200"></canvas>
        </div>
      </div>
    </div>
  </div>

  <!-- Tabs -->
'@
if ($d -notmatch 'chartRuta') {
  $d = $d.Replace($insertarAntes, $bloqueCharts)
  Write-Host "dashboard.html: bloque graficos agregado" -ForegroundColor Green
}

[System.IO.File]::WriteAllText($dashHtmlPath, $d, $utf8)

# Agregar funcion renderCharts en dashboard.js
$dashJsPath = "C:\planta-rapel-2026\js\dashboard.js"
$dj = Get-Content $dashJsPath -Raw

if ($dj -notmatch 'function renderCharts') {
  # Agregar al final del archivo
  $dj += @'

let chartRutaInst = null;
let chartFaltInst = null;

function renderCharts(resumen) {
  if (typeof Chart === 'undefined') return;
  
  // Chart Asistencias por Ruta
  const ctxR = document.getElementById('chartRuta');
  if (ctxR) {
    if (chartRutaInst) chartRutaInst.destroy();
    const rutas = Object.keys(resumen.porRuta || {});
    const valores = rutas.map(k => resumen.porRuta[k]);
    chartRutaInst = new Chart(ctxR, {
      type: 'bar',
      data: {
        labels: rutas,
        datasets: [{
          label: 'Asistencias',
          data: valores,
          backgroundColor: '#1a3a6c'
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: { legend: { display: false } },
        scales: { y: { beginAtZero: true, ticks: { stepSize: 1 } } }
      }
    });
  }
  
  // Chart Faltantes por Motivo
  const ctxF = document.getElementById('chartFaltMotivo');
  if (ctxF) {
    if (chartFaltInst) chartFaltInst.destroy();
    const motivos = Object.keys(resumen.faltantesPorMotivo || {});
    if (motivos.length === 0) {
      // Sin datos, limpiar
      ctxF.parentElement.querySelector('canvas').style.opacity = 0.3;
      return;
    }
    const valores = motivos.map(k => resumen.faltantesPorMotivo[k]);
    chartFaltInst = new Chart(ctxF, {
      type: 'doughnut',
      data: {
        labels: motivos,
        datasets: [{
          data: valores,
          backgroundColor: ['#c8102e', '#ffc107', '#6c757d', '#1a3a6c', '#28a745']
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: { legend: { position: 'bottom' } }
      }
    });
  }
}
'@
}

# Llamar renderCharts en cargarDashboard (despues de actualizar las cards)
$oldCargar = "document.getElementById('resPorRuta').innerHTML = renderResumen(r.porRuta);"
$newCargar = "document.getElementById('resPorRuta').innerHTML = renderResumen(r.porRuta);`n    renderCharts(r);"

if ($dj -notmatch 'renderCharts\(r\);') {
  $dj = $dj.Replace($oldCargar, $newCargar)
}

[System.IO.File]::WriteAllText($dashJsPath, $dj, $utf8)
Write-Host "dashboard.js: funcion renderCharts integrada" -ForegroundColor Green

# === Update version ===
$version = (Get-Date).ToString('yyyyMMdd-HHmmss')
[System.IO.File]::WriteAllText("C:\planta-rapel-2026\version.json", "{`"version`": `"$version`"}", $utf8)

git add .
git commit -m "Login PIN para encargados + Graficos Chart.js en dashboard"
git push

Write-Host ""
Write-Host "===== LISTO =====" -ForegroundColor Green
Write-Host "1. Verifica que ejecutaste agregarColumnaPin en Apps Script" -ForegroundColor Cyan
Write-Host "2. Verifica que hiciste redeploy en Apps Script" -ForegroundColor Cyan
Write-Host "3. Espera 30 seg, Ctrl+Shift+R" -ForegroundColor Cyan