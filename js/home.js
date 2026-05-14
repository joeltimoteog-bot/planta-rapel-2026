document.addEventListener('DOMContentLoaded', () => {
  if (!Auth.requiereLogin()) return;
  const usuario = Auth.obtenerSesion();
  document.getElementById('lblNombre').textContent = usuario.nombre_completo || usuario.username;
  document.getElementById('lblCargo').textContent = usuario.cargo || '';
  document.getElementById('lblRol').textContent = (usuario.rol || '-').toUpperCase();
  document.getElementById('lblEmpresa').textContent = usuario.empresa || '-';

  // Restringir panel admin: solo rol 'admin' ve Dashboard y Gestion de Usuarios.
  // Defensivo: si no hay usuario o el rol no es exactamente 'admin', se oculta.
  const esAdmin = !!usuario && usuario.rol === 'admin';
  if (!esAdmin) {
    const adminPanel = document.getElementById('adminPanel');
    if (adminPanel) adminPanel.style.display = 'none';
    const btnDashboard = document.getElementById('btnDashboard');
    if (btnDashboard) btnDashboard.style.display = 'none';
    const btnUsuarios = document.getElementById('btnUsuarios');
    if (btnUsuarios) btnUsuarios.style.display = 'none';
  }

  document.getElementById('btnLogout').addEventListener('click', () => {
    if (confirm('Cerrar sesion?')) {
      Auth.cerrarSesion();
    }
  });
});