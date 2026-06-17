# Pin npm packages by running ./bin/importmap

pin "application"

# Hotwire
pin "@hotwired/turbo-rails", to: "turbo.js"
pin "@hotwired/stimulus", to: "@hotwired--stimulus.js" # @3.2.2

# Rails JS libraries (served from gems via Propshaft)
pin "@rails/actioncable",    to: "actioncable.esm.js"
pin "@rails/activestorage",  to: "activestorage.esm.js"
pin "@rails/actiontext",     to: "actiontext.esm.js"
pin "trix"

# Vendor (downloaded/vendored)
pin "shepherd.js", to: "shepherd.js"

# Local JS modules — pinned so importmap resolves them as bare specifiers
pin "controllers",                              to: "controllers/index.js"
pin "controllers/application",                  to: "controllers/application.js"
pin "controllers/accordion_controller",         to: "controllers/accordion_controller.js"
pin "controllers/alert_controller",             to: "controllers/alert_controller.js"
pin "controllers/carousel_controller",          to: "controllers/carousel_controller.js"
pin "controllers/classroom_controller",         to: "controllers/classroom_controller.js"
pin "controllers/dashboard_controller",         to: "controllers/dashboard_controller.js"
pin "controllers/form_controller",              to: "controllers/form_controller.js"
pin "controllers/homework_controller",          to: "controllers/homework_controller.js"
pin "controllers/live_leaderboard_controller",  to: "controllers/live_leaderboard_controller.js"
pin "controllers/modal_controller",             to: "controllers/modal_controller.js"
pin "controllers/navbar_controller",            to: "controllers/navbar_controller.js"
pin "controllers/table_controller",             to: "controllers/table_controller.js"
pin "controllers/users_controller",             to: "controllers/users_controller.js"
