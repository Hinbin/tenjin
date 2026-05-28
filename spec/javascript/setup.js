// Make jQuery available globally, mirroring the webpack ProvidePlugin that does this in the browser.
const $ = require('jquery');
global.$ = $;
global.jQuery = $;

// Stub Turbolinks navigation (used in several app/ modules at load time).
global.Turbolinks = { visit: jest.fn() };
