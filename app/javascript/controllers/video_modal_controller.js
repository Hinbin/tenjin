import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["iframe", "modal", "vimeo"];

  connect() {
    this.vimeoTargets.forEach((img) => this._loadVimeoThumbnail(img));
    this.modalHandler = () => this._stopVideo();
    this.modalTarget.addEventListener("hide.bs.modal", this.modalHandler);
  }

  disconnect() {
    this.modalTarget.removeEventListener("hide.bs.modal", this.modalHandler);
  }

  open(event) {
    this.iframeTarget.src =
      event.currentTarget.getAttribute("src") + "?autoplay=1&rel=0";
  }

  _stopVideo() {
    this.iframeTarget.src = this.iframeTarget.src.replace(
      "autoplay=1",
      "autoplay=0",
    );
  }

  async _loadVimeoThumbnail(img) {
    const vidUrl = "https://vimeo.com/" + img.getAttribute("video_id");
    const res = await fetch(
      "https://vimeo.com/api/oembed.json?url=" + encodeURI(vidUrl),
    );
    if (res.ok) img.src = (await res.json()).thumbnail_url;
  }
}
