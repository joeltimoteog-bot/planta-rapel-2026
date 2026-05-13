cd C:\planta-rapel-2026

$utf8 = [System.Text.UTF8Encoding]::new($true)

# === auth.js: redirigir segun rol ===
$authJs = @'
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
'@
[System.IO.File]::WriteAllText("C:\planta-rapel-2026\js\auth.js", $authJs, $utf8)
Write-Host "auth.js OK" -ForegroundColor Green

# === config.html: pantalla de configuracion inicial del encargado ===
$configHtml = @'
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <meta name="theme-color" content="#c8102e">
  <title>Configuraci&oacute;n - Planta Rapel 2026</title>
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
  <link href="css/styles.css" rel="stylesheet">
</head>
<body>
  <nav class="navbar navbar-dark" style="background:#1a3a6c;">
    <div class="container-fluid">
      <span class="navbar-brand mb-0 h6 d-flex align-items-center">
        <img src="assets/logo-unifrutti.png" alt="Unifrutti" class="logo-navbar" onerror="this.style.display='none';">
        Planta Rapel 2026
      </span>
      <button class="btn btn-sm btn-outline-light" id="btnLogout">Salir</button>
    </div>
  </nav>
  
  <div class="container py-3">
    <div class="card shadow-sm">
      <div class="card-body p-3">
        <h5 class="mb-1" style="color:#1a3a6c;">Configuraci&oacute;n de Ruta</h5>
        <p class="text-muted small mb-3">Complete los datos antes de iniciar el escaneo</p>
        
        <form id="formConfig" novalidate>
          <div class="mb-3">
            <label class="form-label small fw-bold">Packing / Empresa</label>
            <select class="form-select" id="empresa" required>
              <option value="">Seleccione...</option>
              <option value="RAPEL">RAPEL</option>
              <option value="VERFRUT">VERFRUT</option>
            </select>
          </div>
          
          <div class="mb-3">
            <label class="form-label small fw-bold">Ruta</label>
            <input type="text" class="form-control" id="ruta" placeholder="Ej: CHAPAIRA" autocapitalize="characters" required>
          </div>
          
          <div class="mb-3">
            <label class="form-label small fw-bold">C&oacute;digo del Bus</label>
            <input type="text" class="form-control" id="codigoBus" placeholder="Ej: BUS-001" autocapitalize="characters" required>
          </div>
          
          <div class="mb-3">
            <label class="form-label small fw-bold">Placa del Bus</label>
            <input type="text" class="form-control" id="placa" placeholder="Ej: ABC-123" autocapitalize="characters" required>
          </div>
          
          <div class="mb-3">
            <label class="form-label small fw-bold">Cantidad de personal esperado</label>
            <input type="number" class="form-control" id="cantidad" placeholder="Ej: 50" min="1" max="200" required>
          </div>
          
          <hr class="my-3">
          
          <div class="mb-3">
            <label class="form-label small fw-bold">DNI del Encargado</label>
            <input type="text" class="form-control" id="dniEncargado" placeholder="8 d&iacute;gitos" inputmode="numeric" maxlength="8" required>
            <p class="text-muted small mt-1 mb-0">Se validar&aacute; contra la base y se registrar&aacute; como encargado de esta ruta</p>
          </div>
          
          <div id="msgError" class="alert alert-danger d-none py-2 small" role="alert"></div>
          
          <div id="cardEncargado" class="alert alert-success d-none py-2" role="alert">
            <p class="mb-1 small"><strong>Encargado identificado:</strong></p>
            <p class="mb-0" id="lblNombreEncargado">-</p>
          </div>
          
          <button type="submit" class="btn btn-primary btn-lg w-100 mt-2" id="btnIniciar">Iniciar Escaneo</button>
        </form>
      </div>
    </div>
  </div>
  
  <script src="js/config.js"></script>
  <script src="js/api.js"></script>
  <script src="js/auth.js"></script>
  <script src="js/config-inicial.js"></script>
</body>
</html>
'@
[System.IO.File]::WriteAllText("C:\planta-rapel-2026\config.html", $configHtml, $utf8)
Write-Host "config.html OK" -ForegroundColor Green

