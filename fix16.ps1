cd C:\planta-rapel-2026
$utf8 = [System.Text.UTF8Encoding]::new($true)

# === dashboard.html ===
$dashboardHtml = @'
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Dashboard - Planta Rapel 2026</title>
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
<script src="https://cdn.sheetjs.com/xlsx-0.20.1/package/dist/xlsx.full.min.js"></script>
<link rel="stylesheet" href="css/styles.css">
<script src="js/version-check.js"></script>
</head>
<body>
<nav class="navbar navbar-dark" style="background:#1a3a6c;">
  <div class="container-fluid">
    <span><img src="assets/logo-unifrutti.png" alt="Unifrutti" class="logo-nav" onerror="this.style.display='none'; this.nextElementSibling.style.display='inline-block';"><span class="logo-nav-fallback" style="display:none;">UNIFRUTTI</span><span class="navbar-brand">Dashboard Gestion Humana</span></span>
    <div>
      <button class="btn btn-sm btn-light me-2" id="btnHome">Inicio</button>
      <button class="btn btn-sm btn-outline-light" id="btnSalir">Salir</button>
    </div>
  </div>
</nav>

<div class="container my-3" style="max-width:1400px;">
  <!-- Filtros -->
  <div class="card mb-3">
    <div class="card-body">
      <h6 class="mb-3 fw-bold">Filtros</h6>
      <div class="row g-2">
        <div class="col-md-2">
          <label class="form-label small mb-1">Fecha inicio</label>
          <input type="date" class="form-control form-control-sm" id="fechaInicio">
        </div>
        <div class="col-md-2">
          <label class="form-label small mb-1">Fecha fin</label>
          <input type="date" class="form-control form-control-sm" id="fechaFin">
        </div>
        <div class="col-md-2">
          <label class="form-label small mb-1">Ruta</label>
          <input type="text" class="form-control form-control-sm" id="filtroRuta" placeholder="Todas">
        </div>
        <div class="col-md-2">
          <label class="form-label small mb-1">Turno</label>
          <select class="form-select form-select-sm" id="filtroTurno">
            <option value="">Todos</option>
            <option value="DIA">DIA</option>
            <option value="NOCHE">NOCHE</option>
          </select>
        </div>
        <div class="col-md-2">
          <label class="form-label small mb-1">Empresa</label>
          <select class="form-select form-select-sm" id="filtroEmpresa">
            <option value="">Todas</option>
            <option value="RAPEL">RAPEL</option>
            <option value="VERFRUT">VERFRUT</option>
          </select>
        </div>
        <div class="col-md-2 d-flex align-items-end">
          <button class="btn btn-primary btn-sm w-100" id="btnAplicar">Aplicar</button>
        </div>
      </div>
      <div class="row g-2 mt-1">
        <div class="col-md-3">
          <button class="btn btn-outline-secondary btn-sm w-100" id="btnHoy">Hoy</button>
        </div>
        <div class="col-md-3">
          <button class="btn btn-outline-secondary btn-sm w-100" id="btnUltima7">Ultimos 7 dias</button>
        </div>
        <div class="col-md-3">
          <button class="btn btn-outline-secondary btn-sm w-100" id="btnEsteMes">Este mes</button>
        </div>
        <div class="col-md-3">
          <button class="btn btn-success btn-sm w-100" id="btnExportar">Exportar a Excel</button>
        </div>
      </div>
    </div>
  </div>

  <!-- Resumen -->
  <div class="row g-2 mb-3">
    <div class="col-md-3">
      <div class="card text-white" style="background:#1a3a6c;">
        <div class="card-body py-3 text-center">
          <div class="small">Asistencias</div>
          <div style="font-size:2.5rem; font-weight:bold;" id="totalAsist">-</div>
        </div>
      </div>
    </div>
    <div class="col-md-3">
      <div class="card text-white" style="background:#c8102e;">
        <div class="card-body py-3 text-center">
          <div class="small">Faltantes</div>
          <div style="font-size:2.5rem; font-weight:bold;" id="totalFalt">-</div>
        </div>
      </div>
    </div>
    <div class="col-md-3">
      <div class="card text-white bg-success">
        <div class="card-body py-3 text-center">
          <div class="small">% Asistencia</div>
          <div style="font-size:2.5rem; font-weight:bold;" id="pctAsist">-</div>
        </div>
      </div>
    </div>
    <div class="col-md-3">
      <div class="card text-white bg-secondary">
        <div class="card-body py-3 text-center">
          <div class="small">Periodo</div>
          <div style="font-size:1rem; font-weight:bold; padding-top:18px;" id="periodo">-</div>
        </div>
      </div>
    </div>
  </div>

  <!-- Resumen detallado -->
  <div class="row g-2 mb-3">
    <div class="col-md-6">
      <div class="card">
        <div class="card-body py-2">
          <h6 class="fw-bold">Asistencias por Ruta</h6>
          <div id="resPorRuta" class="small"></div>
        </div>
      </div>
    </div>
    <div class="col-md-6">
      <div class="card">
        <div class="card-body py-2">
          <h6 class="fw-bold">Faltantes por Motivo</h6>
          <div id="resFaltMotivo" class="small"></div>
        </div>
      </div>
    </div>
  </div>

  <!-- Tabs -->
  <ul class="nav nav-tabs">
    <li class="nav-item"><a class="nav-link active" data-bs-toggle="tab" href="#tabAsist">Asistencias (<span id="cntAsist">0</span>)</a></li>
    <li class="nav-item"><a class="nav-link" data-bs-toggle="tab" href="#tabFalt">Faltantes (<span id="cntFalt">0</span>)</a></li>
  </ul>
  <div class="tab-content border border-top-0 p-2 bg-white">
    <div class="tab-pane fade show active" id="tabAsist">
      <input type="text" class="form-control form-control-sm mb-2" id="buscadorAsist" placeholder="Buscar por DNI o nombre...">
      <div class="table-responsive" style="max-height:500px; overflow-y:auto;">
        <table class="table table-sm table-hover">
          <thead style="position:sticky; top:0; background:#1a3a6c; color:white; z-index:1;">
            <tr>
              <th>Hora</th><th>DNI</th><th>Nombre</th><th>Empresa</th><th>Ruta</th>
              <th>Bus</th><th>Turno</th><th>Zona</th><th>Encargado</th>
            </tr>
          </thead>
          <tbody id="tblAsist"></tbody>
        </table>
      </div>
    </div>
    <div class="tab-pane fade" id="tabFalt">
      <input type="text" class="form-control form-control-sm mb-2" id="buscadorFalt" placeholder="Buscar por DNI o nombre...">
      <div class="table-responsive" style="max-height:500px; overflow-y:auto;">
        <table class="table table-sm table-hover">
          <thead style="position:sticky; top:0; background:#c8102e; color:white; z-index:1;">
            <tr>
              <th>Hora</th><th>DNI</th><th>Nombre</th><th>Empresa</th><th>Ruta</th>
              <th>Bus</th><th>Motivo</th><th>Observacion</th><th>Encargado</th>
            </tr>
          </thead>
          <tbody id="tblFalt"></tbody>
        </table>
      </div>
    </div>
  </div>
  
  <div id="cargando" class="text-center py-4" style="display:none;">
    <div class="spinner-border text-primary"></div>
    <p class="mt-2">Cargando dashboard...</p>
  </div>
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"></script>
<script src="js/config.js"></script>
<script src="js/api.js"></script>
<script src="js/auth.js"></script>
<script src="js/dashboard.js"></script>
</body>
</html>
'@
[System.IO.File]::WriteAllText("C:\planta-rapel-2026\dashboard.html", $dashboardHtml, $utf8)
Write-Host "dashboard.html OK" -ForegroundColor Green

