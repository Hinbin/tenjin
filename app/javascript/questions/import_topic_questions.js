// turbo:load wrapper removed — was the only jQuery usage.
// The custom-file-input listener is vanilla; no changes needed to the inner code.
document.addEventListener('turbo:load', () => {
  if (page.controller() !== 'questions' || page.action() !== 'import_topic_questions') return

  document.querySelector('.custom-file-input')?.addEventListener('change', function (e) {
    const fileName = document.getElementById('select-file').files[0].name
    const nextSibling = e.target.nextElementSibling
    if (nextSibling) nextSibling.innerText = fileName
  })
})
