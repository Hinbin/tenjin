// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.

import '../styles/application.scss'

import '@hotwired/turbo-rails'
import * as ActiveStorage from '@rails/activestorage'

import '@fortawesome/fontawesome-free/js/all'
import { Application } from '@hotwired/stimulus'
import { definitionsFromContext } from '@hotwired/stimulus-webpack-helpers'

import Shepherd from 'shepherd.js'
import Cookies from 'js-cookie'


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

require('trix')
require('@rails/actioncable')

// Workaround for actiontext issue
require('@rails/actiontext')

// Stimulus
const application = Application.start()
const context = require.context('./controllers', true, /\.js$/)
application.load(definitionsFromContext(context))

window.Shepherd = Shepherd
window.Cookies = Cookies
