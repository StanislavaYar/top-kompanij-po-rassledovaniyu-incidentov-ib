// Только визуальные эффекты: подсветка пункта оглавления, закрытие выпадающих меню.
(function () {
  var links = Array.prototype.slice.call(document.querySelectorAll('.ir-toc-side a[href^="#"]'));
  if (links.length && 'IntersectionObserver' in window) {
    var map = {};
    links.forEach(function (a) { map[a.getAttribute('href').slice(1)] = a; });
    var current = null;
    var io = new IntersectionObserver(function (entries) {
      entries.forEach(function (e) {
        if (!e.isIntersecting) return;
        var a = map[e.target.id];
        if (!a || a === current) return;
        if (current) current.classList.remove('is-active');
        a.classList.add('is-active');
        current = a;
      });
    }, { rootMargin: '-80px 0px -70% 0px' });
    Object.keys(map).forEach(function (id) { var s = document.getElementById(id); if (s) io.observe(s); });
  }
  var menus = document.querySelectorAll('.ir-dd, .ir-mnav');
  document.addEventListener('click', function (ev) {
    menus.forEach(function (d) { if (d.open && !d.contains(ev.target)) d.open = false; });
  });
  document.addEventListener('keydown', function (ev) {
    if (ev.key !== 'Escape') return;
    menus.forEach(function (d) { if (d.open) { d.open = false; d.querySelector('summary').focus(); } });
  });
  document.querySelectorAll('.ir-mnav__panel a, .ir-toc-inline a').forEach(function (a) {
    a.addEventListener('click', function () { var d = a.closest('details'); if (d) d.open = false; });
  });
})();
// Кнопка "Наверх": видна после прокрутки на высоту экрана. Без JS остается обычной ссылкой на начало страницы.
(function () {
  var btn = document.querySelector('.ir-totop');
  if (!btn) return;
  document.documentElement.classList.add('ir-js');
  var reduce = window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  var update = function () { btn.classList.toggle('is-visible', window.scrollY > window.innerHeight * 0.9); };
  window.addEventListener('scroll', update, { passive: true });
  update();
  btn.addEventListener('click', function (ev) {
    ev.preventDefault();
    window.scrollTo({ top: 0, behavior: reduce ? 'auto' : 'smooth' });
    btn.blur();
  });
})();
