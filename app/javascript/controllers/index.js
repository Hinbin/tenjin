import { application } from "controllers/application"

import AccordionController from "controllers/accordion_controller"
application.register("accordion", AccordionController)

import AlertController from "controllers/alert_controller"
application.register("alert", AlertController)

import CarouselController from "controllers/carousel_controller"
application.register("carousel", CarouselController)

import ClassroomController from "controllers/classroom_controller"
application.register("classroom", ClassroomController)

import DashboardController from "controllers/dashboard_controller"
application.register("dashboard", DashboardController)

import FormController from "controllers/form_controller"
application.register("form", FormController)

import HomeworkController from "controllers/homework_controller"
application.register("homework", HomeworkController)

import LiveLeaderboardController from "controllers/live_leaderboard_controller"
application.register("live-leaderboard", LiveLeaderboardController)

import ModalController from "controllers/modal_controller"
application.register("modal", ModalController)

import NavbarController from "controllers/navbar_controller"
application.register("navbar", NavbarController)

import QuizController from "controllers/quiz_controller"
application.register("quiz", QuizController)

import TableController from "controllers/table_controller"
application.register("table", TableController)

import ThemeController from "controllers/theme_controller"
application.register("theme", ThemeController)

import UsersController from "controllers/users_controller"
application.register("users", UsersController)
