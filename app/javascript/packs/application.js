// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.

import '../styles/application.scss'

import '@hotwired/turbo-rails'
import * as ActiveStorage from '@rails/activestorage'

import 'bootstrap'
import '@fortawesome/fontawesome-free/js/all'
import { Application } from 'stimulus'
import { definitionsFromContext } from 'stimulus/webpack-helpers'

import flatpickr from 'flatpickr'
import 'flatpickr/dist/flatpickr.min.css'
import Shepherd from 'shepherd.js'
import Cookies from 'js-cookie/src/js.cookie'


import './classroom'
import './homework'
import './pages'
import './schools'
import './student_dashboard'
import './teacher_dashboard'
import './users'
import './questions/multiple_choice_question'
import './questions/question_top'
import './questions/short_response_question'
import './questions/import_topic_questions'
import './lessons'
import './questions'
import './controller_info'
import './google_analytics'

ActiveStorage.start()

const images = require.context('../images', true)
const imagePath = (name) => images(name, true)

require('datatables.net-bs4')
require('datatables.net-buttons-bs4')
require('datatables.net-buttons/js/buttons.html5.js')
require('datetime-moment')
require('trix')
require('@rails/actioncable')

// Workaround for actiontext issue
require('@rails/actiontext')

$(document).on('turbo:load', function () {
  if ($('#notice').text().length) {
    $('#noticeModal').modal()
  }

  if ($('#alert').text().length) {
    $('#alertModal').modal()
  }
})

// Support component names relative to this directory:
var componentRequireContext = require.context('components', true)
var ReactRailsUJS = require('react_ujs')
ReactRailsUJS.useContext(componentRequireContext)

// Fix for leaderboard not loading
ReactRailsUJS.handleEvent('turbo:frame-load', ReactRailsUJS.handleMount)
ReactRailsUJS.handleEvent('turbo:frame-render', ReactRailsUJS.handleUnmount)
ReactRailsUJS.handleEvent('turbo:load', ReactRailsUJS.handleMount)
ReactRailsUJS.handleEvent('turbo:before-render', ReactRailsUJS.handleUnmount)

// Stimulus
const application = Application.start()
const context = require.context('./controllers', true, /\.js$/)
application.load(definitionsFromContext(context))

window.Shepherd = Shepherd
window.Cookies = Cookies

