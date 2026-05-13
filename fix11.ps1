cd C:\planta-rapel-2026
$utf8 = [System.Text.UTF8Encoding]::new($true)

# === faltantes.html ===
$faltantesHtml = @'
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Registrar Faltantes - Planta Rapel 2026</title>
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
<link rel="stylesheet" href="css/styles.css">
</head>
<body>
<nav class="navbar navbar-dark" style="background:#c8102e;">
  <div class="container-fluid">
    <span class="navbar-brand">Registrar Faltantes</span>
    <button class="btn btn-sm btn-light" id="btnVolver">Volver al Scanner</button>
  </div>
</nav>

<div class="container my-3" style="max-width:900px;">
  <div class="card mb-3"><div class="card-body py-2"><div class="row small">
    <div class="col-6">
      <div><strong>Ruta:</strong> <span id="lblRuta"></span></div>
      <div><strong>Bus:</strong> <span id="lblBus"></span></div>
      <div><strong>Encargado:</strong> <span id="lblEncargado"></span></div>
    </div>
    <div class="col-6">
      <div><strong>Turno:</strong> <span class="badge bg-primary" id="lblTurno"></span></div>
      <div><strong>Asistencias OK:</strong> <span id="lblAsistencias"></span></div>
      <div><strong>Faltantes a registrar:</strong> <span class="badge bg-danger" id="lblFaltan"></span></div>
    </div>
  </div></div></div>
  
  <div class="alert alert-warning">
    <strong>Instrucciones:</strong> Ingresa el DNI de cada trabajador faltante, selecciona el motivo, y agrega una observación si es necesario. El sistema buscará automáticamente el nombre al ingresar el DNI.
  </div>
  
  <div class="table-responsive">
    <table class="table table-bordered table-sm align-middle">
      <thead style="background:#1a3a6c; color:white;">
        <tr>
          <th>#</th>
          <th>DNI</th>
          <th>Nombre</th>
          <th>Empresa</th>
          <th>Motivo</th>
          <th>Observacion</th>
        </tr>
      </thead>
      <tbody id="tablaFaltantes"></tbody>
    </table>
  </div>
  
  <button id="btnConfirmar" class="btn btn-lg w-100 mt-3" style="background:#c8102e; color:white;">
    Confirmar Faltantes y Finalizar Sesion
  </button>
</div>

<div class="modal fade" id="modalExito" tabindex="-1"><div class="modal-dialog modal-dialog-centered"><div class="modal-content">
  <div class="modal-header bg-success text-white"><h5 class="modal-title">Sesion Finalizada</h5></div>
  <div class="modal-body"><p id="lblMsgExito"></p></div>
  <div class="modal-footer"><button type="button" class="btn btn-primary" data-bs-dismiss="modal" onclick="sessionStorage.clear(); window.location.href='config.html';">Nueva Sesion</button></div>
</div></div></div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"></script>
<script src="js/config.js"></script>
<script src="js/api.js"></script>
<script src="js/auth.js"></script>
<script src="js/faltantes.js"></script>
</body>
</html>
'@
[System.IO.File]::WriteAllText("C:\planta-rapel-2026\faltantes.html", $faltantesHtml, $utf8)
Write-Host "faltantes.html OK" -ForegroundColor Green

