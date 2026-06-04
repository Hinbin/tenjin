// Handles HTML responses from `@rails/ujs` `remote: true` links/forms:
//   - redirect       -> window.location.assign(responseURL)
//   - inline render  -> swap document.body (e.g. validation errors)
// Also tags `data-remote="true"` elements with `data-turbo="false"` so
// Turbo never double-handles submissions owned by UJS.

function handleAjaxSuccess(event) {
  const [data, , xhr] = event.detail;
  const contentType = xhr.getResponseHeader("Content-Type") || "";
  if (!contentType.includes("text/html")) return;

  // XHR auto-follows redirects, so xhr.status is always 200 here.
  // Detect a redirect by comparing the final URL to the originating element's URL.
  const target = event.target;
  const originalURL =
    target.href ||
    (target.action && new URL(target.action, document.baseURI).href);
  const wasRedirect =
    originalURL && xhr.responseURL && xhr.responseURL !== originalURL;

  if (wasRedirect) {
    window.location.assign(xhr.responseURL);
  } else {
    const html = typeof data === "string" ? data : xhr.responseText;
    const doc = new DOMParser().parseFromString(html, "text/html");
    document.body.replaceWith(doc.body);
    document.dispatchEvent(new CustomEvent("turbo:load"));
  }
}

function tagRemoteForms() {
  document.querySelectorAll('[data-remote="true"]').forEach((el) => {
    if (!el.hasAttribute("data-turbo")) el.setAttribute("data-turbo", "false");
  });
}

document.addEventListener("ajax:success", handleAjaxSuccess);
document.addEventListener("turbo:load", tagRemoteForms);
// Also run on initial DOMContentLoaded for the very first page load, since
// `turbo:load` fires on first navigation but not before turbo is installed.
document.addEventListener("DOMContentLoaded", tagRemoteForms);
