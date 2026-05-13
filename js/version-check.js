(function() {
  const VERSION_URL = './version.json?t=' + Date.now();
  fetch(VERSION_URL, { cache: 'no-store' })
    .then(r => r.json())
    .then(data => {
      const serverVersion = data.version;
      const localVersion = localStorage.getItem('app_version');
      if (!localVersion) {
        localStorage.setItem('app_version', serverVersion);
        return;
      }
      if (localVersion !== serverVersion) {
        console.log('Nueva version detectada:', serverVersion, '- recargando...');
        localStorage.setItem('app_version', serverVersion);
        // Esperar 200ms para no romper otros scripts del DOM
        setTimeout(() => window.location.reload(true), 200);
      }
    })
    .catch(e => console.warn('Version check fallo:', e));
})();