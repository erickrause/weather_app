import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="sidebar"
export default class extends Controller {
  connect() {
  }

  hide() {
    const sidebar = document.getElementById("sidebar")
    if (sidebar) {
      sidebar.classList.add("hidden")
    }
  }

  show() {
    const sidebar = document.getElementById("sidebar")
    if (sidebar) {
      sidebar.classList.remove("hidden")
    }
  }
}
