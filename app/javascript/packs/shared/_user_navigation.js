$(document).ready( () => {
  "use strict"; // Start of use strict
  // Collapse Navbar
  var navbarCollapse = function() {
    if ($("#navbar-main").offset().top > 0) {
      $("#navbar-main").addClass("collapsed");
    } else {
      $("#navbar-main").removeClass("collapsed");
    }
  };
  // Collapse now if page is not at top
  navbarCollapse();
  // Collapse the navbar when page is scrolled
  $(window).scroll(navbarCollapse);
});
