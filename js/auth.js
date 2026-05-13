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
    window.location.href = 'home.html';
  }
};
