import { application } from "./application.js"

import AccordionController from "./accordion_controller.js"
application.register("accordion", AccordionController)

import AlertController from "./alert_controller.js"
application.register("alert", AlertController)

import CarouselController from "./carousel_controller.js"
application.register("carousel", CarouselController)

import ClassroomController from "./classroom_controller.js"
application.register("classroom", ClassroomController)

import DashboardController from "./dashboard_controller.js"
application.register("dashboard", DashboardController)

import FormController from "./form_controller.js"
application.register("form", FormController)

import HomeworkController from "./homework_controller.js"
application.register("homework", HomeworkController)

import LiveLeaderboardController from "./live_leaderboard_controller.js"
application.register("live-leaderboard", LiveLeaderboardController)

import ModalController from "./modal_controller.js"
application.register("modal", ModalController)

import NavbarController from "./navbar_controller.js"
application.register("navbar", NavbarController)

import TableController from "./table_controller.js"
application.register("table", TableController)

import UsersController from "./users_controller.js"
application.register("users", UsersController)
