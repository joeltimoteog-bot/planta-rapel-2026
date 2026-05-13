$utf8 = [System.Text.UTF8Encoding]::new($true)

$loginJs = @'
document.addEventListener("DOMContentLoaded", function() {
  console.log("[login] DOM listo");
  
  if (typeof API === "undefined") { console.error("API no cargado"); return; }
  if (typeof Auth === "undefined") { console.error("Auth no cargado"); return; }
  
  API.ping().catch(function() {});
  API.validarTrabajador("00000000").catch(function() {});
  
  var inputPin = document.getElementById("inputPin");
  var inputUser = document.getElementById("inputUser");
  var inputPass = document.getElementById("inputPass");
  var btnLoginPin = document.getElementById("btnLoginPin");
  var btnLogin = document.getElementById("btnLogin");
  
  if (btnLoginPin) {
    btnLoginPin.addEventListener("click", loginConPin);
    console.log("[login] btnLoginPin listener OK");
  }
  if (btnLogin) {
    btnLogin.addEventListener("click", loginAdmin);
    console.log("[login] btnLogin listener OK");
  }
  
  if (inputPin) {
    inputPin.addEventListener("keydown", function(e) {
      if (e.key === "Enter") { e.preventDefault(); loginConPin(); }
    });
    inputPin.addEventListener("input", function(e) {
      var v = e.target.value.replace(/\D/g, "");
      e.target.value = v;
      if (v.length === 4) loginConPin();
    });
  }
  if (inputPass) {
    inputPass.addEventListener("keydown", function(e) {
      if (e.key === "Enter") { e.preventDefault(); loginAdmin(); }
    });
  }
  
  setTimeout(function() { if (inputPin) inputPin.focus(); }, 100);
});

async function loginConPin() {
  console.log("[login] loginConPin disparado");
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
    console.log("[login] respuesta PIN:", resp);
    procesarRespLogin(resp, msg);
  } catch (err) {
    console.error("[login] error PIN:", err);
    msg.textContent = "Error de conexion: " + err.message;
    msg.className = "mensaje error";
  }
}

async function loginAdmin() {
  console.log("[login] loginAdmin disparado");
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
    console.log("[login] respuesta admin:", resp);
    procesarRespLogin(resp, msg);
  } catch (err) {
    console.error("[login] error admin:", err);
    msg.textContent = "Error de conexion: " + err.message;
    msg.className = "mensaje error";
  }
}

function procesarRespLogin(resp, msg) {
  if (!resp || !resp.ok) {
    msg.textContent = (resp && resp.error) ? resp.error : "Error de autenticacion";
    msg.className = "mensaje error";
    var inputPin = document.getElementById("inputPin");
    if (inputPin) inputPin.value = "";
    return;
  }
  console.log("[login] guardando sesion para:", resp.usuario.username);
  Auth.guardarSesion(resp.usuario);
  msg.textContent = "Bienvenido, " + (resp.usuario.nombre_completo || resp.usuario.username);
  msg.className = "mensaje success";
  setTimeout(function() {
    if (resp.usuario.rol === "admin") {
      console.log("[login] redirigiendo a home.html");
      window.location.href = "home.html";
    } else {
      console.log("[login] redirigiendo a config.html");
      window.location.href = "config.html";
    }
  }, 600);
}
'@

[System.IO.File]::WriteAllText("C:\planta-rapel-2026\js\login.js", $loginJs, $utf8)
Write-Host "login.js reescrito limpio con console.log de diagnostico" -ForegroundColor Green

$version = (Get-Date).ToString('yyyyMMdd-HHmmss')
[System.IO.File]::WriteAllText("C:\planta-rapel-2026\version.json", "{`"version`": `"$version`"}", $utf8)

git add .
git commit -m "Login: reescribir limpio con diagnostico console.log"
git push

Write-Host "LISTO - prueba ahora con F12 Console abierto" -ForegroundColor Green