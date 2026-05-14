let asistenciasData = [];
let faltantesData = [];

document.addEventListener('DOMContentLoaded', () => {
  if (!Auth.requiereLogin()) return;
  
  // Solo admins acceden al Dashboard. Defensivo: sin sesion o rol distinto de 'admin' -> fuera.
  const usuario = Auth.obtenerSesion();
  if (!usuario || usuario.rol !== 'admin') {
    alert('Solo administradores pueden acceder al Dashboard');
    window.location.href = 'home.html';
    return;
  }
  
  // Fechas por defecto: hoy
  const hoy = new Date().toISOString().substring(0, 10);
  document.getElementById('fechaInicio').value = hoy;
  document.getElementById('fechaFin').value = hoy;
  
  document.getElementById('btnHome').addEventListener('click', () => window.location.href = 'home.html');
  document.getElementById('btnSalir').addEventListener('click', () => { (function(){localStorage.removeItem('planta_usuario');localStorage.removeItem('usuario');sessionStorage.clear();})(); window.location.href = 'index.html'; });
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
    
    // Total Programado = Asistencias + Faltantes
    const totalProg = r.totalAsistencias + r.totalFaltantes;
    const elTP = document.getElementById('totalProgramado');
    if (elTP) elTP.textContent = totalProg;
    
    // Poblar select de rutas dinamicamente
    poblarRutasDinamicas();
    
    document.getElementById('resPorRuta').innerHTML = renderResumen(r.porRuta);
    renderCharts(r);
    document.getElementById('resFaltMotivo').innerHTML = renderResumen(r.faltantesPorMotivo);
    
    document.getElementById('cntAsist').textContent = asistenciasData.length;
    document.getElementById('cntFalt').textContent = faltantesData.length;
    
    renderTablaAsist(asistenciasData);
    renderTablaFalt(faltantesData);

    // Comparativas de tendencia (hoy/ayer, mes actual/anterior)
    cargarComparativas();
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
let chartRutaInst = null;
let chartFaltInst = null;
let chartZonaInst = null;

// Paleta de colores variada para los graficos del dashboard
const PALETA_CHARTS = [
  '#1a3a6c', // azul Unifrutti
  '#c8102e', // rojo Unifrutti
  '#28a745', // verde
  '#ffc107', // amarillo
  '#fd7e14', // naranja
  '#6f42c1', // violeta
  '#20c997', // turquesa
  '#e83e8c', // rosa fuerte
  '#17a2b8', // celeste
  '#6c757d', // gris medio
  '#343a40', // gris oscuro
  '#0dcaf0', // celeste claro
  '#dc3545', // rojo brillante
  '#198754', // verde oscuro
  '#0d6efd'  // azul Bootstrap
];

// Plugin inline: dibuja el numero encima de cada barra (sin dependencias externas)
const datalabelsPlugin = {
  id: 'datalabels',
  afterDatasetsDraw(chart) {
    const { ctx } = chart;
    chart.data.datasets.forEach((dataset, i) => {
      const meta = chart.getDatasetMeta(i);
      if (meta.hidden) return;
      meta.data.forEach((bar, index) => {
        const value = dataset.data[index];
        if (value === 0 || value == null) return;
        ctx.fillStyle = '#000';
        ctx.font = 'bold 11px sans-serif';
        ctx.textAlign = 'center';
        ctx.textBaseline = 'bottom';
        ctx.fillText(value, bar.x, bar.y - 4);
      });
    });
  }
};

// Plugin inline: dibuja el numero dentro de cada segmento del donut
const datalabelsDoughnut = {
  id: 'datalabelsDoughnut',
  afterDatasetsDraw(chart) {
    const { ctx } = chart;
    chart.data.datasets.forEach((dataset, i) => {
      const meta = chart.getDatasetMeta(i);
      meta.data.forEach((arc, index) => {
        const value = dataset.data[index];
        if (!value) return;
        const pos = arc.tooltipPosition();
        ctx.fillStyle = '#fff';
        ctx.font = 'bold 14px sans-serif';
        ctx.textAlign = 'center';
        ctx.textBaseline = 'middle';
        ctx.fillText(value, pos.x, pos.y);
      });
    });
  }
};

function renderCharts(resumen) {
  if (typeof Chart === 'undefined') return;
  
  // Chart Asistencias por Ruta
  const ctxR = document.getElementById('chartRuta');
  if (ctxR) {
    if (chartRutaInst) chartRutaInst.destroy();
    const rutasOrdenadas = Object.entries(resumen.porRuta || {})
      .sort((a, b) => b[1] - a[1]);
    const rutas = rutasOrdenadas.map(e => e[0]);
    const valores = rutasOrdenadas.map(e => e[1]);
    chartRutaInst = new Chart(ctxR, {
      type: 'bar',
      data: {
        labels: rutas,
        datasets: [{
          label: 'Asistencias',
          data: valores,
          backgroundColor: rutas.map((_, i) => PALETA_CHARTS[i % PALETA_CHARTS.length]),
          borderColor: rutas.map((_, i) => PALETA_CHARTS[i % PALETA_CHARTS.length]),
          borderWidth: 1
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        animation: false,
        plugins: { legend: { display: false } },
        scales: { y: { beginAtZero: true, ticks: { stepSize: 1 } } }
      },
      plugins: [datalabelsPlugin]
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
    } else {
      const valores = motivos.map(k => resumen.faltantesPorMotivo[k]);
      chartFaltInst = new Chart(ctxF, {
        type: 'doughnut',
        data: {
          labels: motivos,
          datasets: [{
            data: valores,
            backgroundColor: motivos.map((_, i) => PALETA_CHARTS[i % PALETA_CHARTS.length]),
            borderColor: '#ffffff',
            borderWidth: 3,
            hoverOffset: 15
          }]
        },
        options: {
          responsive: true,
          maintainAspectRatio: false,
          animation: false,
          plugins: {
            legend: {
              position: 'bottom',
              labels: {
                font: { weight: 'bold', size: 12 },
                padding: 12
              }
            }
          }
        },
        plugins: [datalabelsDoughnut]
      });
    }
  }

  // Chart Asistencias por Zona / Packing
  const ctxZ = document.getElementById('chartZona');
  if (ctxZ) {
    if (chartZonaInst) chartZonaInst.destroy();
    const porZona = {};
    asistenciasData.forEach(a => {
      const z = a.zona_packing || 'SIN ZONA';
      porZona[z] = (porZona[z] || 0) + 1;
    });
    const zonaEntries = Object.entries(porZona).sort((a, b) => b[1] - a[1]);
    const zonasOrd = zonaEntries.map(e => e[0]);
    const valoresZona = zonaEntries.map(e => e[1]);
    chartZonaInst = new Chart(ctxZ, {
      type: 'bar',
      data: {
        labels: zonasOrd,
        datasets: [{
          label: 'Asistencias',
          data: valoresZona,
          backgroundColor: zonasOrd.map((_, i) => PALETA_CHARTS[i % PALETA_CHARTS.length]),
          borderColor: zonasOrd.map((_, i) => PALETA_CHARTS[i % PALETA_CHARTS.length]),
          borderWidth: 1
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        animation: false,
        plugins: { legend: { display: false } },
        scales: { y: { beginAtZero: true, ticks: { stepSize: 1, precision: 0 } } }
      },
      plugins: [datalabelsPlugin]
    });
  }
}

// Pobla el select de rutas con las rutas presentes en los datos cargados
function poblarRutasDinamicas() {
  const select = document.getElementById('filtroRuta');
  if (!select) return;
  const seleccionActual = select.value;
  const rutasSet = new Set();
  (asistenciasData || []).forEach(a => {
    if (a && a.ruta_sesion) rutasSet.add(String(a.ruta_sesion).trim().toUpperCase());
  });
  (faltantesData || []).forEach(f => {
    if (f && f.ruta) rutasSet.add(String(f.ruta).trim().toUpperCase());
  });
  const rutas = Array.from(rutasSet).filter(r => r).sort();
  select.innerHTML = '<option value="">Todas</option>' +
    rutas.map(r => '<option value="' + escapeHtml(r) + '">' + escapeHtml(r) + '</option>').join('');
  if (seleccionActual && rutas.indexOf(seleccionActual) !== -1) {
    select.value = seleccionActual;
  }
}

// Comparativas de tendencia: hoy vs ayer, mes actual vs mes anterior.
// Hace 4 llamadas a API.getDashboard en paralelo (Promise.all).
async function cargarComparativas() {
  // Fecha local a ISO (yyyy-mm-dd) sin desfase de zona horaria
  function isoLocal(d) {
    const y = d.getFullYear();
    const m = String(d.getMonth() + 1).padStart(2, '0');
    const dia = String(d.getDate()).padStart(2, '0');
    return y + '-' + m + '-' + dia;
  }

  const hoy = new Date();
  const ayer = new Date(hoy); ayer.setDate(hoy.getDate() - 1);
  const primerDiaMes = new Date(hoy.getFullYear(), hoy.getMonth(), 1);
  const primerDiaMesAnt = new Date(hoy.getFullYear(), hoy.getMonth() - 1, 1);
  const ultimoDiaMesAnt = new Date(hoy.getFullYear(), hoy.getMonth(), 0);

  // Rangos en formato dd/MM/yyyy (igual que cargarDashboard)
  const rangos = {
    hoy:         { fechaInicio: isoADdMmYyyy(isoLocal(hoy)),            fechaFin: isoADdMmYyyy(isoLocal(hoy)) },
    ayer:        { fechaInicio: isoADdMmYyyy(isoLocal(ayer)),           fechaFin: isoADdMmYyyy(isoLocal(ayer)) },
    mesActual:   { fechaInicio: isoADdMmYyyy(isoLocal(primerDiaMes)),   fechaFin: isoADdMmYyyy(isoLocal(hoy)) },
    mesAnterior: { fechaInicio: isoADdMmYyyy(isoLocal(primerDiaMesAnt)), fechaFin: isoADdMmYyyy(isoLocal(ultimoDiaMesAnt)) }
  };

  // Una llamada: devuelve { ok, total }. Nunca lanza (try/catch propio).
  async function pedirTotal(rango) {
    try {
      const resp = await API.getDashboard({
        fechaInicio: rango.fechaInicio,
        fechaFin: rango.fechaFin,
        ruta: '', turno: '', empresa: ''
      });
      if (resp && resp.ok && resp.resumen) {
        return { ok: true, total: resp.resumen.totalAsistencias || 0 };
      }
      return { ok: false, total: 0 };
    } catch (e) {
      return { ok: false, total: 0 };
    }
  }

  // Las 4 llamadas en paralelo
  const [rHoy, rAyer, rMes, rMesAnt] = await Promise.all([
    pedirTotal(rangos.hoy),
    pedirTotal(rangos.ayer),
    pedirTotal(rangos.mesActual),
    pedirTotal(rangos.mesAnterior)
  ]);

  // Actualizar stats (si una llamada fallo, muestra "-" sin afectar las demas)
  document.getElementById('statHoy').textContent    = rHoy.ok    ? rHoy.total    : '-';
  document.getElementById('statAyer').textContent   = rAyer.ok   ? rAyer.total   : '-';
  document.getElementById('statMes').textContent    = rMes.ok    ? rMes.total    : '-';
  document.getElementById('statMesAnt').textContent = rMesAnt.ok ? rMesAnt.total : '-';

  // Variacion porcentual
  function mostrarVariacion(elId, actual, anterior, hayDatos) {
    const el = document.getElementById(elId);
    if (!el) return;
    if (!hayDatos) { el.textContent = ''; el.style.color = ''; return; }
    const variacion = ((actual - anterior) / Math.max(anterior, 1)) * 100;
    if (variacion > 0) {
      el.textContent = '↑ +' + variacion.toFixed(1) + '%';
      el.style.color = '#28a745';
    } else if (variacion < 0) {
      el.textContent = '↓ ' + variacion.toFixed(1) + '%';
      el.style.color = '#c8102e';
    } else {
      el.textContent = '= sin cambio';
      el.style.color = '#6c757d';
    }
  }
  mostrarVariacion('varHoy', rHoy.total, rAyer.total, rHoy.ok && rAyer.ok);
  mostrarVariacion('varMes', rMes.total, rMesAnt.total, rMes.ok && rMesAnt.ok);
}