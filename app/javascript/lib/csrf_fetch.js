export default function csrfFetch(url, options = {}) {
  const token = document.querySelector('meta[name="csrf-token"]')?.content;
  return fetch(url, {
    ...options,
    headers: {
      "Content-Type": "application/json",
      Accept: "application/json",
      "X-CSRF-Token": token,
      "X-Requested-With": "XMLHttpRequest",
      ...(options.headers || {}),
    },
  });
}
