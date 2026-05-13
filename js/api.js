const API = {
  async call(accion, params = {}) {
    if (!CONFIG.API_URL || CONFIG.API_URL.startsWith('PEGAR')) {
      return { ok: false, error: 'API_URL no configurada en config.js' };
    }
    try {
      const response = await fetch(CONFIG.API_URL, {
        method: 'POST',
        mode: 'cors',
        headers: { 'Content-Type': 'text/plain;charset=utf-8' },
        body: JSON.stringify({ accion, ...params })
      });
      return await response.json();
    } catch (err) {
      console.error('API error:', err);
      return { ok: false, error: 'Error de conexion: ' + err.message };
    }
  },
  login(username, password) { return this.call('login', { username, password }); },
  validarTrabajador(dni, empresa) { return this.call('validarTrabajador', { dni, empresa }); },
  registrarAsistencias(asistencias, sesion) { return this.call('registrarAsistencias', { asistencias, sesion }); },
  ping() { return this.call('ping'); }
};