cd C:\planta-rapel-2026
$utf8 = [System.Text.UTF8Encoding]::new($true)

# === Rescribir TABLAS de dashboard.html con columnas correctas ===
$htmlPath = "C:\planta-rapel-2026\dashboard.html"
$h = Get-Content $htmlPath -Raw

# Reemplazar thead Asistencias (con regex robusto)
$theadAsistNew = "<thead style=`"position:sticky; top:0; background:#1a3a6c; color:white; z-index:1;`">`n            <tr>`n              <th>Fecha</th><th>Hora</th><th>DNI</th><th>Nombre</th><th>Empresa</th><th>Ruta</th><th>Codigo</th><th>Placa</th><th>Turno</th><th>Zona</th><th>Encargado</th>`n            </tr>`n          </thead>"
$h = [regex]::Replace($h, '<thead style="position:sticky; top:0; background:#1a3a6c[\s\S]*?</thead>', $theadAsistNew)

$theadFaltNew = "<thead style=`"position:sticky; top:0; background:#c8102e; color:white; z-index:1;`">`n            <tr>`n              <th>Fecha</th><th>Hora</th><th>DNI</th><th>Nombre</th><th>Empresa</th><th>Ruta</th><th>Codigo</th><th>Placa</th><th>Motivo</th><th>Observacion</th><th>Encargado</th>`n            </tr>`n          </thead>"
$h = [regex]::Replace($h, '<thead style="position:sticky; top:0; background:#c8102e[\s\S]*?</thead>', $theadFaltNew)

[System.IO.File]::WriteAllText($htmlPath, $h, $utf8)
Write-Host "dashboard.html: tablas reescritas con columnas correctas" -ForegroundColor Green

# === Reescribir funciones render en dashboard.js ===
$jsPath = "C:\planta-rapel-2026\js\dashboard.js"
$j = Get-Content $jsPath -Raw

$renderAsistNew = @'
function renderTablaAsist(data) {
  const tbody = document.getElementById('tblAsist');
  if (data.length === 0) {
    tbody.innerHTML = '<tr><td colspan="11" class="text-center text-muted py-3">Sin asistencias en el periodo</td></tr>';
    return;
  }
  tbody.innerHTML = data.map(a => 
    '<tr>' +
    '<td>' + escapeHtml(a.fecha) + '</td>' +
    '<td>' + escapeHtml(a.hora) + '</td>' +
    '<td>' + escapeHtml(a.dni) + '</td>' +
    '<td>' + escapeHtml(a.nombre) + '</td>' +
    '<td><span class="badge bg-secondary">' + escapeHtml(a.empresa) + '</span></td>' +
    '<td>' + escapeHtml(a.ruta_sesion) + '</td>' +
    '<td>' + escapeHtml(a.codigo_bus) + '</td>' +
    '<td>' + escapeHtml(a.placa) + '</td>' +
    '<td>' + escapeHtml(a.turno) + '</td>' +
    '<td>' + escapeHtml(a.zona_packing) + '</td>' +
    '<td>' + escapeHtml(a.encargado_nombre) + '</td>' +
    '</tr>'
  ).join('');
}
'@

$renderFaltNew = @'
function renderTablaFalt(data) {
  const tbody = document.getElementById('tblFalt');
  if (data.length === 0) {
    tbody.innerHTML = '<tr><td colspan="11" class="text-center text-muted py-3">Sin faltantes en el periodo</td></tr>';
    return;
  }
  tbody.innerHTML = data.map(f => 
    '<tr>' +
    '<td>' + escapeHtml(f.fecha) + '</td>' +
    '<td>' + escapeHtml(f.hora) + '</td>' +
    '<td>' + escapeHtml(f.dni) + '</td>' +
    '<td>' + escapeHtml(f.nombre) + '</td>' +
    '<td><span class="badge bg-secondary">' + escapeHtml(f.empresa) + '</span></td>' +
    '<td>' + escapeHtml(f.ruta) + '</td>' +
    '<td>' + escapeHtml(f.codigo_bus) + '</td>' +
    '<td>' + escapeHtml(f.placa) + '</td>' +
    '<td><span class="badge bg-danger">' + escapeHtml(f.motivo) + '</span></td>' +
    '<td>' + escapeHtml(f.observacion) + '</td>' +
    '<td>' + escapeHtml(f.encargado_nombre) + '</td>' +
    '</tr>'
  ).join('');
}
'@

