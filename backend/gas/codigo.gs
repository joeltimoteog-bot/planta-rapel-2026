/**
 * ============================================================
 * SNIPPET PARA APPS SCRIPT - Planta Rapel 2026
 * ============================================================
 * Este archivo es un BACKUP / referencia del codigo que debe
 * pegarse MANUALMENTE en el editor de Apps Script
 * (script.google.com). El backend de produccion no se
 * despliega desde este repo.
 *
 * AGREGADO 2026-05-14: endpoint asignarPinsMasivos
 *
 * COMO APLICARLO:
 *   1) Pegar la funcion asignarPinsMasivos() al final de codigo.gs
 *   2) Agregar el case 'asignarPinsMasivos' dentro del switch
 *      de acciones de doPost()
 * ============================================================
 */

// ---- 1) FUNCION: pegar al final de codigo.gs ----
function asignarPinsMasivos(pinInicial) {
  try {
    var pin = parseInt(pinInicial, 10);
    if (isNaN(pin) || pin < 1000 || pin > 9999) {
      return { ok: false, error: 'PIN inicial invalido (debe ser 4 digitos: 1000-9999)' };
    }

    var ss = SpreadsheetApp.getActiveSpreadsheet();
    var sheet = ss.getSheetByName('Usuarios');
    if (!sheet) return { ok: false, error: 'No se encontro la hoja "Usuarios"' };

    var data = sheet.getDataRange().getValues();
    if (data.length < 2) return { ok: false, error: 'La hoja "Usuarios" no tiene datos' };

    // Localizar columnas por nombre de cabecera (flexible ante el orden)
    var headers = data[0].map(function(h) { return String(h).trim().toLowerCase(); });
    function buscarCol(nombres) {
      for (var i = 0; i < headers.length; i++) {
        for (var j = 0; j < nombres.length; j++) {
          if (headers[i] === nombres[j]) return i;
        }
      }
      return -1;
    }
    var idxRol = buscarCol(['rol']);
    var idxPin = buscarCol(['pin']);
    var idxDni = buscarCol(['dni']);
    var idxNombre = buscarCol(['nombre_completo', 'nombre completo', 'nombre']);
    var idxUser = buscarCol(['username', 'usuario']);

    if (idxRol === -1) return { ok: false, error: 'No existe la columna "rol" en la hoja Usuarios' };
    if (idxPin === -1) return { ok: false, error: 'No existe la columna "pin" en la hoja Usuarios' };

    var asignados = [];
    var pinActual = pin;

    for (var r = 1; r < data.length; r++) {
      var rol = String(data[r][idxRol]).trim().toLowerCase();
      var pinVal = String(data[r][idxPin]).trim();
      if (rol === 'encargado_bus' && pinVal === '') {
        // Escribir el PIN como texto para conservar el formato de 4 digitos
        sheet.getRange(r + 1, idxPin + 1).setValue(String(pinActual));
        asignados.push({
          dni: idxDni !== -1 ? String(data[r][idxDni]).trim() : '',
          nombre: idxNombre !== -1
            ? String(data[r][idxNombre]).trim()
            : (idxUser !== -1 ? String(data[r][idxUser]).trim() : ''),
          pin: String(pinActual)
        });
        pinActual++;
      }
    }

    return { ok: true, asignados: asignados };
  } catch (e) {
    return { ok: false, error: 'Error en asignarPinsMasivos: ' + e.message };
  }
}

// ---- 2) CASE: agregar dentro del switch(accion) de doPost() ----
//
//   case 'asignarPinsMasivos':
//     resultado = asignarPinsMasivos(body.pinInicial);
//     break;
//
// Notas:
//  - 'body' es el objeto JSON ya parseado del request
//    (normalmente: var body = JSON.parse(e.postData.contents);).
//    Si en tu codigo.gs esa variable se llama distinto
//    (datos, params, req, request...) usa ese nombre.
//  - 'resultado' es la variable que doPost() devuelve como JSON.
//    Si tu doPost usa otro patron de retorno, adapta esa linea.
//  - El campo que envia el frontend es: pinInicial
