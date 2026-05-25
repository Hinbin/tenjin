// Expose which controller and action are being run - replace over time with Stimulus
var Page;
var bind = function (fn, me) {
  return function () {
    return fn.apply(me, arguments);
  };
};
Page = (function () {
  function Page() {
    this.action = bind(this.action, this);
    this.controller = bind(this.controller, this);
  }
  Page.prototype.controller = function () {
    return document.querySelector("meta[name=psj]").getAttribute("controller");
  };
  Page.prototype.action = function () {
    return document.querySelector("meta[name=psj]").getAttribute("action");
  };
  return Page;
})();
window.page = new Page();
