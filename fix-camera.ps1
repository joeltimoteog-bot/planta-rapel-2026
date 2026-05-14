$utf8 = [System.Text.UTF8Encoding]::new($true)
$jsPath = "C:\planta-rapel-2026\js\scanner.js"
$j = Get-Content $jsPath -Raw

# === Replace 1: simplificar el primer parametro a solo facingMode ===
$old1 = @'
      html5QrCode.start(
        // [PERF 2] Resolucion 1280x720 fija = menos carga de CPU en celulares modestos
        {
          facingMode: { ideal: "environment" },
          width: { ideal: 1280 },
          height: { ideal: 720 },
          frameRate: { ideal: 25 }
        },
'@

$new1 = @'
      html5QrCode.start(
        // [PERF 2] Primer parametro solo facingMode (libreria acepta 1 key)
        { facingMode: "environment" },
'@

$j = $j.Replace($old1, $new1)

# === Replace 2: agregar videoConstraints dentro del config ===
$old2 = @'
          aspectRatio: 1.0
        },
        onScanSuccess,
'@

$new2 = @'
          aspectRatio: 1.0,
          // [PERF 2] videoConstraints aqui dentro (no en primer parametro)
          videoConstraints: {
            facingMode: { ideal: "environment" },
            width: { ideal: 1280 },
            height: { ideal: 720 },
            frameRate: { ideal: 25 }
          }
        },
        onScanSuccess,
'@

$j = $j.Replace($old2, $new2)

[System.IO.File]::WriteAllText($jsPath, $j, $utf8)
Write-Host "scanner.js: error de camara corregido" -ForegroundColor Green

# Verificacion
Write-Host ""
Write-Host "=== Verificando ===" -ForegroundColor Cyan
Select-String -Path $jsPath -Pattern "videoConstraints|html5QrCode.start"

$version = (Get-Date).ToString('yyyyMMdd-HHmmss')
[System.IO.File]::WriteAllText("C:\planta-rapel-2026\version.json", "{`"version`": `"$version`"}", $utf8)

git add .
git commit -m "Fix camera: mover constraints a videoConstraints (error 1 key)"
git push

Write-Host ""
Write-Host "LISTO - prueba ahora" -ForegroundColor Green