$j = [regex]::Replace($j, 'function renderTablaAsist\(data\) \{[\s\S]*?^\}', $renderAsistNew, 'Multiline')
$j = [regex]::Replace($j, 'function renderTablaFalt\(data\) \{[\s\S]*?^\}', $renderFaltNew, 'Multiline')

[System.IO.File]::WriteAllText($jsPath, $j, $utf8)
Write-Host "dashboard.js: funciones render actualizadas" -ForegroundColor Green

# === Crear usuarios.html ===
$usuariosHtml = @'
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Gestion de Usuarios - Planta Rapel 2026</title>
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
<link rel="stylesheet" href="css/styles.css">
<script src="js/version-check.js"></script>
</head>
<body>
<nav class="navbar navbar-dark" style="background:#1a3a6c;">
  <div class="container-fluid">
    <span><img src="assets/logo-unifrutti.png" alt="Unifrutti" class="logo-nav" onerror="this.style.display='none'; this.nextElementSibling.style.display='inline-block';"><span class="logo-nav-fallback" style="display:none;">UNIFRUTTI</span><span class="navbar-brand">Gestion de Usuarios</span></span>
    <div>
      <button class="btn btn-sm btn-light me-2" id="btnHome">Inicio</button>
      <button class="btn btn-sm btn-outline-light" id="btnSalir">Salir</button>
    </div>
  </div>
</nav>

<div class="container my-3" style="max-width:1100px;">

  <!-- Form crear -->
  <div class="card mb-3">
    <div class="card-header" style="background:#1a3a6c; color:white;"><strong>Crear Nuevo Usuario</strong></div>
    <div class="card-body">
      <div class="row g-2">
        <div class="col-md-4">
          <label class="form-label small">Usuario (login)</label>
          <input type="text" class="form-control form-control-sm" id="iUsername" placeholder="ej: maria.lopez">
        </div>
        <div class="col-md-4">
          <label class="form-label small">Contrasena</label>
          <input type="text" class="form-control form-control-sm" id="iPassword" placeholder="minimo 6 caracteres">
        </div>
        <div class="col-md-4">
          <label class="form-label small">Nombre completo</label>
          <input type="text" class="form-control form-control-sm" id="iNombre" placeholder="ej: Maria Lopez">
        </div>
        <div class="col-md-4">
          <label class="form-label small">Cargo</label>
          <input type="text" class="form-control form-control-sm" id="iCargo" placeholder="ej: Encargado de Bus">
        </div>
        <div class="col-md-4">
          <label class="form-label small">Empresa</label>
          <select class="form-select form-select-sm" id="iEmpresa">
            <option value="AMBAS">AMBAS</option>
            <option value="RAPEL">RAPEL</option>
            <option value="VERFRUT">VERFRUT</option>
          </select>
        </div>
        <div class="col-md-4">
          <label class="form-label small fw-bold">Rol *</label>
          <div class="d-flex gap-3 mt-1">
            <div class="form-check">
              <input type="radio" name="iRol" class="form-check-input" id="rolEnc" value="encargado_bus" checked>
              <label class="form-check-label small" for="rolEnc">Encargado (usuario normal)</label>
            </div>
            <div class="form-check">
              <input type="radio" name="iRol" class="form-check-input" id="rolAdm" value="admin">
              <label class="form-check-label small" for="rolAdm">Administrador</label>
            </div>
          </div>
        </div>
      </div>
      <button class="btn btn-success mt-3" id="btnCrear">Crear Usuario</button>
      <div id="msgCrear" class="mt-2 small"></div>
    </div>
  </div>

  <!-- Tabla -->
  <div class="card">
    <div class="card-header" style="background:#1a3a6c; color:white;"><strong>Usuarios Registrados</strong></div>
    <div class="card-body">
      <input type="text" class="form-control form-control-sm mb-2" id="buscador" placeholder="Buscar por usuario o nombre...">
      <div class="table-responsive">
        <table class="table table-sm table-hover">
          <thead style="background:#1a3a6c; color:white;">
            <tr>
              <th>ID</th><th>Usuario</th><th>Nombre</th><th>Cargo</th><th>Empresa</th>
              <th>Rol</th><th>Estado</th><th>Creado</th><th>Accion</th>
            </tr>
          </thead>
          <tbody id="tblUsuarios"></tbody>
        </table>
      </div>
    </div>
  </div>
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"></script>
<script src="js/config.js"></script>
<script src="js/api.js"></script>
<script src="js/auth.js"></script>
<script src="js/usuarios.js"></script>
</body>
</html>
'@
[System.IO.File]::WriteAllText("C:\planta-rapel-2026\usuarios.html", $usuariosHtml, $utf8)
Write-Host "usuarios.html OK" -ForegroundColor Green

