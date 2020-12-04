// src/controllers/homework_controller.js
import { Controller } from "stimulus"

export default class extends Controller {
  static targets = ["lessonSelect"]
  
  loadLessons () {
    var topicID = $('#homework_topic_id').val()
    var options = $('.jsVars').data('lessons').filter((i) => { return i.topic_id == topicID })

    $(this.lessonSelectTarget).empty()

    $(this.lessonSelectTarget)
    .append($("<option></option>")
      .attr("value", null)
      .text(null));

    if (options.length) {
      options.forEach((i) => {
        $(this.lessonSelectTarget)
          .append($("<option></option>")
            .attr("value", i.id)
            .text(i.title));
      });

      this.lessonSelectTarget.disabled = false
    } else {
      this.lessonSelectTarget.disabled = true
    }

  }
}