# === config-inicial.js: logica de la pantalla de configuracion ===
$configInicialJs = @'
document.addEventListener('DOMContentLoaded', () => {
  if (!Auth.requiereLogin()) return;
  
  const form = document.getElementById('formConfig');
  const btn = document.getElementById('btnIniciar');
  const msgError = document.getElementById('msgError');
  const cardEncargado = document.getElementById('cardEncargado');
  const lblNombreEncargado = document.getElementById('lblNombreEncargado');
  const inputDni = document.getElementById('dniEncargado');
  
  let encargadoValidado = null;
  
  document.getElementById('btnLogout').addEventListener('click', () => {
    if (confirm('Salir de la sesion?')) Auth.cerrarSesion();
  });
  
  // Validar DNI del encargado al perder foco
  inputDni.addEventListener('blur', async () => {
    const dni = inputDni.value.trim();
    if (dni.length < 8) {
      encargadoValidado = null;
      cardEncargado.classList.add('d-none');
      return;
    }
    await validarDniEncargado(dni);
  });
  
  async function validarDniEncargado(dni) {
    const dniNorm = String(dni).trim().padStart(8, '0');
    msgError.classList.add('d-none');
    cardEncargado.classList.add('d-none');
    
    // Buscar en AMBAS bases (sin especificar empresa)
    const resp = await API.validarTrabajador(dniNorm);
    
    if (!resp.ok) {
      mostrarError('DNI no encontrado en ninguna base. Verifique el numero.');
      encargadoValidado = null;
      return false;
    }
    
    encargadoValidado = resp.trabajador;
    lblNombreEncargado.textContent = resp.trabajador.nombre + ' (' + resp.trabajador.empresa + ')';
    cardEncargado.classList.remove('d-none');
    return true;
  }
  
  form.addEventListener('submit', async (e) => {
    e.preventDefault();
    msgError.classList.add('d-none');
    
    const empresa = document.getElementById('empresa').value;
    const ruta = document.getElementById('ruta').value.trim().toUpperCase();
    const codigoBus = document.getElementById('codigoBus').value.trim().toUpperCase();
    const placa = document.getElementById('placa').value.trim().toUpperCase();
    const cantidad = parseInt(document.getElementById('cantidad').value);
    const dni = inputDni.value.trim();
    
    if (!empresa || !ruta || !codigoBus || !placa || !cantidad || !dni) {
      mostrarError('Complete todos los campos');
      return;
    }
    
    btn.disabled = true;
    btn.innerHTML = '<span class="spinner-border spinner-border-sm me-2"></span>Validando...';
    
    // Re-validar DNI si no estaba validado
    if (!encargadoValidado) {
      const ok = await validarDniEncargado(dni);
      if (!ok) {
        btn.disabled = false;
        btn.innerHTML = 'Iniciar Escaneo';
        return;
      }
    }
    
    // Guardar config en sessionStorage
    BusConfig.guardar({
      empresa: empresa,
      ruta: ruta,
      codigoBus: codigoBus,
      placa: placa,
      cantidadEsperada: cantidad,
      encargadoDni: encargadoValidado.dni,
      encargadoNombre: encargadoValidado.nombre,
      encargadoEmpresa: encargadoValidado.empresa,
      iniciadoAt: new Date().toISOString()
    });
    
    window.location.href = 'scanner.html';
  });
  
  function mostrarError(msg) {
    msgError.textContent = msg;
    msgError.classList.remove('d-none');
  }
});
'@
[System.IO.File]::WriteAllText("C:\planta-rapel-2026\js\config-inicial.js", $configInicialJs, $utf8)
Write-Host "config-inicial.js OK" -ForegroundColor Green

# === scanner.html con info de la ruta + scan en ambas bases ===
$scannerHtml = @'
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <meta name="theme-color" content="#c8102e">
  <title>Scanner QR - Planta Rapel 2026</title>
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
  <link href="css/styles.css" rel="stylesheet">
  <script src="https://unpkg.com/html5-qrcode@2.3.8/html5-qrcode.min.js"></script>
