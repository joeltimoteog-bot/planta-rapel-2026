cd C:\planta-rapel-2026

$utf8 = [System.Text.UTF8Encoding]::new($true)

# === Crear carpeta assets si no existe ===
if (-not (Test-Path 'assets')) {
    New-Item -ItemType Directory -Path 'assets' | Out-Null
}

# === css/styles.css con Tahoma 10pt + estilos del logo ===
$stylesCss = @'
:root {
  --unifrutti-red: #c8102e;
  --unifrutti-blue: #1a3a6c;
  --unifrutti-light: #f5f5f5;
}
* {
  font-family: 'Tahoma', Geneva, Verdana, sans-serif;
}
body {
  font-size: 10pt;
}
body.bg-login {
  background: linear-gradient(135deg, #e8eef7 0%, #f5f5f5 100%);
  min-height: 100vh;
}
.login-card {
  max-width: 380px;
  width: 100%;
  border: none;
  border-radius: 18px;
  overflow: hidden;
}
.login-card .card-header {
  background: linear-gradient(135deg, #c8102e 0%, #a00d24 100%);
  border-bottom: none;
}
.logo-header {
  max-height: 50px;
  width: auto;
}
.logo-navbar {
  max-height: 28px;
  width: auto;
  margin-right: 8px;
}
.btn-primary {
  background-color: var(--unifrutti-blue);
  border-color: var(--unifrutti-blue);
  padding: 12px;
  font-weight: 600;
}
.btn-primary:hover, .btn-primary:focus, .btn-primary:active {
  background-color: #142a52 !important;
  border-color: #142a52 !important;
}
.input-rojo {
  border: 2px solid var(--unifrutti-red);
  border-radius: 8px;
  padding: 12px 16px;
}
.input-rojo:focus {
  border-color: var(--unifrutti-red);
  box-shadow: 0 0 0 0.2rem rgba(200, 16, 46, 0.15);
}
.text-danger { color: var(--unifrutti-red) !important; }
.card-footer { background: var(--unifrutti-light); }

/* Scanner */
#reader {
  border-radius: 12px;
  overflow: hidden;
}
#reader video {
  border-radius: 12px;
}
'@
[System.IO.File]::WriteAllText("C:\planta-rapel-2026\css\styles.css", $stylesCss, $utf8)
Write-Host "styles.css OK" -ForegroundColor Green

# === index.html con logo ===
$indexHtml = @'
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <meta name="theme-color" content="#c8102e">
  <title>Planta Rapel 2026 - Ingresar</title>
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
  <link href="css/styles.css" rel="stylesheet">
</head>
<body class="bg-login">
  <div class="container py-4 d-flex align-items-center justify-content-center min-vh-100">
    <div class="card shadow-lg login-card">
      <div class="card-header text-center py-3">
        <img src="assets/logo-unifrutti.png" alt="Unifrutti" class="logo-header" onerror="this.style.display='none';this.nextElementSibling.style.display='block';">
        <div style="display:none; color:white; font-weight:bold; font-size:1.3em; letter-spacing:2px;">UNIFRUTTI</div>
      </div>
      <div class="card-body p-4">
        <h4 class="fw-bold mb-1 text-center" style="color: #1a3a6c;">Registro de Asistencia</h4>
        <p class="text-muted text-center mb-4">Planta 2026</p>
        <form id="formLogin" novalidate autocomplete="on">
          <div class="mb-3">
            <input type="text" class="form-control form-control-lg input-rojo" id="username" placeholder="Usuario" autocomplete="username" autocapitalize="none" required>
          </div>
          <div class="mb-3">
            <input type="password" class="form-control form-control-lg input-rojo" id="password" placeholder="Contrase&ntilde;a" autocomplete="current-password" required>
          </div>
          <div id="msgError" class="alert alert-danger d-none py-2" role="alert"></div>
          <button type="submit" class="btn btn-primary btn-lg w-100 mb-3" id="btnLogin">Ingresar</button>
          <div class="text-center">
            <a href="#" class="text-muted small d-block mb-1" onclick="alert('Contacta a Gestion Humana'); return false;">&iquest;Olvid&oacute; su contrase&ntilde;a?</a>
            <a href="#" class="text-danger fw-bold small" onclick="alert('Contacta a Gestion Humana para solicitar acceso'); return false;">Solicitar Acceso</a>
          </div>
        </form>
      </div>
      <div class="card-footer text-center text-muted small py-2">Planta 2026 &middot; v0.1.0</div>
    </div>
  </div>
  <script src="js/config.js"></script>
  <script src="js/api.js"></script>
  <script src="js/auth.js"></script>
  <script src="js/login.js"></script>
