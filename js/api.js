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