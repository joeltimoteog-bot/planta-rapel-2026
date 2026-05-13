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