document.addEventListener('DOMContentLoaded', () => {
  if (!Auth.requiereLogin()) return;
  
  const usuario = Auth.obtenerSesion();
  const empresa = usuario.empresa || 'RAPEL';
  
  let contador = 0;
  let ultimoDni = null;
  let ultimoTimestamp = 0;
  let procesando = false;
  
  const cardResultado = document.getElementById('cardResultado');
  const cardError = document.getElementById('cardError');
  const lblContador = document.getElementById('contador');
  
  const html5QrCode = new Html5Qrcode("reader");
  const config = { 
    fps: 10, 
    qrbox: { width: 250, height: 250 },
    aspectRatio: 1.0
  };
  
  html5QrCode.start(
    { facingMode: "environment" },
    config,
    onScanSuccess,
    onScanError
  ).catch(err => {
    console.error('Error camara:', err);
    alert('No se pudo iniciar la camara. Verifica que diste permisos.');
  });
  
  async function onScanSuccess(decodedText) {
    if (procesando) return;
    
    const dni = String(decodedText).trim().padStart(8, '0');
    const ahora = Date.now();
    
    // Debounce: ignorar mismo DNI en menos de 3 segundos
    if (dni === ultimoDni && (ahora - ultimoTimestamp) < 3000) return;
    
    ultimoDni = dni;
    ultimoTimestamp = ahora;
    procesando = true;
    
    if (navigator.vibrate) navigator.vibrate(100);
    
    // Llamar al backend
    const resp = await API.validarTrabajador(dni, empresa);
    
    if (resp.ok) {
      mostrarTrabajador(resp.trabajador);
      contador++;
      lblContador.textContent = contador;
    } else {
      mostrarError(resp.error || 'No encontrado');
    }
    
    procesando = false;
  }
  
  function mostrarTrabajador(t) {
    cardError.style.display = 'none';
    cardResultado.style.display = 'block';
    document.getElementById('lblNombre').textContent = t.nombre || '-';
    document.getElementById('lblDni').textContent = t.dni || '-';
    document.getElementById('lblCodigo').textContent = t.codigo || '-';
    document.getElementById('lblOficio').textContent = t.oficio || '-';
    document.getElementById('lblRegimen').textContent = t.regimen || '-';
    document.getElementById('lblRuta').textContent = t.ruta || 'SIN RUTA';
    document.getElementById('lblZona').textContent = t.zona || '-';
    document.getElementById('lblEmpresaTrab').textContent = t.empresa || '-';
    document.getElementById('lblFechas').textContent = 
      (t.fechaInicio || '?') + ' - ' + (t.fechaTermino || '?');
  }
  
  function mostrarError(msg) {
    cardResultado.style.display = 'none';
    cardError.style.display = 'block';
    document.getElementById('lblErrorMsg').textContent = msg;
  }
  
  function onScanError(err) { /* ignorar */ }
});