$(document).on("turbolinks:load", () => {
  $(".videoLink").click((click) => {
    var $videoSource = $(click.currentTarget).attr("src");
    $("iframe#video").attr("src", $videoSource + "?autoplay=1&rel=0");
  });

  // stop playing the youtube video when I close the modal
  $("#videoModal").on("hide.bs.modal", function (e) {
    // a poor man's stop video
    $("iframe#video").attr(
      "src",
      $("iframe#video").attr("src").replace("autoplay=1", "autoplay=0"),
    );
  });

  $('img[category="vimeo"]').each((i, image) => {
    const img = $(image);
    const embedUrl = "https://vimeo.com/api/oembed.json?url=";
    const vidUrl = "https://vimeo.com/" + img.attr("video_id");
    $.getJSON(embedUrl + encodeURI(vidUrl), function (data) {
      img.attr("src", data.thumbnail_url);
    });
  });
});
