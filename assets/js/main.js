document.addEventListener('DOMContentLoaded', () => {
  const filmCards = document.querySelectorAll('.film-card');
  const filterButtons = document.querySelectorAll('.films__filter');
  const filmPanel = document.getElementById('film-panel');
  const panelOverlay = document.getElementById('panel-overlay');
  const panelClose = document.querySelector('.film-panel__close');
  const menuToggle = document.querySelector('.header__menu-toggle');
  const mobileNav = document.querySelector('.header__nav-mobile');
  const navLinks = document.querySelectorAll('.header__nav-mobile a');

  const panelImage = document.querySelector('.film-panel__image');
  const panelVideo = document.querySelector('.film-panel__video');
  const panelCategory = document.querySelector('.film-panel__category');
  const panelTitle = document.querySelector('.film-panel__title');
  const panelDescription = document.querySelector('.film-panel__description');

  // Filter
  filterButtons.forEach(button => {
    button.addEventListener('click', () => {
      const filter = button.dataset.filter;
      filterButtons.forEach(btn => btn.classList.remove('active', 'bg-neutral-100', 'text-neutral-950', 'border-neutral-100'));
      button.classList.add('active', 'bg-neutral-100', 'text-neutral-950', 'border-neutral-100');
      
      filmCards.forEach(card => {
        card.classList.toggle('hidden', filter !== 'all' && card.dataset.category !== filter);
      });
    });
  });

  // Open panel
  filmCards.forEach(card => {
    card.addEventListener('click', () => {
      panelTitle.textContent = card.dataset.title;
      panelCategory.textContent = card.dataset.category.replace(/-/g, ' ');
      panelDescription.textContent = card.dataset.description;

      if (card.dataset.video) {
        panelImage.classList.add('hidden');
        panelVideo.innerHTML = getVideoEmbed(card.dataset.video);
        panelVideo.classList.remove('hidden');
      } else {
        panelVideo.classList.add('hidden');
        panelVideo.innerHTML = '';
        panelImage.src = card.dataset.image;
        panelImage.classList.remove('hidden');
      }

      filmPanel.classList.remove('translate-x-full');
      panelOverlay.classList.remove('opacity-0', 'invisible');
      document.body.classList.add('overflow-hidden');
    });
  });

  // Close panel
  function closePanel() {
    filmPanel.classList.add('translate-x-full');
    panelOverlay.classList.add('opacity-0', 'invisible');
    document.body.classList.remove('overflow-hidden');
    setTimeout(() => { panelVideo.innerHTML = ''; }, 300);
  }

  panelClose.addEventListener('click', closePanel);
  panelOverlay.addEventListener('click', closePanel);
  document.addEventListener('keydown', e => {
    if (e.key === 'Escape') closePanel();
  });

  // Mobile menu
  menuToggle.addEventListener('click', () => {
    mobileNav.classList.toggle('opacity-0');
    mobileNav.classList.toggle('invisible');
  });

  navLinks.forEach(link => {
    link.addEventListener('click', () => {
      mobileNav.classList.add('opacity-0', 'invisible');
    });
  });

  // Video embed
  function getVideoEmbed(url) {
    const yt = url.match(/(?:youtube\.com\/(?:watch\?v=|embed\/)|youtu\.be\/)([a-zA-Z0-9_-]+)/);
    if (yt) return `<iframe class="w-full aspect-video" src="https://www.youtube.com/embed/${yt[1]}" frameborder="0" allowfullscreen></iframe>`;
    
    const vm = url.match(/vimeo\.com\/(\d+)/);
    if (vm) return `<iframe class="w-full aspect-video" src="https://player.vimeo.com/video/${vm[1]}" frameborder="0" allowfullscreen></iframe>`;
    
    return '';
  }

  // Smooth scroll
  document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', e => {
      e.preventDefault();
      document.querySelector(anchor.getAttribute('href'))?.scrollIntoView({ behavior: 'smooth' });
    });
  });
});