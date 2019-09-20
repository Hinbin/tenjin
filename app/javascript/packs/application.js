/* eslint no-console:0 */
// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.
//
// To reference this file, add <%= javascript_pack_tag 'application' %> to the appropriate
// layout file, like app/views/layouts/application.html.erb

// Uncomment to copy all static images under ../images to the output folder and reference
// them with the image_pack_tag helper in views (e.g <%= image_pack_tag 'rails.png' %>)
// or the `imagePath` JavaScript helper below.
//
// const images = require.context('../images', true)
// const imagePath = (name) => images(name, true)

import flatpickr from 'flatpickr'
import 'flatpickr/dist/flatpickr.min.css'

var dt_extras = [

  require('datatables.net-bs4'),
  require('datatables.net-buttons-bs4'),
  require('datatables.net-buttons/js/buttons.html5.js')
]

dt_extras.forEach(function (e) { e(window, $) })

require('trix')
require('@rails/actiontext')

$(document).on('turbolinks:load', function () {
  if ($('#notice').text().length) {
    $('#noticeModal').modal()
  }

  if ($('#alert').text().length) {
    $('#alertModal').modal()
  }
})
// Support component names relative to this directory:
var componentRequireContext = require.context("components", true);
var ReactRailsUJS = require("react_ujs");
ReactRailsUJS.useContext(componentRequireContext);