# === js/dashboard.js ===
$dashboardJs = @'
let asistenciasData = [];
let faltantesData = [];

document.addEventListener('DOMContentLoaded', () => {
  if (!Auth.requiereLogin()) return;
  
  const usuario = Auth.obtenerUsuario();
  if (!usuario || usuario.rol !== 'admin') {
    alert('Solo administradores pueden ver el dashboard');
    window.location.href = 'home.html';
    return;
  }
  
  // Fechas por defecto: hoy
  const hoy = new Date().toISOString().substring(0, 10);
  document.getElementById('fechaInicio').value = hoy;
  document.getElementById('fechaFin').value = hoy;
  
  document.getElementById('btnHome').addEventListener('click', () => window.location.href = 'home.html');
  document.getElementById('btnSalir').addEventListener('click', () => { Auth.cerrarSesion(); window.location.href = 'index.html'; });
  document.getElementById('btnAplicar').addEventListener('click', cargarDashboard);
  document.getElementById('btnHoy').addEventListener('click', () => { setRango(0, 0); cargarDashboard(); });
  document.getElementById('btnUltima7').addEventListener('click', () => { setRango(7, 0); cargarDashboard(); });
  document.getElementById('btnEsteMes').addEventListener('click', () => { setRangoMes(); cargarDashboard(); });
  document.getElementById('btnExportar').addEventListener('click', exportarExcel);
  
  document.getElementById('buscadorAsist').addEventListener('input', (e) => filtrarTabla('tblAsist', asistenciasData, e.target.value, 'asistencia'));
  document.getElementById('buscadorFalt').addEventListener('input', (e) => filtrarTabla('tblFalt', faltantesData, e.target.value, 'faltante'));
  
  cargarDashboard();
});

