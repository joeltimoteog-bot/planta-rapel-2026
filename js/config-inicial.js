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