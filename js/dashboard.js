let asistenciasData = [];
let faltantesData = [];

document.addEventListener('DOMContentLoaded', () => {
  if (!Auth.requiereLogin()) return;
  
  const usuario = (function(){try{const r=localStorage.getItem('planta_usuario')||localStorage.getItem('usuario');return r?JSON.parse(r):null;}catch(e){return null;}})();
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