</body>
</html>
'@
[System.IO.File]::WriteAllText("C:\planta-rapel-2026\index.html", $indexHtml, $utf8)
Write-Host "index.html OK" -ForegroundColor Green

# === home.html limpio con nombre + cargo + acceso al scanner ===
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
        <a href="scanner.html" class="btn btn-primary w-100 mb-2">Abrir Scanner QR</a>
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

# === home.js actualizado para mostrar cargo ===
$homeJs = @'
document.addEventListener('DOMContentLoaded', () => {
  if (!Auth.requiereLogin()) return;
  const usuario = Auth.obtenerSesion();
  document.getElementById('lblNombre').textContent = usuario.nombre_completo || usuario.username;
  document.getElementById('lblCargo').textContent = usuario.cargo || '';
  document.getElementById('lblRol').textContent = (usuario.rol || '-').toUpperCase();
  document.getElementById('lblEmpresa').textContent = usuario.empresa || '-';
  document.getElementById('btnLogout').addEventListener('click', () => {
    if (confirm('Cerrar sesion?')) {
      Auth.cerrarSesion();
    }
  });
});
'@
[System.IO.File]::WriteAllText("C:\planta-rapel-2026\js\home.js", $homeJs, $utf8)
Write-Host "home.js OK" -ForegroundColor Green

# === scanner.html con html5-qrcode (modo prueba) ===
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
      <a href="home.html" class="btn btn-sm btn-outline-light">Volver</a>
    </div>
  </nav>
  <div class="container py-3">
    <div class="alert alert-warning py-2 mb-3">
      <small><strong>Modo prueba:</strong> el scanner lee el QR pero a&uacute;n no registra. Pruebe que la c&aacute;mara funcione y los DNIs sean correctos.</small>
    </div>
    <div id="reader" style="width: 100%;"></div>
    <div class="card mt-3">
      <div class="card-body">
        <p class="mb-1 small text-muted">&Uacute;ltimo DNI escaneado:</p>
        <h4 class="mb-2" id="lblUltimoDni" style="color:#1a3a6c;">-</h4>
        <p class="mb-0 small text-success" id="lblMensaje"></p>
      </div>
    </div>
    <div class="card mt-3">
      <div class="card-body">
        <p class="mb-0 small text-muted">Escaneados en esta sesi&oacute;n: <strong id="contador">0</strong></p>
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

# === scanner.js con lectura QR + debounce ===
$scannerJs = @'
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
'@
[System.IO.File]::WriteAllText("C:\planta-rapel-2026\js\scanner.js", $scannerJs, $utf8)
Write-Host "scanner.js OK" -ForegroundColor Green

# === Placeholder README en assets/ ===
$assetsReadme = @'
Coloca aqui el logo de Unifrutti como `logo-unifrutti.png`.
Tamano recomendado: 200x60 pixeles aprox, fondo transparente.
'@
[System.IO.File]::WriteAllText("C:\planta-rapel-2026\assets\README.txt", $assetsReadme, $utf8)

# === Commit y push ===
git add .
git commit -m "Dia 1.5: Tahoma + home limpio + scanner basico + assets folder"
git push

Write-Host ""
Write-Host "===== LISTO =====" -ForegroundColor Green
Write-Host "1. Sube tu logo a: C:\planta-rapel-2026\assets\logo-unifrutti.png" -ForegroundColor Cyan
Write-Host "2. Haz: git add . ; git commit -m 'Logo' ; git push" -ForegroundColor Cyan
Write-Host "3. Cierra sesion y vuelve a loguear para que se cargue el nuevo nombre + cargo" -ForegroundColor Cyan