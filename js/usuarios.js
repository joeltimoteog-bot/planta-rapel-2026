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
  document.getElementById('btnPinsMasivos').addEventListener('click', abrirModalPinsMasivos);
  document.getElementById('btnAsignarPins').addEventListener('click', asignarPinsMasivos);

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
      '<td>' + btn + ' <button class="btn btn-sm btn-outline-warning ms-1" onclick="asignarPin(' + u.id + ', \'' + escapeHtml(u.username) + '\')">PIN</button></td>' +
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

// ===== ASIGNACION MASIVA DE PINs =====
function abrirModalPinsMasivos() {
  const msg = document.getElementById('msgPinsMasivos');
  msg.textContent = '';
  msg.className = 'small';
  document.getElementById('resultadoPinsMasivos').style.display = 'none';
  document.getElementById('tblPinsAsignados').innerHTML = '';
  document.getElementById('iPinInicial').value = '1001';
  const modal = new bootstrap.Modal(document.getElementById('modalPinsMasivos'));
  modal.show();
}

async function asignarPinsMasivos() {
  const msg = document.getElementById('msgPinsMasivos');
  const cont = document.getElementById('resultadoPinsMasivos');
  const tbody = document.getElementById('tblPinsAsignados');
  const pinInicial = parseInt(document.getElementById('iPinInicial').value, 10);

  if (isNaN(pinInicial) || pinInicial < 1000 || pinInicial > 9999) {
    msg.textContent = 'PIN inicial invalido. Debe ser un numero de 4 digitos (1000-9999).';
    msg.className = 'small text-danger';
    return;
  }

  if (!confirm('Asignar PINs secuenciales desde ' + pinInicial + ' a todos los encargados sin PIN?')) return;

  const btn = document.getElementById('btnAsignarPins');
  btn.disabled = true;
  btn.textContent = 'Asignando...';
  msg.textContent = 'Procesando...';
  msg.className = 'small text-muted';

  const resp = await API.asignarPinsMasivos(pinInicial);

  btn.disabled = false;
  btn.textContent = 'Asignar';

  if (!resp.ok) {
    msg.textContent = 'Error: ' + (resp.error || 'desconocido');
    msg.className = 'small text-danger';
    return;
  }

  const asignados = resp.asignados || [];
  if (asignados.length === 0) {
    msg.textContent = 'No habia encargados sin PIN. Nada que asignar.';
    msg.className = 'small text-warning fw-bold';
    cont.style.display = 'none';
    return;
  }

  msg.textContent = 'Se asignaron ' + asignados.length + ' PINs correctamente.';
  msg.className = 'small text-success fw-bold';
  tbody.innerHTML = asignados.map(a =>
    '<tr><td>' + escapeHtml(a.dni) + '</td><td>' + escapeHtml(a.nombre) +
    '</td><td><strong>' + escapeHtml(a.pin) + '</strong></td></tr>'
  ).join('');
  cont.style.display = 'block';
  cargarUsuarios();
}