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