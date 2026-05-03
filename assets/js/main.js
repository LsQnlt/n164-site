// Smooth scroll pour tous les liens d'ancre
document.addEventListener("click", (e) => {
  const link = e.target.closest('a[href^="#"]');
  if (!link) return;

  const href = link.getAttribute("href");
  if (href === "#" || href.length < 2) return;

  const target = document.querySelector(href);
  if (!target) return;

  e.preventDefault();
  target.scrollIntoView({ behavior: "smooth" });

  document.querySelector(".header__nav-mobile")?.classList.remove("is-open");
});

// Lien actif dans la navbar selon la section visible
const sections = document.querySelectorAll("section[id]");
const navLinks = document.querySelectorAll('header a[href^="#"], .header__nav-mobile a[href^="#"]');

const observer = new IntersectionObserver(
  (entries) => {
    entries.forEach((entry) => {
      if (entry.isIntersecting) {
        const id = entry.target.id;
        navLinks.forEach((link) => {
          const isActive = link.getAttribute("href") === `#${id}`;
          if (isActive) {
            link.setAttribute("aria-current", "page");
          } else {
            link.removeAttribute("aria-current");
          }
        });
      }
    });
  },
  { rootMargin: "-40% 0px -55% 0px" },
);

sections.forEach((section) => observer.observe(section));
