// Teacher dashboard classroom row navigation.
// The otherClassroomTable now uses table_controller.js (no DataTables).
document.addEventListener('turbo:load', () => {
  document.querySelectorAll('tr[data-classroom]').forEach(tr => {
    tr.addEventListener('click', (event) => {
      if (event.target.closest('.btn')) return
      const classroomId = tr.dataset.classroom
      if (classroomId) Turbo.visit('/classrooms/' + classroomId)
    })
  })
})