function setRango(diasAtras, diasAdelante) {
  const hoy = new Date();
  const inicio = new Date(hoy); inicio.setDate(hoy.getDate() - diasAtras);
  const fin = new Date(hoy); fin.setDate(hoy.getDate() + diasAdelante);
  document.getElementById('fechaInicio').value = inicio.toISOString().substring(0, 10);
  document.getElementById('fechaFin').value = fin.toISOString().substring(0, 10);
}

function setRangoMes() {
  const hoy = new Date();
  const primero = new Date(hoy.getFullYear(), hoy.getMonth(), 1);
  document.getElementById('fechaInicio').value = primero.toISOString().substring(0, 10);
  document.getElementById('fechaFin').value = hoy.toISOString().substring(0, 10);
}

function isoADdMmYyyy(iso) {
  if (!iso) return '';
  const partes = iso.split('-');
  if (partes.length !== 3) return iso;
  return partes[2] + '/' + partes[1] + '/' + partes[0];
}

async function cargarDashboard() {
  const filtros = {
    fechaInicio: isoADdMmYyyy(document.getElementById('fechaInicio').value),
    fechaFin: isoADdMmYyyy(document.getElementById('fechaFin').value),
    ruta: document.getElementById('filtroRuta').value.trim(),
    turno: document.getElementById('filtroTurno').value,
    empresa: document.getElementById('filtroEmpresa').value
  };
  
  document.getElementById('cargando').style.display = 'block';
  
  try {
    const resp = await API.getDashboard(filtros);
    if (!resp.ok) {
      alert('Error: ' + (resp.error || 'desconocido'));
      return;
    }
    
    asistenciasData = resp.asistencias || [];
    faltantesData = resp.faltantes || [];
    const r = resp.resumen;
    
    document.getElementById('totalAsist').textContent = r.totalAsistencias;
    document.getElementById('totalFalt').textContent = r.totalFaltantes;
    const total = r.totalAsistencias + r.totalFaltantes;
    document.getElementById('pctAsist').textContent = total > 0 ? Math.round((r.totalAsistencias / total) * 100) + '%' : '-';
    document.getElementById('periodo').textContent = r.fechaInicio + ' al ' + r.fechaFin;
    
    document.getElementById('resPorRuta').innerHTML = renderResumen(r.porRuta);
    document.getElementById('resFaltMotivo').innerHTML = renderResumen(r.faltantesPorMotivo);
    
    document.getElementById('cntAsist').textContent = asistenciasData.length;
    document.getElementById('cntFalt').textContent = faltantesData.length;
    
    renderTablaAsist(asistenciasData);
    renderTablaFalt(faltantesData);
  } catch (e) {
    alert('Error de conexion: ' + e.message);
  } finally {
    document.getElementById('cargando').style.display = 'none';
  }
}

