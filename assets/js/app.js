import "phoenix_html"
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"

// JS Hooks
const Hooks = {}

// Scroll-triggered animations via IntersectionObserver
Hooks.ScrollAnimate = {
  mounted() {
    this.setupObserver()
  },
  updated() {
    // Re-observe any new scroll-reveal elements after LiveView patches
    this.setupObserver()
  },
  setupObserver() {
    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            entry.target.classList.add("revealed")
            observer.unobserve(entry.target)
          }
        })
      },
      { threshold: 0.1 }
    )

    this.el.querySelectorAll(".scroll-reveal:not(.revealed)").forEach((el) => {
      observer.observe(el)
    })
  }
}

// Sticky header with scroll-based background
Hooks.StickyHeader = {
  mounted() {
    const header = this.el
    const onScroll = () => {
      if (window.scrollY > 50) {
        header.classList.add("header-scrolled")
        header.classList.remove("bg-transparent")
      } else {
        header.classList.remove("header-scrolled")
        header.classList.add("bg-transparent")
      }
    }
    window.addEventListener("scroll", onScroll, { passive: true })
    this.cleanup = () => window.removeEventListener("scroll", onScroll)
    // Run once on mount
    onScroll()
  },
  destroyed() {
    if (this.cleanup) this.cleanup()
  }
}

// Auto-rotate testimonials carousel
Hooks.AutoRotateTestimonials = {
  mounted() {
    this.interval = setInterval(() => {
      this.pushEvent("next_testimonial", {})
    }, 5000)
  },
  destroyed() {
    clearInterval(this.interval)
  }
}

const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
const liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken},
  hooks: Hooks,
})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#c8d935"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

window.liveSocket = liveSocket
