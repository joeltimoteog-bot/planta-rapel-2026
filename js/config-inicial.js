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
  document.getElementById('btnInicio').addEventListener('click', () => {
    window.location.href = 'home.html';
  });
  
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
    
    const resp = await API.validarTrabajador(dniNorm);
    
    if (!resp.ok) {
      mostrarError('DNI no encontrado en ninguna base.');
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
    
    const zonaPacking = document.getElementById('zonaPacking').value;
    const turno = document.getElementById('turno').value;
    const ruta = document.getElementById('ruta').value.trim().toUpperCase();
    const codigoBus = document.getElementById('codigoBus').value.trim().toUpperCase();
    const placa = document.getElementById('placa').value.trim().toUpperCase();
    const cantidad = parseInt(document.getElementById('cantidad').value);
    const dni = inputDni.value.trim();
    
    if (!zonaPacking || !turno || !ruta || !codigoBus || !placa || !cantidad || !dni) {
      mostrarError('Complete todos los campos');
      return;
    }
    
    btn.disabled = true;
    btn.innerHTML = '<span class="spinner-border spinner-border-sm me-2"></span>Validando...';
    
    if (!encargadoValidado) {
      const ok = await validarDniEncargado(dni);
      if (!ok) {
        btn.disabled = false;
        btn.innerHTML = 'Iniciar Escaneo';
        return;
      }
    }
    
    BusConfig.guardar({
      zonaPacking: zonaPacking,
      turno: turno,
      ruta: ruta,
      codigoBus: codigoBus,
      placa: placa,
      cantidadAsistente: cantidad,
      encargadoDni: encargadoValidado.dni,
      encargadoNombre: encargadoValidado.nombre,
      encargadoEmpresa: encargadoValidado.empresa,
      iniciadoAt: new Date().toISOString()
    });
    
    // Limpiar asistencias previas
    sessionStorage.removeItem('planta_asistencias');
    
    window.location.href = 'scanner.html';
  });
  
  function mostrarError(msg) {
    msgError.textContent = msg;
    msgError.classList.remove('d-none');
  }
});