# === js/faltantes.js ===
$faltantesJs = @'
document.addEventListener('DOMContentLoaded', () => {
  if (!Auth.requiereLogin()) return;
  
  const config = BusConfig.obtener();
  if (!config) {
    window.location.href = 'config.html';
    return;
  }
  
  const params = new URLSearchParams(window.location.search);
  const faltan = parseInt(params.get('faltan') || '0', 10);
  
  if (faltan <= 0) {
    window.location.href = 'scanner.html';
    return;
  }
  
  const asistencias = JSON.parse(sessionStorage.getItem('planta_asistencias') || '[]');
  
  document.getElementById('lblRuta').textContent = config.ruta;
  document.getElementById('lblBus').textContent = config.codigoBus;
  document.getElementById('lblTurno').textContent = config.turno;
  document.getElementById('lblEncargado').textContent = config.encargadoNombre;
  document.getElementById('lblAsistencias').textContent = asistencias.length;
  document.getElementById('lblFaltan').textContent = faltan;
  
  document.getElementById('btnVolver').addEventListener('click', () => {
    if (confirm('Volver al scanner? Las filas que llenaste se perderan.')) {
      window.location.href = 'scanner.html';
    }
  });
  
  document.getElementById('btnConfirmar').addEventListener('click', confirmarFaltantes);
  
  const tbody = document.getElementById('tablaFaltantes');
  for (let i = 1; i <= faltan; i++) {
    crearFilaFaltante(tbody, i);
  }
});

function crearFilaFaltante(tbody, numero) {
  const tr = document.createElement('tr');
  tr.innerHTML = 
    '<td class="text-center fw-bold">' + numero + '</td>' +
    '<td><input type="text" class="form-control form-control-sm dni-input" maxlength="8" placeholder="8 digitos" data-fila="' + numero + '"></td>' +
    '<td><span class="nombre-faltante text-muted" data-fila="' + numero + '">-</span></td>' +
    '<td><span class="empresa-faltante text-muted" data-fila="' + numero + '">-</span></td>' +
    '<td><select class="form-select form-select-sm motivo-select" data-fila="' + numero + '">' +
      '<option value="">Seleccione...</option>' +
      '<option value="Personales">Personales</option>' +
      '<option value="Salud">Salud</option>' +
      '<option value="Suspension">Suspension</option>' +
      '<option value="Otro">Otro</option>' +
    '</select></td>' +
    '<td><input type="text" class="form-control form-control-sm obs-input" data-fila="' + numero + '" placeholder="Opcional (obligatorio si Otro)"></td>';
  tbody.appendChild(tr);
  
  const dniInput = tr.querySelector('.dni-input');
  dniInput.addEventListener('blur', () => validarDniFaltante(dniInput, numero));
}

async function validarDniFaltante(input, fila) {
  const dni = String(input.value).trim().padStart(8, '0');
  const lblNombre = document.querySelector('.nombre-faltante[data-fila="' + fila + '"]');
  const lblEmpresa = document.querySelector('.empresa-faltante[data-fila="' + fila + '"]');
  
  if (dni.length !== 8 || !/^\d{8}$/.test(dni)) {
    lblNombre.textContent = 'DNI invalido';
    lblNombre.className = 'nombre-faltante text-danger';
    lblEmpresa.textContent = '-';
    input.dataset.validado = 'false';
    return;
  }
  
  lblNombre.textContent = 'Buscando...';
  lblNombre.className = 'nombre-faltante text-muted';
  
  try {
    const resp = await API.validarTrabajador(dni);
    if (resp.ok) {
      lblNombre.textContent = resp.trabajador.nombre;
      lblNombre.className = 'nombre-faltante text-success fw-bold';
      lblEmpresa.textContent = resp.trabajador.empresa;
      input.value = resp.trabajador.dni;
      input.dataset.validado = 'true';
      input.dataset.nombre = resp.trabajador.nombre;
      input.dataset.empresa = resp.trabajador.empresa;
    } else {
      lblNombre.textContent = 'No encontrado';
      lblNombre.className = 'nombre-faltante text-danger';
      lblEmpresa.textContent = '-';
      input.dataset.validado = 'false';
    }
  } catch (e) {
    lblNombre.textContent = 'Error de conexion';
    lblNombre.className = 'nombre-faltante text-danger';
    input.dataset.validado = 'false';
  }
}