# === Crear js/usuarios.js ===
$usuariosJs = @'
let usuariosData = [];

document.addEventListener('DOMContentLoaded', () => {
  if (!Auth.requiereLogin()) return;
  
  try {
    const raw = localStorage.getItem('planta_usuario') || localStorage.getItem('usuario');
    const u = raw ? JSON.parse(raw) : null;
    if (u && u.rol && u.rol !== 'admin') {
      alert('Solo administradores pueden gestionar usuarios');
      window.location.href = 'home.html';
      return;
    }
  } catch (e) {}
  
  document.getElementById('btnHome').addEventListener('click', () => window.location.href = 'home.html');
  document.getElementById('btnSalir').addEventListener('click', () => {
    localStorage.removeItem('planta_usuario');
    localStorage.removeItem('usuario');
    sessionStorage.clear();
    window.location.href = 'index.html';
  });
  document.getElementById('btnCrear').addEventListener('click', crearUsuario);
  document.getElementById('buscador').addEventListener('input', (e) => filtrarTabla(e.target.value));
  
  cargarUsuarios();
});

async function cargarUsuarios() {
  const resp = await API.listarUsuarios();
  if (!resp.ok) { alert('Error: ' + resp.error); return; }
  usuariosData = resp.usuarios || [];
  renderTabla(usuariosData);
}

function renderTabla(data) {
  const tbody = document.getElementById('tblUsuarios');
  if (data.length === 0) {
    tbody.innerHTML = '<tr><td colspan="9" class="text-center text-muted">Sin usuarios</td></tr>';
    return;
  }
  tbody.innerHTML = data.map(u => {
    const activo = u.activo === true || u.activo === 'true' || u.activo === 'TRUE';
    const badgeRol = u.rol === 'admin' 
      ? '<span class="badge bg-danger">admin</span>' 
      : '<span class="badge bg-primary">' + escapeHtml(u.rol) + '</span>';
    const badgeEstado = activo 
      ? '<span class="badge bg-success">Activo</span>' 
      : '<span class="badge bg-secondary">Inactivo</span>';
    const btn = activo 
      ? '<button class="btn btn-sm btn-outline-danger" onclick="cambiarEstado(' + u.id + ', false)">Desactivar</button>'
      : '<button class="btn btn-sm btn-outline-success" onclick="cambiarEstado(' + u.id + ', true)">Activar</button>';
    return '<tr>' +
      '<td>' + escapeHtml(u.id) + '</td>' +
      '<td><strong>' + escapeHtml(u.username) + '</strong></td>' +
      '<td>' + escapeHtml(u.nombre_completo) + '</td>' +
      '<td>' + escapeHtml(u.cargo) + '</td>' +
      '<td>' + escapeHtml(u.empresa) + '</td>' +
      '<td>' + badgeRol + '</td>' +
      '<td>' + badgeEstado + '</td>' +
      '<td class="small">' + escapeHtml(u.fecha_creacion) + '</td>' +
      '<td>' + btn + '</td>' +
      '</tr>';
  }).join('');
}

function filtrarTabla(q) {
  q = q.toLowerCase().trim();
  if (!q) { renderTabla(usuariosData); return; }
  const filtrado = usuariosData.filter(u => 
    String(u.username).toLowerCase().includes(q) || 
    String(u.nombre_completo).toLowerCase().includes(q)
  );
  renderTabla(filtrado);
}

