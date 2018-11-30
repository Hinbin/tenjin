$(document).ready( () => {
  "use strict"; // Start of use strict

  // Collapse Navbar
  var triggerBackground = function() {
    if ($("#navbar-main").offset().top > 0) {
      $("#navbar-main").addClass("bg-black");
    } else {
      $("#navbar-main").removeClass("bg-black");
    }
  };
  // Collapse now if page is not at top
  triggerBackground();
  // Collapse the navbar when page is scrolled
  $(window).scroll(triggerBackground);
});
