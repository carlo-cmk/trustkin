const TRUSTKIN_WHATSAPP = "243854541549";
const DEFAULT_WHATSAPP_MESSAGE = "Bonjour, puis-je en savoir plus sur le produit ?";

const brands = [
  { name: "Audi", slug: "audi", logo: "voitures/Audi/Audi logo/audi.jpeg" },
  { name: "BMW", slug: "bmw", logo: "voitures/Bmw/Bmw logo/BMW.jpeg" },
  { name: "Honda", slug: "honda", logo: "voitures/hONDA/logo honda/Honda.jpeg" },
  { name: "Jaguar", slug: "jaguar", logo: "voitures/Jaguar/logo jaguar/Jaguar logo.jpeg" },
  { name: "Mazda", slug: "mazda", logo: "voitures/mazda/Mazda logo/Mazda.jpeg" },
  { name: "Mercedes", slug: "mercedes", logo: "voitures/Mercedes/logo mercedes/mercedes logo.jpeg" },
  { name: "Mitsubishi", slug: "mitsubishi", logo: "voitures/Mitsubishi/LOGO Mitsubishi/Mitsubishi.jpeg" },
  { name: "Nissan", slug: "nissan", logo: "voitures/Nissan/nissan logo/Nissan.jpeg" },
  { name: "Terios (Daihatsu)", slug: "terios", logo: "voitures/terrios/terrios logo/Terrios.jpeg" },
  { name: "Tesla", slug: "tesla", logo: "voitures/tesla/logo tesla/Tesla.jpeg" },
  { name: "Toyota", slug: "toyota", logo: "voitures/Toyota/logo toyota/Toyota.jpeg" }
];

const brandGrid = document.querySelector("#brand-grid");
const dialog = document.querySelector("#detail-dialog");
const dialogContent = document.querySelector("#dialog-content");

function renderBrands(query = "") {
  const normalizedQuery = query.trim().toLocaleLowerCase("fr");
  const visibleBrands = brands.filter((brand) => brand.name.toLocaleLowerCase("fr").includes(normalizedQuery));

  brandGrid.innerHTML = visibleBrands.map((brand) => `
    <button class="brand-tile" type="button" data-brand="${brand.slug}" aria-label="Voir les annonces ${brand.name}">
      <img src="${brand.logo}" alt="Logo ${brand.name}" loading="lazy">
      <small>0 annonce publiée</small>
    </button>
  `).join("");

  brandGrid.querySelectorAll(".brand-tile").forEach((tile) => {
    tile.addEventListener("click", () => showBrand(tile.dataset.brand));
  });

  brandGrid.querySelectorAll("img").forEach((image) => {
    image.addEventListener("error", () => {
      const fallback = document.createElement("span");
      fallback.className = "brand-fallback";
      fallback.textContent = image.alt.replace("Logo ", "");
      image.replaceWith(fallback);
    }, { once: true });
  });
}

function showBrand(slug) {
  const brand = brands.find((item) => item.slug === slug);
  if (!brand) return;

  dialogContent.innerHTML = `
    <p class="eyebrow">VÉHICULES · ${brand.name.toLocaleUpperCase("fr")}</p>
    <h2>Les annonces ${brand.name} arrivent.</h2>
    <p>Nous n'avons pas encore reçu de fiche avec des photos authentiques pour cette marque. L'équipe TrustKin pourra vous prévenir ou vous aider à trouver un véhicule.</p>
    <a class="button button-navy" href="#contact" data-dialog-contact>Demander à TrustKin <span>↗</span></a>
  `;
  dialog.showModal();
  dialogContent.querySelector("[data-dialog-contact]").addEventListener("click", () => dialog.close());
}

renderBrands();
document.querySelector("#year").textContent = new Date().getFullYear();

document.querySelector("#brand-search").addEventListener("input", (event) => {
  renderBrands(event.currentTarget.value);
});

document.querySelectorAll(".filter-chip").forEach((chip) => {
  chip.addEventListener("click", () => {
    document.querySelectorAll(".filter-chip").forEach((item) => item.classList.remove("active"));
    chip.classList.add("active");
    if (chip.dataset.condition !== "all") {
      dialogContent.innerHTML = `
        <p class="eyebrow">FILTRE · ${chip.textContent.toLocaleUpperCase("fr")}</p>
        <h2>Le catalogue se prépare.</h2>
        <p>Le filtre sera utile dès que des annonces de véhicules vérifiées seront disponibles. Pour l'instant, aucune annonce n'est publiée.</p>
        <a class="button button-navy" href="#publier" data-dialog-contact>Proposer un véhicule <span>↗</span></a>
      `;
      dialog.showModal();
      dialogContent.querySelector("[data-dialog-contact]").addEventListener("click", () => dialog.close());
    }
  });
});

