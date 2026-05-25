import updateQuizStatistics from "app/questions/questions_shared";

function processShortResponse(serverResponse, guess) {
  const results = serverResponse.answer;
  let correct = false;

  for (var result of results) {
    if (result.text.toUpperCase() === guess.toUpperCase()) {
      $("#shortAnswerButton").addClass("correct-answer");
      $("#shortAnswerButton").text("Correct!");
      $("#shortAnswerButton").append(
        '<i class="fas fa-check fa-lg float-right my-1"></i>',
      );
      correct = true;
    }
  }

  if (!correct && results[0]) {
    $("#shortAnswerButton").addClass("incorrect-answer");
    $("#shortAnswerButton").text("Incorrect");
    $("#shortAnswerButton").append(
      '<i class="fas fa-times fa-lg float-right my-1"></i>',
    );

    $("#shortAnswerText").addClass("correct-answer");
    if (results.length === 1) {
      $("#shortAnswerText").val(results[0].text);
    } else {
      const correctAnswerText = results.map((r) => r.text).join(" or ");
      $("#shortAnswerText").val(correctAnswerText);
    }
  }

  updateQuizStatistics(serverResponse);

  $("#nextButton").removeClass("invisible");
  $("#nextButton").focus();
}

$(document).on("turbolinks:load", function () {
  // If someone presses enter, cause the submit answer button to be pressed
  $("#shortAnswerText").keypress((e) => {
    if (e.keyCode === 13) {
      $("#shortAnswerButton").click();
    }
  });

  $("#shortAnswerButton").click((click) => {
    $("#shortAnswerButton").attr("disabled", "disabled");
    $("#shortAnswerText").attr("disabled", "disabled");

    $.ajax({
      type: "PUT",
      url: window.location.pathname,
      beforeSend: function (xhr) {
        xhr.setRequestHeader(
          "X-CSRF-Token",
          $('meta[name="csrf-token"]').attr("content"),
        );
      },
      success: (result) =>
        processShortResponse(result, $("#shortAnswerText").val()),
      data: {
        answer: {
          short_answer: $("#shortAnswerText").val(),
        },
      },
    });
  });
});
