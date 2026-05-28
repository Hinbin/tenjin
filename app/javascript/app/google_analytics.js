document.addEventListener("turbolinks:load", function (event) {
  if (typeof gtag === "function") {
    const gaId = document.querySelector('meta[name="google-analytics-id"]')
      ?.content;
    if (gaId) {
      gtag("config", gaId, {
        page_location: event.data.url,
      });
    }
  }
});
