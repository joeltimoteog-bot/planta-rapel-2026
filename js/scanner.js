document.addEventListener('DOMContentLoaded', async () => {
  if (!Auth.requiereLogin()) return;
  
  // Limpiar cache previo de la base (legacy)
  ['RAPEL', 'VERFRUT'].forEach(emp => {
    localStorage.removeItem('planta_base_' + emp);
    localStorage.removeItem('planta_base_ts_' + emp);
  });
  
  // Obtener config de bus de la sesion
  const config = BusConfig.obtener();
  if (!config) {
    // Si no hay config, mandar a configurar
    window.location.href = 'config.html';
    return;
  }
  
  let contador = 0;
  let ultimoDni = null;
  let ultimoTimestamp = 0;
  let procesando = false;
  
  // Mostrar info de la ruta arriba
  document.getElementById('lblRuta').textContent = config.ruta;
  document.getElementById('lblBus').textContent = config.codigoBus;
  document.getElementById('lblPlaca').textContent = config.placa;
  document.getElementById('lblPacking').textContent = config.empresa;
  document.getElementById('lblEncargado').textContent = config.encargadoNombre;
  document.getElementById('lblProgreso').textContent = '0 / ' + config.cantidadEsperada;
  
  const cardPreparando = document.getElementById('cardPreparando');
  const cardBuscando = document.getElementById('cardBuscando');
  const cardResultado = document.getElementById('cardResultado');
  const cardError = document.getElementById('cardError');
  const reader = document.getElementById('reader');
  
  // Warm-up
  await API.ping();
  
  cardPreparando.style.display = 'none';
  iniciarCamara();
  
  function iniciarCamara() {
    reader.style.display = 'block';
    const html5QrCode = new Html5Qrcode("reader");
    const cfgQr = { 
      fps: 10, 
      qrbox: { width: 250, height: 250 },
      aspectRatio: 1.0
    };
    html5QrCode.start(
      { facingMode: "environment" },
      cfgQr,
      onScanSuccess,
      function() {}
    ).catch(err => {
      console.error('Error camara:', err);
      alert('No se pudo iniciar la camara. Verifica permisos.');
    });
  }
  
  async function onScanSuccess(decodedText) {
    if (procesando) return;
    
    const dni = String(decodedText).trim().padStart(8, '0');
    const ahora = Date.now();
    
    if (dni === ultimoDni && (ahora - ultimoTimestamp) < 3000) return;
    
    ultimoDni = dni;
    ultimoTimestamp = ahora;
    procesando = true;
    
    if (navigator.vibrate) navigator.vibrate(100);
    
    cardResultado.style.display = 'none';
    cardError.style.display = 'none';
    cardBuscando.style.display = 'block';
    
    // BUSCA EN AMBAS BASES (no envia empresa)
    const resp = await API.validarTrabajador(dni);
    
    cardBuscando.style.display = 'none';
    
    if (resp.ok) {
      mostrarTrabajador(resp.trabajador);
      contador++;
      document.getElementById('lblProgreso').textContent = contador + ' / ' + config.cantidadEsperada;
    } else {
      mostrarError(resp.error || 'No encontrado');
    }
    
    procesando = false;
  }
  
  function mostrarTrabajador(t) {
    cardResultado.style.display = 'block';
    document.getElementById('lblNombre').textContent = t.nombre || '-';
    document.getElementById('lblDni').textContent = t.dni || '-';
    document.getElementById('lblOficio').textContent = t.oficio || '-';
    document.getElementById('lblRegimen').textContent = t.regimen || '-';
    document.getElementById('lblRutaTrab').textContent = t.ruta || 'SIN RUTA';
    document.getElementById('lblZona').textContent = t.zona || '-';
    document.getElementById('lblEmpresaTrab').textContent = t.empresa || '-';
    document.getElementById('lblFechas').textContent = 
      (t.fechaInicio || '?') + ' - ' + (t.fechaTermino || '?');
    
    // Validacion suave: avisar si la ruta no coincide
    const warning = document.getElementById('lblWarningRuta');
    if (t.ruta && t.ruta.toUpperCase() !== config.ruta.toUpperCase()) {
      warning.textContent = 'No es de ' + config.ruta;
      warning.style.display = 'inline';
    } else {
      warning.style.display = 'none';
    }
  }
  
  function mostrarError(msg) {
    cardError.style.display = 'block';
    document.getElementById('lblErrorMsg').textContent = msg;
  }
});