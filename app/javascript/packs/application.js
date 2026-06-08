// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.

import "../styles/application.scss";

import { Turbo } from "@hotwired/turbo-rails";
// Turbo Streams + ActionCable are wanted, but Drive is off — full-page
// navigations remain classic browser navigations. Forms/links opt-in to
// Turbo per element via data-turbo="true".
Turbo.session.drive = false;
import * as ActiveStorage from "@rails/activestorage";
import "bootstrap";
import { Application } from "@hotwired/stimulus";
import { definitionsFromContext } from "@hotwired/stimulus-webpack-helpers";

import flatpickr from "flatpickr";
import "flatpickr/dist/flatpickr.min.css";

import "../lib/live_leaderboard";
import "../lib/google_analytics";

ActiveStorage.start();

const images = require.context("../images", true);
const imagePath = (name) => images(name, true);

import "tabulator-tables/dist/css/tabulator_bootstrap5.min.css";

require("trix");
import "@rails/actiontext";
import "@rails/actioncable";

// Stimulus
const application = Application.start();
const context = require.context("controllers", true, /\.js$/);
application.load(definitionsFromContext(context));

import Alpine from "alpinejs";
window.Alpine = Alpine;
Alpine.start();
