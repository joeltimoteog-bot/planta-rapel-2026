function beep(freq, duration, volume) {
  try {
    const ctx = new (window.AudioContext || window.webkitAudioContext)();
    const osc = ctx.createOscillator();
    const gain = ctx.createGain();
    osc.connect(gain);
    gain.connect(ctx.destination);
    osc.frequency.value = freq || 880;
    osc.type = 'sine';
    gain.gain.value = volume || 0.2;
    osc.start();
    setTimeout(() => { osc.stop(); ctx.close(); }, duration || 120);
  } catch (e) {}
}

document.addEventListener('DOMContentLoaded', () => {
  if (!Auth.requiereLogin()) return;
  
  const config = BusConfig.obtener();
  if (!config) {
    window.location.href = 'config.html';
    return;
  }
  
  let ultimoDni = null;
  let ultimoTimestamp = 0;
  let procesando = false;
  let dnisRegistrados = new Set();
  let asistencias = [];
  
  const previas = sessionStorage.getItem('planta_asistencias');
  if (previas) {
    try {
      asistencias = JSON.parse(previas);
      asistencias.forEach(a => dnisRegistrados.add(a.dni));
    } catch (e) {}
  }
  
  document.getElementById('lblRuta').textContent = config.ruta;
  document.getElementById('lblBus').textContent = config.codigoBus;
  document.getElementById('lblPlaca').textContent = config.placa;
  document.getElementById('lblTurno').textContent = config.turno;
  document.getElementById('lblZonaPacking').textContent = config.zonaPacking;
  document.getElementById('lblEncargado').textContent = config.encargadoNombre;
  document.getElementById('cantidadEsperada').textContent = config.cantidadAsistente;
  
  const cardPreparando = document.getElementById('cardPreparando');
  const cardBuscando = document.getElementById('cardBuscando');
  const cardResultado = document.getElementById('cardResultado');
  const cardError = document.getElementById('cardError');
  const reader = document.getElementById('reader');
  const btnFinalizar = document.getElementById('btnFinalizar');
  actualizarContador();
  
  btnFinalizar.addEventListener('click', finalizar);
  document.getElementById('btnNuevaSesion').addEventListener('click', () => {
    sessionStorage.removeItem('planta_asistencias');
    BusConfig.limpiar();
    window.location.href = 'config.html';
  });
  
  API.ping().catch(e => console.warn('Warm-up fallo:', e));
  cardPreparando.style.display = 'none';
  iniciarCamara();
  
  function iniciarCamara() {
    reader.style.display = 'block';
    try {
      const html5QrCode = new Html5Qrcode("reader");
      const cfgQr = { fps: 10, qrbox: { width: 250, height: 250 }, aspectRatio: 1.0 };
      html5QrCode.start(
        { facingMode: "environment" },
        cfgQr,
        onScanSuccess,
        function() {}
      ).catch(err => {
        console.error('Error camara:', err);
        alert('Error al iniciar la camara: ' + err);
      });
    } catch (e) {
      console.error('Error html5-qrcode:', e);
      alert('Error: la libreria de QR no cargo. Recarga (Ctrl+F5).');
    }
  }
  
  async function onScanSuccess(decodedText) {
    if (procesando) return;
    const dni = String(decodedText).trim().padStart(8, '0');
    const ahora = Date.now();
    if (dni === ultimoDni && (ahora - ultimoTimestamp) < 3000) return;
    
    ultimoDni = dni;
    ultimoTimestamp = ahora;
    procesando = true;
    
    if (navigator.vibrate) navigator.vibrate(80);
    
    cardResultado.style.display = 'none';
    cardError.style.display = 'none';
    cardBuscando.style.display = 'block';
    
    const timeoutPromise = new Promise(resolve => 
      setTimeout(() => resolve({ ok: false, error: 'Timeout: backend tardo demasiado' }), 8000)
    );
    
    const resp = await Promise.race([
      API.validarTrabajador(dni),
      timeoutPromise
    ]);
    
    cardBuscando.style.display = 'none';
    
    if (resp.ok) {
      if (dnisRegistrados.has(resp.trabajador.dni)) {
        mostrarError('Este trabajador ya fue escaneado en esta sesion');
        beep(440, 200, 0.15);
      } else {
        dnisRegistrados.add(resp.trabajador.dni);
        asistencias.push({
          dni: resp.trabajador.dni,
          nombre: resp.trabajador.nombre,
          empresa: resp.trabajador.empresa,
          ruta_trabajador: resp.trabajador.ruta,
          tipoRegistro: 'QR'
        });
        sessionStorage.setItem('planta_asistencias', JSON.stringify(asistencias));
        mostrarTrabajador(resp.trabajador);
        actualizarContador();
        beep(880, 120, 0.2);
      }
    } else {
      mostrarError(resp.error || 'No encontrado');
      beep(220, 300, 0.2);
    }
    procesando = false;
  }
  
  function actualizarContador() {
    document.getElementById('contador').textContent = asistencias.length;
    btnFinalizar.style.display = asistencias.length > 0 ? 'block' : 'none';
  }
  
  function mostrarTrabajador(t) {
    cardResultado.style.display = 'block';
    document.getElementById('lblNombre').textContent = t.nombre || '-';
    document.getElementById('lblDni').textContent = t.dni || '-';
    document.getElementById('lblOficio').textContent = t.oficio || '-';
    document.getElementById('lblRutaTrab').textContent = t.ruta || 'SIN RUTA';
    document.getElementById('lblZona').textContent = t.zona || '-';
    document.getElementById('lblEmpresaTrab').textContent = t.empresa || '-';
    const warning = document.getElementById('lblWarningRuta');
    if (t.ruta && t.ruta.toUpperCase() !== config.ruta.toUpperCase()) {
      warning.style.display = 'inline';
    } else {
      warning.style.display = 'none';
    }
  }
  
  function mostrarError(msg) {
    cardError.style.display = 'block';
    document.getElementById('lblErrorMsg').textContent = msg;
  }
  
  async function finalizar() {
    if (!asistencias.length) return;
    if (!confirm('Guardar ' + asistencias.length + ' asistencias?')) return;
    btnFinalizar.disabled = true;
    btnFinalizar.innerHTML = '<span class="spinner-border spinner-border-sm me-2"></span>Guardando...';
    const resp = await API.registrarAsistencias(asistencias, config);
    if (!resp.ok) {
      alert('Error al guardar: ' + (resp.error || 'desconocido'));
      btnFinalizar.disabled = false;
      btnFinalizar.innerHTML = 'Finalizar y Guardar Asistencias';
      return;
    }
    sessionStorage.removeItem('planta_asistencias');
    const msg = 'Has registrado ' + resp.cantidad + ' asistencias de la ruta ' + 
                resp.ruta + ' - codigo ' + resp.codigoBus + ' - fecha ' + resp.fecha;
    document.getElementById('lblMsgExito').textContent = msg;
    const modal = new bootstrap.Modal(document.getElementById('modalExito'));
    modal.show();
  }
});