document.querySelector("#all-brands").addEventListener("click", () => {
  document.querySelector("#brand-search").value = "";
  renderBrands();
  document.querySelector("#brand-grid").scrollIntoView({ behavior: "smooth", block: "center" });
});

document.querySelector("#hero-search").addEventListener("submit", (event) => {
  event.preventDefault();
  const category = document.querySelector("#quick-category").value;
  const keyword = document.querySelector("#quick-keyword").value.trim();

  if (category === "vehicules" || category === "all") {
    document.querySelector("#brand-search").value = keyword;
    renderBrands(keyword);
    document.querySelector("#vehicules").scrollIntoView({ behavior: "smooth" });
    return;
  }

  const destination = category === "immobilier" ? "#immobilier" : "#iphone-services";
  document.querySelector(destination).scrollIntoView({ behavior: "smooth" });
  dialogContent.innerHTML = `
    <p class="eyebrow">RECHERCHE TRUSTKIN</p>
    <h2>Nous pouvons vous aider à chercher.</h2>
    <p>${keyword ? `Votre recherche « ${keyword.replace(/[<>]/g, "")} »` : "Votre recherche"} sera transmise à TrustKin dès que le contact WhatsApp sera configuré.</p>
    <a class="button button-navy" href="#contact" data-dialog-contact>Écrire à TrustKin <span>↗</span></a>
  `;
  dialog.showModal();
  dialogContent.querySelector("[data-dialog-contact]").addEventListener("click", () => dialog.close());
});

document.querySelector(".dialog-close").addEventListener("click", () => dialog.close());
dialog.addEventListener("click", (event) => {
  if (event.target === dialog) dialog.close();
});

const menuToggle = document.querySelector(".menu-toggle");
const mainNav = document.querySelector(".main-nav");
menuToggle.addEventListener("click", () => {
  const isExpanded = menuToggle.getAttribute("aria-expanded") === "true";
  menuToggle.setAttribute("aria-expanded", String(!isExpanded));
  mainNav.classList.toggle("open", !isExpanded);
});
mainNav.querySelectorAll("a").forEach((link) => {
  link.addEventListener("click", () => {
    mainNav.classList.remove("open");
    menuToggle.setAttribute("aria-expanded", "false");
  });
});

document.querySelectorAll("[data-service]").forEach((link) => {
  link.addEventListener("click", () => {
    const subject = document.querySelector(".contact-form select[name='subject']");
    subject.value = "Je souhaite un devis de service";
    document.querySelector(".contact-form textarea[name='message']").value = `Je souhaite en savoir plus : ${link.dataset.service}.`;
  });
});

document.querySelector("#contact-form").addEventListener("submit", (event) => {
  event.preventDefault();
  const form = event.currentTarget;
  const formData = new FormData(form);
  const message = [
    "Bonjour TrustKin, je souhaite vous contacter.",
    `Nom : ${formData.get("name")}`,
    `Téléphone : ${formData.get("phone")}`,
    `Sujet : ${formData.get("subject")}`,
    `Message : ${formData.get("message") || "Aucun détail supplémentaire."}`
  ].join("\n");
  const note = document.querySelector("#form-note");

  if (!/^\d{8,15}$/.test(TRUSTKIN_WHATSAPP)) {
    note.textContent = "Le numéro WhatsApp de TrustKin n'est pas valide. Votre message n'a pas été envoyé.";
    note.classList.add("form-note-warning");
    return;
  }

  const whatsappMessage = formData.get("message")
    ? message
    : `${DEFAULT_WHATSAPP_MESSAGE}\n\nNom : ${formData.get("name")}\nTéléphone : ${formData.get("phone")}\nSujet : ${formData.get("subject")}`;
  window.open(`https://wa.me/${TRUSTKIN_WHATSAPP}?text=${encodeURIComponent(whatsappMessage)}`, "_blank", "noopener,noreferrer");
});

const sectionTargets = ["accueil", "vehicules", "immobilier", "contact"];
const dockLinks = [...document.querySelectorAll(".mobile-dock a")];
const sectionObserver = new IntersectionObserver((entries) => {
  entries.forEach((entry) => {
    if (!entry.isIntersecting || !sectionTargets.includes(entry.target.id)) return;
    dockLinks.forEach((link) => link.classList.toggle("dock-active", link.getAttribute("href") === `#${entry.target.id}`));
  });
}, { rootMargin: "-35% 0px -55% 0px" });
sectionTargets.forEach((id) => {
  const section = document.getElementById(id);
  if (section) sectionObserver.observe(section);
});

document.querySelectorAll(".property-tab").forEach((tab) => {
  tab.addEventListener("click", () => {
    document.querySelectorAll(".property-tab").forEach((item) => item.classList.remove("active"));
    tab.classList.add("active");
  });
});

document.querySelectorAll('a[href="#publier"]').forEach((link) => {
  link.addEventListener("click", () => {
    document.querySelector(".contact-form select[name='subject']").value = "Je souhaite proposer un bien";
  });
});