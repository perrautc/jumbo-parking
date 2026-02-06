defmodule JumboParkingWeb.ParkingComponents do
  @moduledoc """
  Reusable UI components for the Jumbo Parking application.
  """
  use Phoenix.Component
  use Phoenix.VerifiedRoutes, endpoint: JumboParkingWeb.Endpoint, router: JumboParkingWeb.Router

  alias Phoenix.LiveView.JS

  # ── Admin Navigation Link ────────────────────────────────

  attr :href, :string, required: true
  attr :icon, :string, required: true
  attr :label, :string, required: true
  attr :active, :boolean, default: false

  def admin_nav_link(assigns) do
    ~H"""
    <a
      href={@href}
      class={"flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm transition-colors #{if @active, do: "bg-[#c8d935]/10 text-[#c8d935]", else: "text-[#a0a0a0] hover:bg-white/5 hover:text-white"}"}
    >
      <.nav_icon name={@icon} />
      <span>{@label}</span>
    </a>
    """
  end

  defp nav_icon(%{name: "chart-bar"} = assigns) do
    ~H"""
    <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
    </svg>
    """
  end

  defp nav_icon(%{name: "users"} = assigns) do
    ~H"""
    <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z" />
    </svg>
    """
  end

  defp nav_icon(%{name: "squares-2x2"} = assigns) do
    ~H"""
    <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2V6zM14 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2V6zM4 16a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2v-2zM14 16a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2v-2z" />
    </svg>
    """
  end

  defp nav_icon(%{name: "currency-dollar"} = assigns) do
    ~H"""
    <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
    </svg>
    """
  end

  defp nav_icon(assigns) do
    ~H"""
    <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16" />
    </svg>
    """
  end

  # ── Stat Card ─────────────────────────────────────────────

  attr :title, :string, required: true
  attr :value, :string, required: true
  attr :icon, :string, default: nil
  attr :trend, :string, default: nil
  attr :trend_label, :string, default: nil
  attr :color, :string, default: "yellow"

  def stat_card(assigns) do
    ~H"""
    <div class="bg-[#1a1a1a] border border-[#333333] rounded-xl p-6 hover:border-[#c8d935]/30 transition-colors">
      <div class="flex items-start justify-between">
        <div>
          <p class="text-[#a0a0a0] text-sm">{@title}</p>
          <p class="text-2xl font-bold text-white mt-1">{@value}</p>
          <p :if={@trend} class={"text-sm mt-2 #{if String.starts_with?(@trend, "+"), do: "text-green-400", else: "text-red-400"}"}>
            {@trend} <span class="text-[#a0a0a0]">{@trend_label}</span>
          </p>
        </div>
        <div class={"w-12 h-12 rounded-lg flex items-center justify-center #{color_bg(@color)}"}>
          <.stat_icon name={@icon} />
        </div>
      </div>
    </div>
    """
  end

  defp color_bg("yellow"), do: "bg-[#c8d935]/10 text-[#c8d935]"
  defp color_bg("blue"), do: "bg-blue-500/10 text-blue-400"
  defp color_bg("green"), do: "bg-green-500/10 text-green-400"
  defp color_bg("purple"), do: "bg-purple-500/10 text-purple-400"
  defp color_bg(_), do: "bg-[#c8d935]/10 text-[#c8d935]"

  defp stat_icon(%{name: "spaces"} = assigns) do
    ~H"""
    <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" />
    </svg>
    """
  end

  defp stat_icon(%{name: "customers"} = assigns) do
    ~H"""
    <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
    </svg>
    """
  end

  defp stat_icon(%{name: "occupancy"} = assigns) do
    ~H"""
    <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 3.055A9.001 9.001 0 1020.945 13H11V3.055z" />
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20.488 9H15V3.512A9.025 9.025 0 0120.488 9z" />
    </svg>
    """
  end

  defp stat_icon(%{name: "revenue"} = assigns) do
    ~H"""
    <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
    </svg>
    """
  end

  defp stat_icon(assigns) do
    ~H"""
    <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6" />
    </svg>
    """
  end

  # ── Status Badge ──────────────────────────────────────────

  attr :status, :string, required: true

  def status_badge(assigns) do
    ~H"""
    <span class={"inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium #{status_color(@status)}"}>
      {@status |> to_string() |> String.capitalize()}
    </span>
    """
  end

  defp status_color("active"), do: "bg-green-500/10 text-green-400"
  defp status_color("pending"), do: "bg-yellow-500/10 text-yellow-400"
  defp status_color("inactive"), do: "bg-red-500/10 text-red-400"
  defp status_color("available"), do: "bg-green-500/10 text-green-400"
  defp status_color("occupied"), do: "bg-[#c8d935]/10 text-[#c8d935]"
  defp status_color("reserved"), do: "bg-blue-500/10 text-blue-400"
  defp status_color("maintenance"), do: "bg-gray-500/10 text-gray-400"
  defp status_color("confirmed"), do: "bg-green-500/10 text-green-400"
  defp status_color("cancelled"), do: "bg-red-500/10 text-red-400"
  defp status_color(_), do: "bg-gray-500/10 text-gray-400"

  # ── Plan Badge ────────────────────────────────────────────

  attr :plan, :string, required: true

  def plan_badge(assigns) do
    ~H"""
    <span class={"inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium #{plan_color(@plan)}"}>
      {@plan |> to_string() |> String.capitalize()}
    </span>
    """
  end

  defp plan_color("yearly"), do: "bg-purple-500/10 text-purple-400"
  defp plan_color("monthly"), do: "bg-blue-500/10 text-blue-400"
  defp plan_color("weekly"), do: "bg-green-500/10 text-green-400"
  defp plan_color("daily"), do: "bg-yellow-500/10 text-yellow-400"
  defp plan_color(_), do: "bg-gray-500/10 text-gray-400"

  # ── Progress Bar ──────────────────────────────────────────

  attr :value, :integer, required: true
  attr :max, :integer, required: true
  attr :color, :string, default: "#c8d935"
  attr :label, :string, default: nil

  def progress_bar(assigns) do
    assigns = assign(assigns, :percentage, if(assigns.max > 0, do: round(assigns.value / assigns.max * 100), else: 0))

    ~H"""
    <div>
      <div :if={@label} class="flex justify-between text-sm mb-1">
        <span class="text-[#a0a0a0]">{@label}</span>
        <span class="text-white">{@value}/{@max}</span>
      </div>
      <div class="w-full bg-[#333333] rounded-full h-2">
        <div class="h-2 rounded-full transition-all duration-500" style={"width: #{@percentage}%; background-color: #{@color}"}></div>
      </div>
    </div>
    """
  end

  # ── Modal ─────────────────────────────────────────────────

  attr :id, :string, required: true
  attr :show, :boolean, default: false
  attr :on_cancel, JS, default: %JS{}
  slot :inner_block, required: true

  def modal(assigns) do
    ~H"""
    <div
      :if={@show}
      id={@id}
      phx-mounted={JS.show(transition: {"ease-out duration-200", "opacity-0", "opacity-100"})}
      class="fixed inset-0 z-50 flex items-center justify-center p-4"
    >
      <div class="fixed inset-0 bg-black/60 backdrop-blur-sm" phx-click={@on_cancel}></div>
      <div class="relative bg-[#1a1a1a] border border-[#333333] rounded-2xl shadow-2xl max-w-lg w-full max-h-[90vh] overflow-y-auto">
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  # ── Vehicle Type Icon ─────────────────────────────────────

  attr :type, :string, required: true
  attr :class, :string, default: "h-5 w-5"

  def vehicle_icon(assigns) do
    ~H"""
    <svg xmlns="http://www.w3.org/2000/svg" class={@class} fill="none" viewBox="0 0 24 24" stroke="currentColor">
      <path :if={@type == "truck"} stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 17a2 2 0 002-2H4a2 2 0 002 2m2 0a2 2 0 104 0m-6 0H4m12 0a2 2 0 002-2V9a2 2 0 00-2-2h-3l-2-3H7L5 7H2a2 2 0 00-2 2v6a2 2 0 002 2m14 0a2 2 0 104 0m-4 0h4" />
      <path :if={@type == "rv"} stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" />
      <path :if={@type == "car"} stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 17a2 2 0 11-4 0 2 2 0 014 0zM19 17a2 2 0 11-4 0 2 2 0 014 0z M13 16V6a1 1 0 00-1-1H4a1 1 0 00-1 1v10m10 0H3m10 0h4m0 0a1 1 0 001-1v-4l-3-4h-4" />
    </svg>
    """
  end
end