function renderResumen(map) {
  if (!map || Object.keys(map).length === 0) return '<em class="text-muted">Sin datos</em>';
  const items = Object.keys(map).sort().map(k => 
    '<div class="d-flex justify-content-between"><span>' + escapeHtml(k) + '</span><strong>' + map[k] + '</strong></div>'
  );
  return items.join('');
}

function renderTablaAsist(data) {
  const tbody = document.getElementById('tblAsist');
  if (data.length === 0) {
    tbody.innerHTML = '<tr><td colspan="9" class="text-center text-muted py-3">Sin asistencias en el periodo</td></tr>';
    return;
  }
  tbody.innerHTML = data.map(a => 
    '<tr>' +
    '<td>' + escapeHtml(a.hora) + '</td>' +
    '<td>' + escapeHtml(a.dni) + '</td>' +
    '<td>' + escapeHtml(a.nombre) + '</td>' +
    '<td><span class="badge bg-secondary">' + escapeHtml(a.empresa) + '</span></td>' +
    '<td>' + escapeHtml(a.ruta_sesion) + '</td>' +
    '<td>' + escapeHtml(a.codigo_bus) + '</td>' +
    '<td>' + escapeHtml(a.turno) + '</td>' +
    '<td>' + escapeHtml(a.zona_packing) + '</td>' +
    '<td>' + escapeHtml(a.encargado_nombre) + '</td>' +
    '</tr>'
  ).join('');
}

function renderTablaFalt(data) {
  const tbody = document.getElementById('tblFalt');
  if (data.length === 0) {
    tbody.innerHTML = '<tr><td colspan="9" class="text-center text-muted py-3">Sin faltantes en el periodo</td></tr>';
    return;
  }
  tbody.innerHTML = data.map(f => 
    '<tr>' +
    '<td>' + escapeHtml(f.hora) + '</td>' +
    '<td>' + escapeHtml(f.dni) + '</td>' +
    '<td>' + escapeHtml(f.nombre) + '</td>' +
    '<td><span class="badge bg-secondary">' + escapeHtml(f.empresa) + '</span></td>' +
    '<td>' + escapeHtml(f.ruta) + '</td>' +
    '<td>' + escapeHtml(f.codigo_bus) + '</td>' +
    '<td><span class="badge bg-danger">' + escapeHtml(f.motivo) + '</span></td>' +
    '<td>' + escapeHtml(f.observacion) + '</td>' +
    '<td>' + escapeHtml(f.encargado_nombre) + '</td>' +
    '</tr>'
  ).join('');
}

function filtrarTabla(tablaId, data, query, tipo) {
  query = query.toLowerCase().trim();
  if (!query) {
    if (tipo === 'asistencia') renderTablaAsist(data);
    else renderTablaFalt(data);
    return;
  }
  const filtrado = data.filter(r => 
    String(r.dni).toLowerCase().includes(query) || 
    String(r.nombre).toLowerCase().includes(query)
  );
  if (tipo === 'asistencia') renderTablaAsist(filtrado);
  else renderTablaFalt(filtrado);
}

