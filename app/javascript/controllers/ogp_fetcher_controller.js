import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["url", "title", "image"]

  connect() {
  }

  fetch(event) {
    event.preventDefault()
    const url = this.urlTarget.value
    if (!url) return

    // Show loading state if needed, e.g. disable button
    event.currentTarget.disabled = true
    event.currentTarget.textContent = "Fetching..."

    fetch(`/events/fetch_ogp?url=${encodeURIComponent(url)}`)
      .then(response => {
        if (!response.ok) throw new Error("Network response was not ok")
        return response.json()
      })
      .then(data => {
        if (data.title) this.titleTarget.value = data.title
        if (data.image) this.imageTarget.value = data.image
      })
      .catch(error => {
        console.error("Error fetching OGP:", error)
        alert("Failed to fetch OGP data. Please check the URL.")
      })
      .finally(() => {
        event.currentTarget.disabled = false
        event.currentTarget.textContent = "Get Info"
      })
  }
}
