import { application } from "./application"

import AccordionController from "./accordion_controller"
application.register("accordion", AccordionController)

import AlertController from "./alert_controller"
application.register("alert", AlertController)

import CarouselController from "./carousel_controller"
application.register("carousel", CarouselController)

import ClassroomController from "./classroom_controller"
application.register("classroom", ClassroomController)

import DashboardController from "./dashboard_controller"
application.register("dashboard", DashboardController)

import FormController from "./form_controller"
application.register("form", FormController)

import HomeworkController from "./homework_controller"
application.register("homework", HomeworkController)

import LiveLeaderboardController from "./live_leaderboard_controller"
application.register("live-leaderboard", LiveLeaderboardController)

import ModalController from "./modal_controller"
application.register("modal", ModalController)

import NavbarController from "./navbar_controller"
application.register("navbar", NavbarController)

import TableController from "./table_controller"
application.register("table", TableController)

import UsersController from "./users_controller"
application.register("users", UsersController)
