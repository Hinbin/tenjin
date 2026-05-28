$(document).on("turbolinks:load", () => {
  $(".challenge-row, .homework-row").off("click");

  $(".challenge-row, .homework-row").click(function (event) {
    const pickedSubject = $(event.currentTarget).data("subject");
    const pickedTopic = $(event.currentTarget).data("topic");
    const pickedLesson = $(event.currentTarget).data("lesson");
    $(event.currentTarget).prop("disabled", true);

    $.ajax({
      type: "post",
      url: "/quizzes",
      data: {
        quiz: {
          subject: pickedSubject,
          topic_id: pickedTopic,
          lesson_id: pickedLesson,
        },
      },
      beforeSend: function (xhr) {
        xhr.setRequestHeader(
          "X-CSRF-Token",
          $('meta[name="csrf-token"]').attr("content"),
        );
      },
      success: function (data) {
        Turbolinks.visit("/quizzes");
      },
    });
  });
});