async function crearUsuario() {
  const datos = {
    username: document.getElementById('iUsername').value.trim(),
    password: document.getElementById('iPassword').value,
    nombre: document.getElementById('iNombre').value.trim(),
    cargo: document.getElementById('iCargo').value.trim(),
    empresa: document.getElementById('iEmpresa').value,
    rol: document.querySelector('input[name="iRol"]:checked').value
  };
  
  if (!datos.username || !datos.password || !datos.nombre) {
    mostrarMsg('Completa usuario, contrasena y nombre', 'danger');
    return;
  }
  if (datos.password.length < 6) {
    mostrarMsg('La contrasena debe tener al menos 6 caracteres', 'danger');
    return;
  }
  
  const confirmacion = confirm('Crear el usuario "' + datos.username + '" con rol "' + datos.rol + '"?');
  if (!confirmacion) return;
  
  const btn = document.getElementById('btnCrear');
  btn.disabled = true;
  btn.textContent = 'Creando...';
  
  const resp = await API.crearUsuario(datos);
  btn.disabled = false;
  btn.textContent = 'Crear Usuario';
  
  if (resp.ok) {
    mostrarMsg('Usuario creado: ' + resp.usuario + ' (ID ' + resp.id + ')', 'success');
    document.getElementById('iUsername').value = '';
    document.getElementById('iPassword').value = '';
    document.getElementById('iNombre').value = '';
    document.getElementById('iCargo').value = '';
    cargarUsuarios();
  } else {
    mostrarMsg('Error: ' + resp.error, 'danger');
  }
}

async function cambiarEstado(id, activo) {
  if (!confirm((activo ? 'Activar' : 'Desactivar') + ' este usuario?')) return;
  const resp = await API.cambiarEstadoUsuario(id, activo);
  if (resp.ok) cargarUsuarios();
  else alert('Error: ' + resp.error);
}

function mostrarMsg(msg, tipo) {
  const div = document.getElementById('msgCrear');
  div.className = 'mt-2 small alert alert-' + tipo + ' py-2';
  div.textContent = msg;
}

function escapeHtml(str) {
  if (str === null || str === undefined) return '';
  return String(str).replace(/[&<>"']/g, m => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[m]));
}
'@
[System.IO.File]::WriteAllText("C:\planta-rapel-2026\js\usuarios.js", $usuariosJs, $utf8)
Write-Host "usuarios.js OK" -ForegroundColor Green

# === Agregar metodos en api.js ===
$apiPath = "C:\planta-rapel-2026\js\api.js"
$apiContent = Get-Content $apiPath -Raw
if ($apiContent -notmatch 'crearUsuario') {
  $old = "getDashboard: (filtros) => post({ accion: 'getDashboard', filtros })"
  $new = "getDashboard: (filtros) => post({ accion: 'getDashboard', filtros }),`n  crearUsuario: (datos) => post({ accion: 'crearUsuario', datos }),`n  listarUsuarios: () => post({ accion: 'listarUsuarios' }),`n  cambiarEstadoUsuario: (id, activo) => post({ accion: 'cambiarEstadoUsuario', id, activo })"
  $apiContent = $apiContent.Replace($old, $new)
  [System.IO.File]::WriteAllText($apiPath, $apiContent, $utf8)
  Write-Host "api.js: metodos de usuarios agregados" -ForegroundColor Green
}

# === Agregar boton "Gestion de Usuarios" en home.html ===
$homePath = "C:\planta-rapel-2026\home.html"
$homeContent = Get-Content $homePath -Raw
if ($homeContent -notmatch 'usuarios\.html') {
  $btnUsuarios = '<a href="usuarios.html" class="btn btn-lg ms-2" style="background:#c8102e; color:white;" id="btnUsuarios">Gestion de Usuarios</a>'
  # Insertar despues del btnDashboard
  $homeContent = $homeContent -replace '(<a href="dashboard\.html"[^<]*</a>)', "`$1$btnUsuarios"
  [System.IO.File]::WriteAllText($homePath, $homeContent, $utf8)
  Write-Host "home.html: boton Gestion de Usuarios agregado" -ForegroundColor Green
}

# === Actualizar version ===
$version = (Get-Date).ToString('yyyyMMdd-HHmmss')
[System.IO.File]::WriteAllText("C:\planta-rapel-2026\version.json", "{`"version`": `"$version`"}", $utf8)

git add .
git commit -m "Dashboard columnas correctas + Modulo Gestion de Usuarios"
git push

Write-Host ""
Write-Host "===== LISTO =====" -ForegroundColor Green
Write-Host "Verifica que el Apps Script tiene los 3 nuevos cases + las 3 funciones" -ForegroundColor Cyan
Write-Host "Espera 30 seg, Ctrl+Shift+R" -ForegroundColor Cyan