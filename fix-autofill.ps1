$utf8 = [System.Text.UTF8Encoding]::new($true)

# === Reescribir login.js sin auto-submit ===
$loginJs = @'
document.addEventListener("DOMContentLoaded", function() {
  console.log("[login] DOM listo");
  
  if (typeof API === "undefined") { console.error("API no cargado"); return; }
  if (typeof Auth === "undefined") { console.error("Auth no cargado"); return; }
  
  API.ping().catch(function() {});
  
  var inputPin = document.getElementById("inputPin");
  var inputUser = document.getElementById("inputUser");
  var inputPass = document.getElementById("inputPass");
  var btnLoginPin = document.getElementById("btnLoginPin");
  var btnLogin = document.getElementById("btnLogin");
  
  if (btnLoginPin) btnLoginPin.addEventListener("click", loginConPin);
  if (btnLogin) btnLogin.addEventListener("click", loginAdmin);
  
  if (inputPin) {
    inputPin.addEventListener("keydown", function(e) {
      if (e.key === "Enter") { e.preventDefault(); loginConPin(); }
    });
    inputPin.addEventListener("input", function(e) {
      e.target.value = e.target.value.replace(/\D/g, "");
    });
  }
  if (inputPass) {
    inputPass.addEventListener("keydown", function(e) {
      if (e.key === "Enter") { e.preventDefault(); loginAdmin(); }
    });
  }
});

async function loginConPin() {
  console.log("[login] loginConPin");
  var pin = document.getElementById("inputPin").value.trim();
  var msg = document.getElementById("msgPin");
  if (pin.length !== 4) {
    msg.textContent = "El PIN debe tener 4 digitos";
    msg.className = "mensaje error";
    return;
  }
  msg.textContent = "Verificando...";
  msg.className = "mensaje";
  try {
    var resp = await API.loginPin(pin);
    console.log("[login] resp PIN:", resp);
    procesarRespLogin(resp, msg);
  } catch (err) {
    console.error(err);
    msg.textContent = "Error de conexion";
    msg.className = "mensaje error";
  }
}

async function loginAdmin() {
  console.log("[login] loginAdmin");
  var username = document.getElementById("inputUser").value.trim();
  var password = document.getElementById("inputPass").value;
  var msg = document.getElementById("msgLogin");
  if (!username || !password) {
    msg.textContent = "Completa usuario y contrasena";
    msg.className = "mensaje error";
    return;
  }
  msg.textContent = "Verificando...";
  msg.className = "mensaje";
  try {
    var resp = await API.login(username, password);
    console.log("[login] resp admin:", resp);
    procesarRespLogin(resp, msg);
  } catch (err) {
    console.error(err);
    msg.textContent = "Error de conexion";
    msg.className = "mensaje error";
  }
}

function procesarRespLogin(resp, msg) {
  if (!resp || !resp.ok) {
    msg.textContent = (resp && resp.error) ? resp.error : "Error de autenticacion";
    msg.className = "mensaje error";
    return;
  }
  Auth.guardarSesion(resp.usuario);
  msg.textContent = "Bienvenido, " + (resp.usuario.nombre_completo || resp.usuario.username);
  msg.className = "mensaje success";
  setTimeout(function() {
    if (resp.usuario.rol === "admin") {
      window.location.href = "home.html";
    } else {
      window.location.href = "config.html";
    }
  }, 600);
}
'@

[System.IO.File]::WriteAllText("C:\planta-rapel-2026\js\login.js", $loginJs, $utf8)
Write-Host "login.js: SIN auto-submit del PIN" -ForegroundColor Green

# === Agregar autocomplete=off al HTML + limpiar PIN al cambiar tab ===
$htmlPath = "C:\planta-rapel-2026\index.html"
$h = Get-Content $htmlPath -Raw

$h = $h.Replace(
  'class="pin-input" id="inputPin" placeholder="0000">',
  'class="pin-input" id="inputPin" placeholder="0000" autocomplete="off" autocorrect="off" spellcheck="false">'
)
$h = $h.Replace(
  'class="form-input" id="inputUser" placeholder="ej: jtimoteo">',
  'class="form-input" id="inputUser" placeholder="ej: jtimoteo" autocomplete="off">'
)
$h = $h.Replace(
  '<input type="password" class="form-input" id="inputPass">',
  '<input type="password" class="form-input" id="inputPass" autocomplete="new-password">'
)

# Agregar script para limpiar PIN al cambiar de tab
$cleanScript = @'

<script>
document.addEventListener("DOMContentLoaded", function() {
  var tabs = document.querySelectorAll('[data-bs-toggle="tab"]');
  tabs.forEach(function(t) {
    t.addEventListener('shown.bs.tab', function(e) {
      var href = e.target.getAttribute('href');
      if (href === '#tabAdmin') {
        var p = document.getElementById('inputPin'); if (p) p.value = '';
        var u = document.getElementById('inputUser'); if (u) setTimeout(function(){u.focus();}, 50);
      } else {
        var us = document.getElementById('inputUser'); if (us) us.value = '';
        var ps = document.getElementById('inputPass'); if (ps) ps.value = '';
      }
    });
  });
});
</script>

'@

if ($h -notmatch 'shown\.bs\.tab') {
  $h = $h.Replace('</body>', $cleanScript + '</body>')
}

[System.IO.File]::WriteAllText($htmlPath, $h, $utf8)
Write-Host "index.html: autocomplete OFF + limpieza al cambiar tab" -ForegroundColor Green

# Update version
$version = (Get-Date).ToString('yyyyMMdd-HHmmss')
[System.IO.File]::WriteAllText("C:\planta-rapel-2026\version.json", "{`"version`": `"$version`"}", $utf8)

git add .
git commit -m "Fix: quitar auto-submit PIN + autocomplete off (no interfiere admin)"
git push

Write-Host ""
Write-Host "LISTO - prueba ahora" -ForegroundColor Green