async function confirmarFaltantes() {
  const config = BusConfig.obtener();
  const dnisInputs = document.querySelectorAll('.dni-input');
  const motivos = document.querySelectorAll('.motivo-select');
  const obs = document.querySelectorAll('.obs-input');
  
  const faltantes = [];
  for (let i = 0; i < dnisInputs.length; i++) {
    const input = dnisInputs[i];
    const motivo = motivos[i].value;
    const observacion = obs[i].value.trim();
    const numFila = i + 1;
    
    if (input.dataset.validado !== 'true') {
      alert('Fila ' + numFila + ': DNI no validado. Ingresa un DNI correcto.');
      input.focus();
      return;
    }
    if (!motivo) {
      alert('Fila ' + numFila + ': selecciona un motivo.');
      motivos[i].focus();
      return;
    }
    if (motivo === 'Otro' && !observacion) {
      alert('Fila ' + numFila + ': con motivo "Otro" se requiere observacion.');
      obs[i].focus();
      return;
    }
    
    faltantes.push({
      dni: String(input.value).trim().padStart(8, '0'),
      nombre: input.dataset.nombre,
      empresa: input.dataset.empresa,
      motivo: motivo,
      observacion: observacion
    });
  }
  
  // Validar DNIs duplicados en los faltantes
  const dnisSet = new Set();
  for (const f of faltantes) {
    if (dnisSet.has(f.dni)) {
      alert('DNI duplicado en los faltantes: ' + f.dni);
      return;
    }
    dnisSet.add(f.dni);
  }
  
  // Validar que faltantes no se solapen con asistencias ya registradas
  const asistencias = JSON.parse(sessionStorage.getItem('planta_asistencias') || '[]');
  const dnisAsistencias = new Set(asistencias.map(a => a.dni));
  for (const f of faltantes) {
    if (dnisAsistencias.has(f.dni)) {
      alert('El DNI ' + f.dni + ' (' + f.nombre + ') ya esta registrado como asistente. No puede ser faltante.');
      return;
    }
  }
  
  const btn = document.getElementById('btnConfirmar');
  btn.disabled = true;
  btn.innerHTML = '<span class="spinner-border spinner-border-sm me-2"></span>Guardando...';
  
  const resp = await API.registrarFaltantes(faltantes, config);
  
  if (!resp.ok) {
    alert('Error al guardar faltantes: ' + (resp.error || 'desconocido'));
    btn.disabled = false;
    btn.innerHTML = 'Confirmar Faltantes y Finalizar Sesion';
    return;
  }
  
  const fechaHoy = new Date().toLocaleDateString('es-PE');
  const msg = 'Registrado: ' + asistencias.length + ' asistencias + ' + resp.cantidad + ' faltantes\n' +
              'Ruta: ' + config.ruta + ' - Codigo: ' + config.codigoBus + ' - Fecha: ' + fechaHoy;
  document.getElementById('lblMsgExito').textContent = msg;
  
  const modal = new bootstrap.Modal(document.getElementById('modalExito'));
  modal.show();
}
'@
[System.IO.File]::WriteAllText("C:\planta-rapel-2026\js\faltantes.js", $faltantesJs, $utf8)
Write-Host "faltantes.js OK" -ForegroundColor Green

# === Agregar registrarFaltantes a api.js ===
$apiPath = "C:\planta-rapel-2026\js\api.js"
$apiContent = Get-Content $apiPath -Raw

