# frozen_string_literal: true

module SchoolsHelper
  SYNC_STATUS_ICONS = {
    "queued" => ["fas fa-clock", nil],
    "syncing" => ["fas fa-sync", nil],
    "successful" => ["fas fa-check", "color:green"],
    "failed" => ["fas fa-times", "color:red"],
    "needed" => ["fas fa-exclamation-triangle", "color:red"]
  }.freeze

  def sync_status_icon(status)
    icon_class, style = SYNC_STATUS_ICONS.fetch(status, ["fas fa-question", "color:red"])
    content_tag(:i, nil, class: icon_class, style: style)
  end
end
