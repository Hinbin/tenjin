// src/controllers/dashboard_controller.js
import { Controller } from 'stimulus'

export default class extends Controller {
  initialize () {
    if (document.getElementById('oAuthEmail')) {
      const tour = new Shepherd.Tour({ useModalOverlay: true })
      tour.addStep({
        id: 'Link to Google',
        text: "Let's get your account linked to Google, so you don't have remember another username and password!  Click on your name",
        attachTo: {
          element: '#current_user',
          on: 'bottom'
        },
        buttons: [
          {
            text: 'Later',
            action: tour.cancel
          }
        ]
      })

      tour.start()
    }
  }
}
