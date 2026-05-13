document.addEventListener('DOMContentLoaded', () => {
  if (!Auth.requiereLogin()) return;
  
  let contador = 0;
  let ultimoDni = null;
  let ultimoTimestamp = 0;
  
  const lblUltimoDni = document.getElementById('lblUltimoDni');
  const lblMensaje = document.getElementById('lblMensaje');
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
    alert('No se pudo iniciar la camara. Verifica que diste permisos al navegador.');
  });
  
  function onScanSuccess(decodedText) {
    const dni = String(decodedText).trim().padStart(8, '0');
    const ahora = Date.now();
    
    // Debounce: ignorar mismo DNI en menos de 2 segundos
    if (dni === ultimoDni && (ahora - ultimoTimestamp) < 2000) return;
    
    ultimoDni = dni;
    ultimoTimestamp = ahora;
    contador++;
    
    lblUltimoDni.textContent = dni;
    lblMensaje.textContent = 'DNI capturado correctamente';
    lblContador.textContent = contador;
    
    if (navigator.vibrate) navigator.vibrate(100);
    
    setTimeout(() => { lblMensaje.textContent = ''; }, 2000);
  }
  
  function onScanError(err) {
    // Ignorar errores de "QR no detectado" (es normal entre frames)
  }
});