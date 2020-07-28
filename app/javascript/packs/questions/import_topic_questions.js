
$(document).on('turbolinks:load', function () {
  if (page.controller() === 'questions' && page.action() === 'import_topic_questions') {
    document.querySelector('.custom-file-input').addEventListener('change', function (e) {
      var fileName = document.getElementById('select-file').files[0].name
      var nextSibling = e.target.nextElementSibling
      nextSibling.innerText = fileName
    })
  }
})