</head>
<body>
  <nav class="navbar navbar-dark" style="background:#1a3a6c;">
    <div class="container-fluid">
      <span class="navbar-brand mb-0 h6 d-flex align-items-center">
        <img src="assets/logo-unifrutti.png" alt="Unifrutti" class="logo-navbar" onerror="this.style.display='none';">
        Scanner QR
      </span>
      <a href="config.html" class="btn btn-sm btn-outline-light">Cambiar config</a>
    </div>
  </nav>
  
  <div class="container py-3">
    <!-- Tarjeta con info de la ruta -->
    <div class="card mb-3 shadow-sm" style="background:#f8f9fa;">
      <div class="card-body py-2">
        <div class="row g-2 small">
          <div class="col-6"><strong>Ruta:</strong> <span id="lblRuta">-</span></div>
          <div class="col-6"><strong>Bus:</strong> <span id="lblBus">-</span></div>
          <div class="col-6"><strong>Placa:</strong> <span id="lblPlaca">-</span></div>
          <div class="col-6"><strong>Packing:</strong> <span class="badge" id="lblPacking" style="background:#c8102e;">-</span></div>
        </div>
        <hr class="my-2">
        <p class="mb-0 small text-muted"><strong>Encargado:</strong> <span id="lblEncargado">-</span></p>
        <p class="mb-0 small"><strong>Progreso:</strong> <span id="lblProgreso">0 / 0</span></p>
      </div>
    </div>
    
    <div id="cardPreparando" class="card mb-3 shadow-sm">
      <div class="card-body text-center py-3">
        <div class="spinner-border spinner-border-sm text-primary me-2" role="status"></div>
        <span>Preparando scanner...</span>
      </div>
    </div>
    
    <div id="reader" style="width: 100%; display:none;"></div>
    
    <div class="card mt-3 shadow-sm" id="cardBuscando" style="display:none;">
      <div class="card-body py-2 text-center">
        <div class="spinner-border spinner-border-sm text-primary me-2" role="status"></div>
        <span class="small">Buscando trabajador...</span>
      </div>
    </div>
    
    <div class="card mt-3 shadow-sm" id="cardResultado" style="display:none;">
      <div class="card-body py-3">
        <div class="d-flex justify-content-between align-items-start mb-2">
          <h5 class="mb-0" id="lblNombre" style="color:#1a3a6c;">-</h5>
          <span class="badge" id="lblEmpresaTrab" style="background:#c8102e;">-</span>
        </div>
        <p class="mb-1 small"><strong>DNI:</strong> <span id="lblDni">-</span></p>
        <p class="mb-1 small"><strong>Oficio:</strong> <span id="lblOficio">-</span></p>
        <p class="mb-1 small"><strong>R&eacute;gimen:</strong> <span id="lblRegimen">-</span></p>
        <p class="mb-1 small"><strong>Ruta asignada:</strong> <span class="badge bg-primary" id="lblRutaTrab">-</span> <span class="badge bg-danger ms-1" id="lblWarningRuta" style="display:none;">!=</span></p>
        <p class="mb-1 small"><strong>Sector:</strong> <span id="lblZona">-</span></p>
        <p class="mb-0 small text-muted"><strong>Contrato:</strong> <span id="lblFechas">-</span></p>
      </div>
    </div>
    
    <div class="card mt-3 shadow-sm border-danger" id="cardError" style="display:none;">
      <div class="card-body py-3">
        <h5 class="mb-2 text-danger">No encontrado</h5>
        <p class="mb-0 small" id="lblErrorMsg">-</p>
      </div>
    </div>
  </div>
  
  <script src="js/config.js"></script>
  <script src="js/api.js"></script>
  <script src="js/auth.js"></script>
  <script src="js/scanner.js"></script>
</body>
</html>
'@
[System.IO.File]::WriteAllText("C:\planta-rapel-2026\scanner.html", $scannerHtml, $utf8)
Write-Host "scanner.html OK" -ForegroundColor Green

# === scanner.js: usa BusConfig + busca en ambas bases ===
$scannerJs = @'
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
'@
[System.IO.File]::WriteAllText("C:\planta-rapel-2026\js\scanner.js", $scannerJs, $utf8)
Write-Host "scanner.js OK" -ForegroundColor Green

# === home.html: agregar boton "Modo Encargado" (solo admin) ===
$homeHtml = @'
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta name="theme-color" content="#c8102e">
  <title>Planta Rapel 2026</title>
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
  <link href="css/styles.css" rel="stylesheet">
</head>
<body>
  <nav class="navbar navbar-dark" style="background:#1a3a6c;">
    <div class="container-fluid">
      <span class="navbar-brand mb-0 h6 d-flex align-items-center">
        <img src="assets/logo-unifrutti.png" alt="Unifrutti" class="logo-navbar" onerror="this.style.display='none';">
        Planta Rapel 2026
      </span>
      <button class="btn btn-sm btn-outline-light" id="btnLogout">Cerrar sesi&oacute;n</button>
    </div>
  </nav>
  <div class="container py-4">
    <div class="card shadow-sm mb-3">
      <div class="card-body text-center py-4">
        <h4 class="mb-2" style="color:#1a3a6c;">Bienvenido</h4>
        <p class="lead mb-1" id="lblNombre">-</p>
        <p class="text-muted mb-3" id="lblCargo">-</p>
        <p class="mb-0">
          <span class="badge bg-secondary me-2" id="lblRol">-</span>
          <span class="badge" id="lblEmpresa" style="background:#c8102e;">-</span>
        </p>
      </div>
    </div>
    <div class="card shadow-sm">
      <div class="card-body">
        <h6 class="mb-3" style="color:#1a3a6c;">Acciones</h6>
        <a href="config.html" class="btn btn-primary w-100 mb-2">Modo Encargado (Configurar ruta + Scanner)</a>
      </div>
    </div>
  </div>
  <script src="js/config.js"></script>
  <script src="js/api.js"></script>
  <script src="js/auth.js"></script>
  <script src="js/home.js"></script>
</body>
</html>
'@
[System.IO.File]::WriteAllText("C:\planta-rapel-2026\home.html", $homeHtml, $utf8)
Write-Host "home.html OK" -ForegroundColor Green

git add .
git commit -m "Nuevo flujo: usuario generico encargado + config inicial + scan en ambas bases"
git push

Write-Host ""
Write-Host "===== LISTO =====" -ForegroundColor Green
Write-Host "1. Verifica que ejecutaste crearUsuarioEncargado en Apps Script" -ForegroundColor Cyan
Write-Host "2. Verifica que redesplegaste con la nueva version" -ForegroundColor Cyan
Write-Host "3. Cierra sesion + Ctrl+F5" -ForegroundColor Cyan
Write-Host "4. Loguea con: encargado / Encargado2026" -ForegroundColor Cyan