if ($apiContent -notmatch 'registrarFaltantes') {
  # Buscar el cierre del objeto API y agregar la nueva funcion antes
  $apiContent = $apiContent -replace '(registrarAsistencias[^}]+?\}\s*)\}', "`$1,`n  registrarFaltantes: (faltantes, sesion) => post({ accion: 'registrarFaltantes', faltantes, sesion: extraerSesion(sesion) })`n}"
  
  # Si el regex no funciono (porque la estructura es distinta), agregar al final del archivo
  if ($apiContent -notmatch 'registrarFaltantes') {
    Write-Host "ATENCION: api.js tiene estructura inesperada. Reescribiendo completo..." -ForegroundColor Yellow
    $apiContent = @'
const API_URL = window.API_URL || 'https://script.google.com/macros/s/AKfycbxWIgvJzcVIzBA_9tUQqcjCLrcBoENDV9l2c2vD5FLLAAaw6OaVUUZJZu3kRwm2N0yo/exec';

async function post(payload) {
  try {
    const r = await fetch(API_URL, {
      method: 'POST',
      mode: 'cors',
      cache: 'no-cache',
      headers: { 'Content-Type': 'text/plain;charset=utf-8' },
      body: JSON.stringify(payload)
    });
    return await r.json();
  } catch (e) {
    return { ok: false, error: 'Error de red: ' + e.message };
  }
}

function extraerSesion(s) {
  return {
    ruta: s.ruta, codigoBus: s.codigoBus, placa: s.placa,
    zonaPacking: s.zonaPacking, turno: s.turno,
    encargadoDni: s.encargadoDni, encargadoNombre: s.encargadoNombre
  };
}

const API = {
  ping: () => post({ accion: 'ping' }),
  login: (username, password) => post({ accion: 'login', username, password }),
  validarTrabajador: (dni, empresa) => post({ accion: 'validarTrabajador', dni, empresa }),
  registrarAsistencias: (asistencias, sesion) => post({ accion: 'registrarAsistencias', asistencias, sesion: extraerSesion(sesion) }),
  registrarFaltantes: (faltantes, sesion) => post({ accion: 'registrarFaltantes', faltantes, sesion: extraerSesion(sesion) })
};
'@
  }
  
  [System.IO.File]::WriteAllText($apiPath, $apiContent, $utf8)
  Write-Host "api.js OK con registrarFaltantes" -ForegroundColor Green
} else {
  Write-Host "api.js ya tiene registrarFaltantes" -ForegroundColor Yellow
}

# === Modificar scanner.js para redirigir a faltantes.html ===
$scannerPath = "C:\planta-rapel-2026\js\scanner.js"
$scannerContent = Get-Content $scannerPath -Raw

# Reemplazar la funcion finalizar() existente
$nuevoFinalizar = @'
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
    
    if (faltan > 0) {
      const msg = 'Asistencias: ' + asistencias.length + '\n' +
                  'Esperados: ' + config.cantidadAsistente + '\n' +
                  'Faltan: ' + faltan + '\n\n' +
                  'Ir a registrar los faltantes?';
      if (!confirm(msg)) return;
      window.location.href = 'faltantes.html?faltan=' + faltan;
    } else {
      if (!confirm('Sesion completa con ' + asistencias.length + ' asistencias. Finalizar?')) return;
      const fechaHoy = new Date().toLocaleDateString('es-PE');
      const msgFinal = 'Has registrado ' + asistencias.length + ' asistencias de la ruta ' + 
                  config.ruta + ' - codigo ' + config.codigoBus + ' - fecha ' + fechaHoy;
      document.getElementById('lblMsgExito').textContent = msgFinal;
      sessionStorage.removeItem('planta_asistencias');
      sessionStorage.removeItem('planta_pendientes');
      const modal = new bootstrap.Modal(document.getElementById('modalExito'));
      modal.show();
    }
  }
'@

$scannerContent = $scannerContent -replace '(?s)\s*async function finalizar\(\) \{.*?^\s*\}', "`n$nuevoFinalizar"

[System.IO.File]::WriteAllText($scannerPath, $scannerContent, $utf8)
Write-Host "scanner.js actualizado con redireccion a faltantes" -ForegroundColor Green

git add .
git commit -m "Fase 2: Modulo Faltantes (faltantes.html + faltantes.js + api + scanner)"
git push

Write-Host ""
Write-Host "===== FASE 2 LISTA =====" -ForegroundColor Green
Write-Host "1. Verifica que ya hiciste los pasos del backend (Apps Script)" -ForegroundColor Cyan
Write-Host "2. Espera 30 seg para GitHub Pages" -ForegroundColor Cyan
Write-Host "3. Ctrl+Shift+R en navegador" -ForegroundColor Cyan
Write-Host "4. Prueba: escanea menos trabajadores que la cantidad esperada y dale Finalizar Sesion" -ForegroundColor Cyan