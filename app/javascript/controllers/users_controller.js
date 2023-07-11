// src/controllers/users_controller.js
import { Controller } from 'stimulus'

export default class extends Controller {
  initialize () {
    if (document.getElementById('loginGoogle')) {
      const tour = new Shepherd.Tour({ useModalOverlay: true })
      tour.addStep({
        id: 'Click Login Google',
        text: "Click on this button, login and you're done!",
        attachTo: {
          element: '#loginGoogle',
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
