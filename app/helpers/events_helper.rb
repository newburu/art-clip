module EventsHelper
  def status_badge(status)
    color_classes = case status
    when "interested"
      "bg-yellow-100 text-yellow-800"
    when "going"
      "bg-green-100 text-green-800"
    when "went"
      "bg-gray-100 text-gray-800"
    else
      "bg-gray-100 text-gray-800"
    end

    tag.span t("activerecord.attributes.event.statuses.#{status}", default: status&.titleize || "Unknown"), class: "inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium #{color_classes}"
  end

  def google_calendar_url(event)
    if event.scheduled_date
      start_time = event.scheduled_date
      end_time = start_time + 2.hours
    elsif event.start_date && event.end_date
      start_time = event.start_date
      end_time = event.end_date
    else
      return
    end

    base_url = "https://www.google.com/calendar/render?action=TEMPLATE"
    params = {
      text: event.title,
      dates: "#{start_time.utc.strftime('%Y%m%dT%H%M%SZ')}/#{end_time.utc.strftime('%Y%m%dT%H%M%SZ')}",
      details: "#{event.url}\n\n#{event.description}",
      location: event.location
    }

    "#{base_url}&#{params.to_query}"
  end
end
