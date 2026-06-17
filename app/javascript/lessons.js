document.addEventListener('turbo:load', () => {
  // Video trigger: any .videoLink element opens the video modal using its src attribute
  document.querySelectorAll('.videoLink[src]').forEach(trigger => {
    trigger.style.cursor = 'pointer'
    trigger.addEventListener('click', () => {
      const dialog = document.getElementById('videoModal')
      const iframe = document.getElementById('video')
      if (iframe) iframe.src = trigger.getAttribute('src') + '?autoplay=1&rel=0'
      if (dialog) dialog.showModal()
    })
  })

  // Stop video when the dialog closes
  const videoDialog = document.getElementById('videoModal')
  if (videoDialog) {
    videoDialog.addEventListener('close', () => {
      const iframe = document.getElementById('video')
      if (iframe) iframe.src = iframe.src.replace('autoplay=1', 'autoplay=0')
    })
  }

  // Fetch Vimeo thumbnails for any img with a video_id attribute
  document.querySelectorAll('img[video_id][category="vimeo"]').forEach(image => {
    const embedUrl = 'https://vimeo.com/api/oembed.json?url='
    const vidUrl = 'https://vimeo.com/' + image.getAttribute('video_id')
    fetch(embedUrl + encodeURIComponent(vidUrl))
      .then(r => r.json())
      .then(data => { image.src = data.thumbnail_url })
      .catch(() => {})
  })
})
