document.addEventListener('DOMContentLoaded', () => {
  if (!Auth.requiereLogin()) return;
  const usuario = Auth.obtenerSesion();
  document.getElementById('lblNombre').textContent = usuario.nombre_completo || usuario.username;
  document.getElementById('lblCargo').textContent = usuario.cargo || '';
  document.getElementById('lblRol').textContent = (usuario.rol || '-').toUpperCase();
  document.getElementById('lblEmpresa').textContent = usuario.empresa || '-';
  document.getElementById('btnLogout').addEventListener('click', () => {
    if (confirm('Cerrar sesion?')) {
      Auth.cerrarSesion();
    }
  });
});