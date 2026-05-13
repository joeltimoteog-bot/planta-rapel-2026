cd C:\planta-rapel-2026
$utf8 = [System.Text.UTF8Encoding]::new($true)

$indexHtml = @'
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Login - Planta Rapel 2026</title>
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
<script src="js/version-check.js"></script>
<style>
  * { box-sizing: border-box; }
  body {
    background: #1a3a6c;
    min-height: 100vh;
    margin: 0;
    display: flex;
    align-items: center;
    justify-content: center;
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
  }
  .login-wrapper {
    width: 100%;
    max-width: 400px;
    padding: 20px;
    text-align: center;
  }
  .logo-box {
    background: white;
    display: inline-block;
    padding: 16px 32px;
    border-radius: 12px;
    margin-bottom: 20px;
  }
  .logo-box img {
    max-height: 80px;
    width: auto;
    display: block;
  }
  .login-title {
    color: white;
    font-size: 1.5rem;
    font-weight: 700;
    margin-bottom: 24px;
    text-align: center;
  }
  .login-box {
    background: white;
    border-radius: 12px;
    overflow: hidden;
    box-shadow: 0 10px 30px rgba(0,0,0,0.2);
  }
  .nav-tabs { border-bottom: 1px solid #e0e0e0; }
  .nav-tabs .nav-link {
    border: none;
    color: #666;
    font-weight: 600;
    padding: 14px 0;
    text-align: center;
    flex: 1;
  }
  .nav-tabs .nav-link.active {
    color: #c8102e;
    background: white;
    border-bottom: 3px solid #c8102e;
  }
  .tab-content { padding: 24px; }
  .tab-pane { animation: none !important; }
  .form-label-bold {
    display: block;
    font-weight: 700;
    color: #333;
    margin-bottom: 10px;
    text-align: center;
    font-size: 0.95rem;
  }
  .pin-input {
    font-size: 1.8rem !important;
    letter-spacing: 14px !important;
    font-weight: 700;
    text-align: center;
    background: #f5f5f5;
    border: 2px solid #ddd;
    border-radius: 10px;
    padding: 14px 0 14px 14px;
    width: 100%;
  }
  .pin-input:focus {
    outline: none;
    background: white;
    border-color: #c8102e;
  }
  .form-input {
    width: 100%;
    padding: 10px 14px;
    border: 2px solid #ddd;
    border-radius: 8px;
    font-size: 1rem;
    margin-bottom: 14px;
    font-weight: 500;
  }
  .form-input:focus {
    outline: none;
    border-color: #c8102e;
  }
  .btn-ingresar {
    background: #c8102e;
    color: white;
    font-weight: 700;
    padding: 12px;
    border-radius: 10px;
    border: none;
    width: 100%;
    margin-top: 16px;
    font-size: 1rem;
    cursor: pointer;
  }
  .btn-ingresar:hover { background: #a00d24; }
  .mensaje {
    margin-top: 14px;
    font-size: 0.85rem;
    text-align: center;
    font-weight: 600;
    min-height: 20px;
  }
  .mensaje.error { color: #c8102e; }
  .mensaje.success { color: #28a745; }
  .footer-v {
    color: rgba(255,255,255,0.7);
    font-size: 0.75rem;
    margin-top: 18px;
    text-align: center;
  }
</style>
</head>
<body>
<div class="login-wrapper">
  
  <div class="logo-box">
    <img src="assets/logo-unifrutti.png" alt="Unifrutti">
  </div>
  
  <h1 class="login-title">PLANTA RAPEL 2026</h1>
  
  <div class="login-box">
    <ul class="nav nav-tabs nav-fill">
      <li class="nav-item">
        <a class="nav-link active" data-bs-toggle="tab" href="#tabEnc">Encargado (PIN)</a>
      </li>
      <li class="nav-item">
        <a class="nav-link" data-bs-toggle="tab" href="#tabAdmin">Admin / Coordinador</a>
      </li>
    </ul>
    <div class="tab-content">
      
      <div class="tab-pane fade show active" id="tabEnc">
        <label class="form-label-bold">Ingresa tu PIN de 4 d&iacute;gitos</label>
        <input type="text" inputmode="numeric" pattern="[0-9]*" maxlength="4"
               class="pin-input" id="inputPin" placeholder="0000">
        <button class="btn-ingresar" id="btnLoginPin">INGRESAR</button>
        <div class="mensaje" id="msgPin"></div>
      </div>
      
      <div class="tab-pane fade" id="tabAdmin">
        <label class="form-label-bold">USUARIO</label>
        <input type="text" class="form-input" id="inputUser" placeholder="ej: jtimoteo">
        <label class="form-label-bold">CONTRASE&Ntilde;A</label>
        <input type="password" class="form-input" id="inputPass">
        <button class="btn-ingresar" id="btnLogin">INGRESAR</button>
        <div class="mensaje" id="msgLogin"></div>
      </div>
      
    </div>
  </div>
  
  <div class="footer-v">v0.5.0 &middot; Unifrutti / Rapel SAC</div>
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"></script>
<script src="js/config.js"></script>
<script src="js/api.js"></script>
<script src="js/auth.js"></script>
<script src="js/login.js"></script>
</body>
</html>
'@

[System.IO.File]::WriteAllText("C:\planta-rapel-2026\index.html", $indexHtml, $utf8)
Write-Host "index.html OK - login centrado y sin parpadeo" -ForegroundColor Green

$version = (Get-Date).ToString('yyyyMMdd-HHmmss')
[System.IO.File]::WriteAllText("C:\planta-rapel-2026\version.json", "{`"version`": `"$version`"}", $utf8)

git add .
git commit -m "Login: rediseno centrado, negrita, sin parpadeo"
git push

Write-Host "LISTO" -ForegroundColor Green