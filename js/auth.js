const Auth = {
  KEY: 'planta_session',
  guardarSesion(usuario) {
    localStorage.setItem(this.KEY, JSON.stringify({
      ...usuario,
      _loggedAt: new Date().toISOString()
    }));
  },
  obtenerSesion() {
    const data = localStorage.getItem(this.KEY);
    return data ? JSON.parse(data) : null;
  },
  cerrarSesion() {
    localStorage.removeItem(this.KEY);
    sessionStorage.removeItem('planta_bus_config');
    window.location.href = 'index.html';
  },
  requiereLogin() {
    if (!this.obtenerSesion()) {
      window.location.href = 'index.html';
      return false;
    }
    return true;
  },
  redireccionarSegunRol(usuario) {
    // Encargado de bus -> pantalla de config inicial
    if (usuario.rol === 'encargado_bus') {
      window.location.href = 'config.html';
    } else {
      // Admin u otros -> home
      window.location.href = 'home.html';
    }
  }
};

// Helper: obtener configuracion de bus de la sesion (solo encargados)
const BusConfig = {
  KEY: 'planta_bus_config',
  guardar(config) {
    sessionStorage.setItem(this.KEY, JSON.stringify(config));
  },
  obtener() {
    const data = sessionStorage.getItem(this.KEY);
    return data ? JSON.parse(data) : null;
  },
  limpiar() {
    sessionStorage.removeItem(this.KEY);
  }
};