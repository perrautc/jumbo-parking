defmodule JumboParkingWeb.Admin.DashboardLive do
  use JumboParkingWeb, :live_view

  alias JumboParking.Parking

  @impl true
  def mount(_params, _session, socket) do
    stats = Parking.dashboard_stats()
    recent_activities = Parking.list_recent_activities(10)
    recent_customers = Parking.recent_customers(5)

    socket =
      socket
      |> assign(:page_title, "Dashboard")
      |> assign(:active_tab, :dashboard)
      |> assign(:stats, stats)
      |> assign(:recent_activities, recent_activities)
      |> assign(:recent_customers, recent_customers)

    {:ok, socket, layout: {JumboParkingWeb.Layouts, :admin}}
  end

  defp format_revenue(cents) when is_integer(cents) do
    dollars = div(cents, 100)
    formatted = dollars |> Integer.to_string() |> format_number()
    "$#{formatted}"
  end

  defp format_revenue(_), do: "$0"

  defp format_number(str) when byte_size(str) <= 3, do: str
  defp format_number(str) do
    {prefix, suffix} = String.split_at(str, -3)
    format_number(prefix) <> "," <> suffix
  end

  defp time_ago(datetime) do
    diff = DateTime.diff(DateTime.utc_now(), datetime, :second)

    cond do
      diff < 60 -> "#{diff}s ago"
      diff < 3600 -> "#{div(diff, 60)}m ago"
      diff < 86400 -> "#{div(diff, 3600)}h ago"
      true -> "#{div(diff, 86400)}d ago"
    end
  end

  defp activity_color("customer_created"), do: "text-green-400"
  defp activity_color("space_assigned"), do: "text-[#c8d935]"
  defp activity_color("space_released"), do: "text-blue-400"
  defp activity_color("booking_created"), do: "text-purple-400"
  defp activity_color("customer_deleted"), do: "text-red-400"
  defp activity_color(_), do: "text-[#a0a0a0]"
end
