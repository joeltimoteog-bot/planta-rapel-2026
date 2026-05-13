cd C:\planta-rapel-2026

$utf8 = [System.Text.UTF8Encoding]::new($true)

# ===== index.html =====
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
        <div class="logo-unifrutti mx-auto mb-2"></div>
        <small class="text-white opacity-75">unifrutti</small>
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
Write-Host "index.html actualizado" -ForegroundColor Green

# ===== home.html limpio sin mensajes internos =====
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
      <span class="navbar-brand mb-0 h6">Planta Rapel 2026</span>
      <button class="btn btn-sm btn-outline-light" id="btnLogout">Cerrar sesi&oacute;n</button>
    </div>
  </nav>
  <div class="container py-4">
    <div class="card shadow-sm">
      <div class="card-body text-center py-5">
        <h3 class="mb-3" style="color:#1a3a6c;">Bienvenido</h3>
        <p class="lead mb-2" id="lblNombre">-</p>
        <p class="text-muted mb-0">
          <span class="badge bg-secondary me-2" id="lblRol">-</span>
          <span class="badge" id="lblEmpresa" style="background:#c8102e;">-</span>
        </p>
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
Write-Host "home.html actualizado" -ForegroundColor Green

# ===== Commit y push =====
git add .
git status
git commit -m "Fix: encoding HTMLs y home limpio"
git push

Write-Host ""
Write-Host "===== LISTO =====" -ForegroundColor Green
Write-Host "Espera 1-2 min y refresca con Ctrl+F5" -ForegroundColor Cyan