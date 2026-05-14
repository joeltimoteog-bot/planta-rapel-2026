document.addEventListener('DOMContentLoaded', () => {
  if (!Auth.requiereLogin()) return;

  const form = document.getElementById('formConfig');
  const btn = document.getElementById('btnIniciar');
  const msgError = document.getElementById('msgError');
  const cardEncargado = document.getElementById('cardEncargado');
  const lblNombreEncargado = document.getElementById('lblNombreEncargado');
  const inputDni = document.getElementById('dniEncargado');

  let encargadoValidado = null;

  // ==== AUTO-FOCUS SECUENCIAL ====
  // En selects avanza con 'change', en inputs avanza con Enter
  function setFocusSiguiente(currentId, nextId) {
    const el = document.getElementById(currentId);
    if (!el) return;
    if (el.tagName === 'SELECT') {
      el.addEventListener('change', () => {
        if (el.value) {
          const next = document.getElementById(nextId);
          if (next) setTimeout(() => next.focus(), 50);
        }
      });
    } else {
      el.addEventListener('keydown', (e) => {
        if (e.key === 'Enter') {
          e.preventDefault();
          if (el.value.trim()) {
            const next = document.getElementById(nextId);
            if (next) next.focus();
          }
        }
      });
    }
  }
  setFocusSiguiente('zonaPacking', 'turno');
  setFocusSiguiente('turno', 'ruta');
  setFocusSiguiente('ruta', 'codigoBus');
  setFocusSiguiente('codigoBus', 'placa');
  setFocusSiguiente('placa', 'cantidad');
  setFocusSiguiente('cantidad', 'cantidadAusente');
  setFocusSiguiente('cantidadAusente', 'dniEncargado');

  // ==== CALCULO AUTOMATICO DEL TOTAL ====
  function calcularTotal() {
    const a = parseInt(document.getElementById('cantidad').value) || 0;
    const u = parseInt(document.getElementById('cantidadAusente').value) || 0;
    document.getElementById('cantidadTotal').value = a + u;
  }
  document.getElementById('cantidad').addEventListener('input', calcularTotal);
  document.getElementById('cantidadAusente').addEventListener('input', calcularTotal);

  document.getElementById('btnLogout').addEventListener('click', () => {
    if (confirm('Salir de la sesion?')) Auth.cerrarSesion();
  });
  document.getElementById('btnInicio').addEventListener('click', () => {
    window.location.href = 'home.html';
  });

  // ==== VALIDACION DNI ENCARGADO + AUTO-SUBMIT ====
  // Al llegar a 8 digitos valida; si OK y el form esta completo, auto-envia
  inputDni.addEventListener('input', async () => {
    const dni = inputDni.value.trim();
    if (dni.length < 8) {
      encargadoValidado = null;
      cardEncargado.classList.add('d-none');
      return;
    }
    if (dni.length === 8) {
      const ok = await validarDniEncargado(dni);
      if (ok && form.checkValidity()) {
        setTimeout(() => btn.click(), 600);
      }
    }
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
    const cantidadAusente = parseInt(document.getElementById('cantidadAusente').value) || 0;
    const cantidadTotal = cantidad + cantidadAusente;
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
      cantidadAusente: cantidadAusente,
      cantidadTotal: cantidadTotal,
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
