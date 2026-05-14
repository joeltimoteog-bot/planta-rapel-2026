function beep(freq, duration, volume) {
  try {
    const ctx = new (window.AudioContext || window.webkitAudioContext)();
    const osc = ctx.createOscillator();
    const gain = ctx.createGain();
    osc.connect(gain); gain.connect(ctx.destination);
    osc.frequency.value = freq || 880; osc.type = 'sine';
    gain.gain.value = volume || 0.2;
    osc.start();
    setTimeout(() => { osc.stop(); ctx.close(); }, duration || 120);
  } catch (e) {}
}

document.addEventListener('DOMContentLoaded', () => {
  if (!Auth.requiereLogin()) return;
  const config = BusConfig.obtener();
  if (!config) { window.location.href = 'config.html'; return; }

  let ultimoDni = null, ultimoTimestamp = 0, procesando = false;
  let dnisRegistrados = new Set();
  let asistencias = [];
  let pendientesGuardado = [];
  
  // [PERF] Cache de DNIs ya validados en esta sesion (solo memoria, se borra al cerrar)
  const cacheValidados = new Map();

  const previas = sessionStorage.getItem('planta_asistencias');
  if (previas) {
    try { asistencias = JSON.parse(previas); asistencias.forEach(a => dnisRegistrados.add(a.dni)); } catch (e) {}
  }
  const previasPendientes = sessionStorage.getItem('planta_pendientes');
  if (previasPendientes) {
    try { pendientesGuardado = JSON.parse(previasPendientes); } catch (e) {}
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
  const cardDuplicado = document.getElementById('cardDuplicado');
  const cardError = document.getElementById('cardError');
  const reader = document.getElementById('reader');
  const btnFinalizar = document.getElementById('btnFinalizar');

  actualizarContador();

  btnFinalizar.addEventListener('click', finalizar);
  document.getElementById('btnNuevaSesion').addEventListener('click', () => {
    if (asistencias.length > 0 && !confirm('Hay ' + asistencias.length + ' asistencias en curso. Cambiar de sesion?')) return;
    sessionStorage.removeItem('planta_asistencias');
    sessionStorage.removeItem('planta_pendientes');
    BusConfig.limpiar();
    window.location.href = 'config.html';
  });

  API.ping().catch(e => console.warn('Warm-up fallo:', e));
  API.validarTrabajador('00000000').catch(() => {});
  cardPreparando.style.display = 'none';
  iniciarCamara();

  // [PERF] Valida usando cache de sesion si el DNI ya fue consultado
  async function validarConCache(dni, conTimeout) {
    if (cacheValidados.has(dni)) {
      return { ok: true, trabajador: cacheValidados.get(dni), desdeCache: true };
    }
    let resp;
    if (conTimeout) {
      const timeoutPromise = new Promise(r => setTimeout(() => r({ ok: false, error: 'Timeout' }), 8000));
      resp = await Promise.race([API.validarTrabajador(dni), timeoutPromise]);
    } else {
      resp = await API.validarTrabajador(dni);
    }
    if (resp.ok && resp.trabajador) {
      cacheValidados.set(dni, resp.trabajador);
    }
    return resp;
  }

  // ===== BUSQUEDA MANUAL =====
  document.getElementById('btnBuscarManual').addEventListener('click', () => {
    document.getElementById('inputDniManual').value = '';
    document.getElementById('msgManual').textContent = '';
    document.getElementById('msgManual').className = 'mt-2 small';
    document.getElementById('resultadoManual').style.display = 'none';
    const modal = new bootstrap.Modal(document.getElementById('modalManual'));
    modal.show();
    setTimeout(() => document.getElementById('inputDniManual').focus(), 300);
  });

  document.getElementById('inputDniManual').addEventListener('keydown', (e) => {
    if (e.key === 'Enter') { e.preventDefault(); buscarDniManual(); }
  });
  document.getElementById('btnBuscarDniManual').addEventListener('click', buscarDniManual);

  async function buscarDniManual() {
    const input = document.getElementById('inputDniManual');
    const msg = document.getElementById('msgManual');
    const resultado = document.getElementById('resultadoManual');

    const dni = String(input.value).trim().padStart(8, '0');
    if (dni.length !== 8 || !/^\d{8}$/.test(dni)) {
      msg.textContent = 'DNI invalido. Ingresa 8 digitos numericos.';
      msg.className = 'mt-2 small text-danger';
      return;
    }
    if (dnisRegistrados.has(dni)) {
      msg.textContent = 'Este DNI ya fue registrado en esta sesion';
      msg.className = 'mt-2 small text-warning fw-bold';
      return;
    }

    msg.textContent = 'Buscando...';
    msg.className = 'mt-2 small text-muted';

    const resp = await validarConCache(dni, false);

    if (!resp.ok) {
      msg.textContent = 'No encontrado: ' + (resp.error || dni);
      msg.className = 'mt-2 small text-danger';
      return;
    }

    const t = resp.trabajador;
    resultado.style.display = 'block';
    resultado.innerHTML = '<div class="card border-success"><div class="card-body py-2">' +
      '<strong>' + (t.nombre || '-') + '</strong><br>' +
      '<small>DNI: ' + t.dni + ' | Ruta: ' + (t.ruta || '-') + ' | Empresa: ' + t.empresa + '</small><br>' +
      '<button class="btn btn-success btn-sm mt-2" id="btnConfirmarManual">Confirmar y registrar</button>' +
      '</div></div>';
    msg.textContent = '';

    document.getElementById('btnConfirmarManual').addEventListener('click', () => {
      const nuevaAsist = {
        dni: t.dni, nombre: t.nombre, empresa: t.empresa,
        ruta_trabajador: t.ruta, tipoRegistro: 'MANUAL'
      };
      dnisRegistrados.add(t.dni);
      asistencias.push(nuevaAsist);
      sessionStorage.setItem('planta_asistencias', JSON.stringify(asistencias));
      actualizarContador();
      beep(880, 120, 0.2);
      if (navigator.vibrate) navigator.vibrate(80);
      guardarAsistenciaIndividual(nuevaAsist);
      bootstrap.Modal.getInstance(document.getElementById('modalManual')).hide();
    });
  }

  function iniciarCamara() {
    reader.style.display = 'block';
    try {
      // [PERF 1] Solo formato QR_CODE = ~40% mas rapido (no busca 15 formatos)
      const html5QrCode = new Html5Qrcode("reader", {
        formatsToSupport: [Html5QrcodeSupportedFormats.QR_CODE]
      });
      html5QrCode.start(
        // [PERF 2] Resolucion 1280x720 fija = menos carga de CPU en celulares modestos
        {
          facingMode: { ideal: "environment" },
          width: { ideal: 1280 },
          height: { ideal: 720 },
          frameRate: { ideal: 25 }
        },
        {
          fps: 25,
          // [PERF 3] qrbox 70% del lado menor = solo analiza zona central (mas rapido)
          qrbox: function(w, h) {
            var size = Math.floor(Math.min(w, h) * 0.70);
            return { width: size, height: size };
          },
          aspectRatio: 1.0
        },
        onScanSuccess,
        function() {}
      ).catch(err => { console.error(err); alert('Error camara: ' + err); });
    } catch (e) { alert('Error: la libreria de QR no cargo. Recarga (Ctrl+F5).'); }
  }

  async function onScanSuccess(decodedText) {
    if (procesando) return;
    const dni = String(decodedText).trim().padStart(8, '0');
    const ahora = Date.now();
    if (dni === ultimoDni && (ahora - ultimoTimestamp) < 800) return;

    ultimoDni = dni; ultimoTimestamp = ahora; procesando = true;
    if (navigator.vibrate) navigator.vibrate(40); beep(660, 30, 0.1);

    cardResultado.style.display = 'none';
    cardDuplicado.style.display = 'none';
    cardError.style.display = 'none';
    
    // [PERF 4] Si esta en cache, skip "Buscando..." (sera instantaneo)
    if (!cacheValidados.has(dni)) {
      cardBuscando.style.display = 'block';
    }

    const resp = await validarConCache(dni, true);
    cardBuscando.style.display = 'none';

    if (resp.ok) {
      if (dnisRegistrados.has(resp.trabajador.dni)) {
        mostrarDuplicado(resp.trabajador);
        beep(440, 400, 0.3);
        if (navigator.vibrate) navigator.vibrate([100, 50, 100, 50, 100]);
      } else {
        const nuevaAsistencia = {
          dni: resp.trabajador.dni,
          nombre: resp.trabajador.nombre,
          empresa: resp.trabajador.empresa,
          ruta_trabajador: resp.trabajador.ruta,
          tipoRegistro: 'QR'
        };
        dnisRegistrados.add(resp.trabajador.dni);
        asistencias.push(nuevaAsistencia);
        sessionStorage.setItem('planta_asistencias', JSON.stringify(asistencias));
        mostrarTrabajador(resp.trabajador);
        actualizarContador();
        beep(880, 120, 0.2);
        guardarAsistenciaIndividual(nuevaAsistencia);
      }
    } else {
      mostrarError(resp.error || 'No encontrado');
      beep(220, 300, 0.2);
    }
    procesando = false;
  }

  async function guardarAsistenciaIndividual(asistencia) {
    actualizarIndicador('guardando');
    try {
      const resp = await API.registrarAsistencias([asistencia], config);
      if (resp.ok) { actualizarIndicador('ok'); }
      else {
        pendientesGuardado.push(asistencia);
        sessionStorage.setItem('planta_pendientes', JSON.stringify(pendientesGuardado));
        actualizarIndicador('pendiente');
      }
    } catch (e) {
      pendientesGuardado.push(asistencia);
      sessionStorage.setItem('planta_pendientes', JSON.stringify(pendientesGuardado));
      actualizarIndicador('pendiente');
    }
  }

  function actualizarIndicador(estado) {
    const ind = document.getElementById('indicadorGuardado');
    if (!ind) return;
    if (estado === 'guardando') { ind.textContent = 'Guardando en servidor...'; ind.style.color = '#6c757d'; }
    else if (estado === 'ok') { ind.textContent = 'Guardado en servidor'; ind.style.color = '#28a745'; }
    else if (estado === 'pendiente') { ind.textContent = 'Pendiente (se reintentara al finalizar)'; ind.style.color = '#dc3545'; }
  }

  function actualizarContador() {
    document.getElementById('contador').textContent = asistencias.length;
    btnFinalizar.style.display = asistencias.length > 0 ? 'block' : 'none';
    let qr = 0, manual = 0;
    for (const a of asistencias) {
      if (a.tipoRegistro === 'MANUAL') manual++; else qr++;
    }
    const elQR = document.getElementById('contadorQR');
    const elMan = document.getElementById('contadorManual');
    if (elQR) elQR.textContent = qr;
    if (elMan) elMan.textContent = manual;
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
    warning.style.display = (t.ruta && t.ruta.toUpperCase() !== config.ruta.toUpperCase()) ? 'inline' : 'none';
  }

  function mostrarDuplicado(t) {
    cardDuplicado.style.display = 'block';
    document.getElementById('lblDuplicadoNombre').textContent = t.nombre || '-';
    document.getElementById('lblDuplicadoDni').textContent = t.dni || '-';
  }

  function mostrarError(msg) {
    cardError.style.display = 'block';
    document.getElementById('lblErrorMsg').textContent = msg;
  }

  async function finalizar() {
    if (!asistencias.length) return;
    if (pendientesGuardado.length > 0) {
      if (!confirm('Hay ' + pendientesGuardado.length + ' pendientes de guardar. Reintentar?')) return;
      btnFinalizar.disabled = true;
      btnFinalizar.innerHTML = '<span class="spinner-border spinner-border-sm me-2"></span>Reintentando...';
      const resp = await API.registrarAsistencias(pendientesGuardado, config);
      if (resp.ok) {
        pendientesGuardado = [];
        sessionStorage.removeItem('planta_pendientes');
      } else {
        alert('Error al reintentar: ' + (resp.error || 'desconocido'));
        btnFinalizar.disabled = false;
        btnFinalizar.innerHTML = 'Finalizar Sesion';
        return;
      }
    }
    const faltan = config.cantidadAsistente - asistencias.length;
    if (faltan > 0) {
      const msg = 'Asistencias: ' + asistencias.length + '\n' +
                  'Esperados: ' + config.cantidadAsistente + '\n' +
                  'Faltan: ' + faltan + '\n\n' + 'Ir a registrar los faltantes?';
      if (!confirm(msg)) return;
      window.location.href = 'faltantes.html?faltan=' + faltan;
    } else {
      if (!confirm('Sesion completa con ' + asistencias.length + ' asistencias. Finalizar?')) return;
      const fechaHoy = new Date().toLocaleDateString('es-PE');
      const msgFinal = 'Has registrado ' + asistencias.length + ' asistencias de la ruta ' +
                  config.ruta + ' - codigo ' + config.codigoBus + ' - fecha ' + fechaHoy;
      document.getElementById('lblMsgExito').textContent = msgFinal;
      sessionStorage.removeItem('planta_asistencias');
      sessionStorage.removeItem('planta_pendientes');
      const modal = new bootstrap.Modal(document.getElementById('modalExito'));
      modal.show();
    }
  }
});