function exportarExcel() {
  if (asistenciasData.length === 0 && faltantesData.length === 0) {
    alert('No hay datos para exportar');
    return;
  }
  const wb = XLSX.utils.book_new();
  if (asistenciasData.length > 0) {
    const wsA = XLSX.utils.json_to_sheet(asistenciasData);
    XLSX.utils.book_append_sheet(wb, wsA, "Asistencias");
  }
  if (faltantesData.length > 0) {
    const wsF = XLSX.utils.json_to_sheet(faltantesData);
    XLSX.utils.book_append_sheet(wb, wsF, "Faltantes");
  }
  const fInicio = document.getElementById('fechaInicio').value;
  const fFin = document.getElementById('fechaFin').value;
  XLSX.writeFile(wb, 'Reporte_Planta_' + fInicio + '_a_' + fFin + '.xlsx');
}

function escapeHtml(str) {
  if (str === null || str === undefined) return '';
  return String(str).replace(/[&<>"']/g, m => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[m]));
}
'@
[System.IO.File]::WriteAllText("C:\planta-rapel-2026\js\dashboard.js", $dashboardJs, $utf8)
Write-Host "dashboard.js OK" -ForegroundColor Green

# === Agregar getDashboard a api.js ===
$apiPath = "C:\planta-rapel-2026\js\api.js"
$apiContent = Get-Content $apiPath -Raw
if ($apiContent -notmatch 'getDashboard') {
  $old = "registrarFaltantes: (faltantes, sesion) => post({ accion: 'registrarFaltantes', faltantes, sesion: extraerSesion(sesion) })"
  $new = "registrarFaltantes: (faltantes, sesion) => post({ accion: 'registrarFaltantes', faltantes, sesion: extraerSesion(sesion) }),`n  getDashboard: (filtros) => post({ accion: 'getDashboard', filtros })"
  $apiContent = $apiContent.Replace($old, $new)
  [System.IO.File]::WriteAllText($apiPath, $apiContent, $utf8)
  Write-Host "api.js actualizado con getDashboard" -ForegroundColor Green
} else {
  Write-Host "api.js ya tiene getDashboard" -ForegroundColor Yellow
}

# === Agregar boton Dashboard en home.html para admin ===
$homePath = "C:\planta-rapel-2026\home.html"
$homeContent = Get-Content $homePath -Raw
if ($homeContent -notmatch 'dashboard.html') {
  # Buscar el final del body para agregar un boton
  $btnDashboard = "<a href=`"dashboard.html`" class=`"btn btn-lg`" style=`"background:#1a3a6c; color:white;`" id=`"btnDashboard`">Ir al Dashboard de Gestion Humana</a>"
  $homeContent = $homeContent -replace '(</div>\s*</div>\s*<script)', "<div class=`"text-center mt-3`">$btnDashboard</div>`n`$1"
  [System.IO.File]::WriteAllText($homePath, $homeContent, $utf8)
  Write-Host "home.html actualizado con boton Dashboard" -ForegroundColor Green
} else {
  Write-Host "home.html ya tiene boton Dashboard" -ForegroundColor Yellow
}

# === Actualizar version.json para forzar refresh ===
$version = (Get-Date).ToString('yyyyMMdd-HHmmss')
[System.IO.File]::WriteAllText("C:\planta-rapel-2026\version.json", "{`"version`": `"$version`"}", $utf8)
Write-Host "version.json actualizado: $version" -ForegroundColor Green

git add .
git commit -m "Dia 4: Dashboard Gestion Humana con filtros, busqueda y export Excel"
git push

Write-Host ""
Write-Host "===== DASHBOARD LISTO =====" -ForegroundColor Green
Write-Host "1. Verifica que ya hiciste los pasos del Apps Script (case + funciones)" -ForegroundColor Cyan
Write-Host "2. Espera 30 seg para GitHub Pages" -ForegroundColor Cyan
Write-Host "3. Loguea como jtimoteo (admin) y dale al boton Dashboard" -ForegroundColor Cyan