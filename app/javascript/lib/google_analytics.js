document.addEventListener("turbo:load", (event) => {
  if (typeof gtag !== "function") return;
  const gaId = document.querySelector(
    'meta[name="google-analytics-id"]',
  )?.content;
  if (gaId) gtag("config", gaId, { page_location: event.detail?.url });
});
