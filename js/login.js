document.addEventListener('DOMContentLoaded', () => {
  const sesion = Auth.obtenerSesion();
  if (sesion) {
    Auth.redireccionarSegunRol(sesion);
    return;
  }
  const form = document.getElementById('formLogin');
  const btn = document.getElementById('btnLogin');
  const msgError = document.getElementById('msgError');
  const inputUsername = document.getElementById('username');
  setTimeout(() => inputUsername.focus(), 100);
  form.addEventListener('submit', async (e) => {
    e.preventDefault();
    const username = inputUsername.value.trim();
    const password = document.getElementById('password').value;
    if (!username || !password) {
      mostrarError('Ingrese usuario y contrasena');
      return;
    }
    btn.disabled = true;
    btn.innerHTML = '<span class="spinner-border spinner-border-sm me-2"></span>Validando...';
    msgError.classList.add('d-none');
    const resp = await API.login(username, password);
    if (!resp.ok) {
      mostrarError(resp.error || 'Error al iniciar sesion');
      btn.disabled = false;
      btn.innerHTML = 'Ingresar';
      return;
    }
    Auth.guardarSesion(resp.usuario);
    Auth.redireccionarSegunRol(resp.usuario);
  });
  function mostrarError(msg) {
    msgError.textContent = msg;
    msgError.classList.remove('d-none');
  }
});
