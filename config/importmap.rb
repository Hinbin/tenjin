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

# Stimulus controllers
pin "controllers",                              to: "controllers/index.js"
pin "controllers/application",                  to: "controllers/application.js"
pin "controllers/accordion_controller",         to: "controllers/accordion_controller.js"
pin "controllers/alert_controller",             to: "controllers/alert_controller.js"
pin "controllers/carousel_controller",          to: "controllers/carousel_controller.js"
pin "controllers/classroom_controller",         to: "controllers/classroom_controller.js"
pin "controllers/dashboard_controller",         to: "controllers/dashboard_controller.js"
pin "controllers/form_controller",              to: "controllers/form_controller.js"
pin "controllers/homework_controller",          to: "controllers/homework_controller.js"
pin "controllers/lesson_filter_controller",     to: "controllers/lesson_filter_controller.js"
pin "controllers/live_leaderboard_controller",  to: "controllers/live_leaderboard_controller.js"
pin "controllers/modal_controller",             to: "controllers/modal_controller.js"
pin "controllers/motion_controller",            to: "controllers/motion_controller.js"
pin "controllers/navbar_controller",            to: "controllers/navbar_controller.js"
pin "controllers/question_builder_controller",  to: "controllers/question_builder_controller.js"
pin "controllers/quiz_controller",              to: "controllers/quiz_controller.js"
pin "controllers/table_controller",             to: "controllers/table_controller.js"
pin "controllers/theme_controller",             to: "controllers/theme_controller.js"
pin "controllers/users_controller",             to: "controllers/users_controller.js"

# Local JS modules (pinned so importmap resolves digested URLs, avoiding bare relative imports)
pin "controller_info",                      to: "controller_info.js"
pin "classroom",                            to: "classroom.js"
pin "homework",                             to: "homework.js"
pin "pages",                                to: "pages.js"
pin "schools",                              to: "schools.js"
pin "student_dashboard",                    to: "student_dashboard.js"
pin "teacher_dashboard",                    to: "teacher_dashboard.js"
pin "users",                                to: "users.js"
pin "lessons",                              to: "lessons.js"
pin "app_questions",                        to: "questions.js"
pin "google_analytics",                     to: "google_analytics.js"
pin "questions/multiple_choice_question",   to: "questions/multiple_choice_question.js"
pin "questions/question_top",               to: "questions/question_top.js"
pin "questions/short_response_question",    to: "questions/short_response_question.js"
pin "questions/drag_drop_question",         to: "questions/drag_drop_question.js"
pin "questions/matrix_question",            to: "questions/matrix_question.js"
pin "questions/fill_blank_question",        to: "questions/fill_blank_question.js"
pin "questions/ordering_question",          to: "questions/ordering_question.js"
pin "questions/import_topic_questions",     to: "questions/import_topic_questions.js"
pin "questions/questions_shared",           to: "questions/questions_shared.js"
pin "questions/touch_drag",                 to: "questions/touch_drag.js"
pin "channels/consumer",                    to: "channels/consumer.js"
