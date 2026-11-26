(function () {
  'use strict';

  var THEME_KEY = 'clovance-color-theme';
  var root = document.documentElement;
  var isSpanish = (root.lang || '').toLowerCase().indexOf('es') === 0;
  var copyLabel = isSpanish ? 'Copiar' : 'Copy';
  var copiedLabel = isSpanish ? 'Copiado' : 'Copied';

  /* ---------- Theme ---------- */

  function updateThemeButton() {
    var button = document.querySelector('[data-theme-toggle]');
    if (!button) return;
    var dark = root.classList.contains('dark');
    var label = dark
      ? isSpanish ? 'Cambiar a modo claro' : 'Switch to light mode'
      : isSpanish ? 'Cambiar a modo oscuro' : 'Switch to dark mode';
    button.setAttribute('aria-label', label);
    button.setAttribute('title', label);
  }

  function setTheme(dark, persist) {
    root.classList.toggle('dark', dark);
    if (persist) {
      try {
        localStorage.setItem(THEME_KEY, dark ? 'dark' : 'light');
      } catch (error) {}
    }
    updateThemeButton();
  }

  var themeButton = document.querySelector('[data-theme-toggle]');
  if (themeButton) {
    updateThemeButton();
    themeButton.addEventListener('click', function () {
      setTheme(!root.classList.contains('dark'), true);
    });
  }

  /* ---------- Mobile sidebar ---------- */

  var body = document.body;
  var sidebarButton = document.querySelector('[data-sidebar-toggle]');

  function setSidebar(open) {
    body.classList.toggle('sidebar-open', open);
    if (sidebarButton) {
      sidebarButton.setAttribute('aria-expanded', String(open));
      sidebarButton.setAttribute(
        'aria-label',
        open
          ? isSpanish ? 'Cerrar navegación' : 'Close navigation'
          : isSpanish ? 'Abrir navegación' : 'Open navigation'
      );
    }
  }

  if (sidebarButton) {
    sidebarButton.setAttribute('aria-label', isSpanish ? 'Abrir navegación' : 'Open navigation');
    sidebarButton.addEventListener('click', function () {
      setSidebar(!body.classList.contains('sidebar-open'));
    });
  }

  document.querySelectorAll('[data-sidebar-close]').forEach(function (element) {
    element.addEventListener('click', function () {
      setSidebar(false);
    });
  });

  document.querySelectorAll('#sidebar a').forEach(function (link) {
    link.addEventListener('click', function () {
      setSidebar(false);
    });
  });

  document.addEventListener('keydown', function (event) {
    if (event.key === 'Escape') setSidebar(false);
  });

  window.addEventListener('resize', function () {
    if (window.innerWidth >= 768) setSidebar(false);
  });

  /* ---------- Clipboard helpers ---------- */

  function fallbackCopy(text) {
    return new Promise(function (resolve, reject) {
      var textarea = document.createElement('textarea');
      textarea.value = text;
      textarea.setAttribute('readonly', '');
      textarea.style.position = 'fixed';
      textarea.style.top = '-9999px';
      document.body.appendChild(textarea);
      textarea.select();

      try {
        document.execCommand('copy') ? resolve() : reject(new Error('Copy failed'));
      } catch (error) {
        reject(error);
      } finally {
        document.body.removeChild(textarea);
      }
    });
  }

  function copyText(text) {
    if (navigator.clipboard && window.isSecureContext) {
      return navigator.clipboard.writeText(text).catch(function () {
        return fallbackCopy(text);
      });
    }

    return fallbackCopy(text);
  }

  function flashButton(button, label) {
    var original = button.getAttribute('data-label') || button.textContent;
    button.setAttribute('data-label', original);
    button.textContent = label;
    button.classList.add('is-copied');

    window.setTimeout(function () {
      button.textContent = original;
      button.classList.remove('is-copied');
    }, 1800);
  }

  /* ---------- Install tabs ---------- */

  var installCommands = {
    unix: 'curl -fsSL https://evaristocuesta.github.io/clovance/install/install.sh | sh',
    win: 'irm https://evaristocuesta.github.io/clovance/install/install.ps1 | iex'
  };

  var installTabs = Array.prototype.slice.call(document.querySelectorAll('[data-install-tab]'));
  var installCommand = document.querySelector('[data-install-cmd]');

  installTabs.forEach(function (tab) {
    tab.addEventListener('click', function () {
      installTabs.forEach(function (other) {
        other.classList.remove('is-active');
        other.setAttribute('aria-pressed', 'false');
      });

      tab.classList.add('is-active');
      tab.setAttribute('aria-pressed', 'true');

      if (installCommand) {
        installCommand.textContent = installCommands[tab.dataset.cmd] || '';
      }
    });
  });

  document.querySelectorAll('[data-copy]').forEach(function (button) {
    button.addEventListener('click', function () {
      var container = button.closest('.install-command');
      var code = container ? container.querySelector('code') : null;
      if (!code) return;

      copyText(code.textContent)
        .then(function () {
          flashButton(button, copiedLabel);
        })
        .catch(function () {});
    });
  });

  /* ---------- Copy buttons on code blocks ---------- */

  document.querySelectorAll('.doc-body pre').forEach(function (pre) {
    var code = pre.querySelector('code');
    if (!code) return;

    var button = document.createElement('button');
    button.type = 'button';
    button.className = 'code-copy';
    button.textContent = copyLabel;
    button.setAttribute('aria-label', isSpanish ? 'Copiar código al portapapeles' : 'Copy code to clipboard');

    button.addEventListener('click', function () {
      copyText(code.textContent)
        .then(function () {
          flashButton(button, copiedLabel);
        })
        .catch(function () {});
    });

    pre.appendChild(button);
  });
})();
