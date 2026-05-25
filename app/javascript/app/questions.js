$(document).on("turbolinks:load", () => {
  if (page.controller() === "questions") {
    if (!$.fn.dataTable.isDataTable("#questionTable")) {
      $("#questionTable").DataTable({
        pageLength: 50,
        language: {
          emptyTable: "No questions have been found",
        },
      });
    }

    $(".save-question-text").on("trix-blur", (event) => {
      saveQuestionText(() => {});
    });

    $(".check-and-save").click((event) => {
      const paths = $(event.target).data();
      validateAndSave(() => {
        Turbolinks.visit(paths["redirect"]);
      }, paths["update"]);
    });

    $(".reload-page").on("change", (target) => {
      const currentPath = window.location.href.split("?")[0];
      $("input[name=authenticity_token").remove();
      const form = $("#questionForm");
      const formParams = form.serialize();
      Turbolinks.visit(currentPath + "?" + formParams);
    });

    $("form").on("click", ".remove-row", function (event) {
      $(this).prev("input[type=hidden]").val("1");
      $(this).closest("tr").hide();
      $(this).closest("tr").remove();
      return event.preventDefault();
    });

    $("form").on("click", ".remove-record", function (event) {
      event.preventDefault();
      const form = this.closest("form");
      const hiddenInput = document.createElement("input");
      hiddenInput.type = "hidden";
      hiddenInput.name = `${this.dataset.objectName}[_destroy]`;
      hiddenInput.value = "true";
      form.appendChild(hiddenInput);
      form.submit();
    });

    $("form").on("click", ".add_fields", function (event) {
      var regexp, time;
      time = new Date().getTime();
      regexp = new RegExp($(this).data("id"), "g");
      $(".fields").append($(this).data("fields").replace(regexp, time));
      return event.preventDefault();
    });
  }
});

$(document).on("turbolinks:before-cache", () => {
  $("#questionTable").DataTable().destroy();
});

function validateAndSave(successCallback, updatePath) {
  const correctAnswers = $("input[checked=checked]");

  // If not answers have been selected as correct, and we're trying to save...
  if (
    correctAnswers.length === 0 &&
    $("#questionTypeSelect").val() !== "short_answer"
  ) {
    // Alert the user and do not save.
    $("#noCorrectAnswerModal").modal();
  } else {
    // Else save the question text and return
    saveQuestionText(successCallback, updatePath);
  }
}

function saveQuestionText(successCallback, updatePath) {
  const questionText = $("#question_question_text").val();

  $.ajax({
    type: "put",
    url: updatePath,
    beforeSend: function (xhr) {
      xhr.setRequestHeader(
        "X-CSRF-Token",
        $('meta[name="csrf-token"]').attr("content"),
      );
    },
    data: { question: { question_text: questionText } },
    success: successCallback(),
  });
}
