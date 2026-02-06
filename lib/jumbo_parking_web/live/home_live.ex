defmodule JumboParkingWeb.HomeLive do
  use JumboParkingWeb, :live_view

  alias JumboParking.Parking

  @testimonials [
    %{
      name: "Mike Richardson",
      role: "Fleet Manager",
      company: "Richardson Transport",
      quote: "Jumbo Parking has been a game-changer for our trucking business. The 24/7 access and security give us peace of mind.",
      image: "testimonial-1.jpg"
    },
    %{
      name: "Sarah Johnson",
      role: "Operations Director",
      company: "Columbia Logistics",
      quote: "The loading docks and laydown yards make transferring cargo so much easier. Best parking facility in Columbia!",
      image: "testimonial-2.jpg"
    },
    %{
      name: "David Miller",
      role: "RV Owner",
      company: "",
      quote: "We've been storing our RV here for years. The staff is always helpful and the facility is always clean and secure.",
      image: "testimonial-3.jpg"
    }
  ]

  @impl true
  def mount(_params, _session, socket) do
    pricing_plans = Parking.list_pricing_plans()
    merch_items = Parking.list_active_merch_items()
    merch_enabled = Parking.get_setting_bool("merch_store_enabled")

    socket =
      socket
      |> assign(:page_title, "Secure Parking & Storage Solutions")
      |> assign(:pricing_plans, pricing_plans)
      |> assign(:selected_vehicle, "truck")
      |> assign(:testimonial_index, 0)
      |> assign(:testimonials, @testimonials)
      |> assign(:merch_items, merch_items)
      |> assign(:merch_enabled, merch_enabled)
      |> assign(:mobile_menu_open, false)

    {:ok, socket}
  end

  @impl true
  def handle_event("toggle_mobile_menu", _params, socket) do
    {:noreply, assign(socket, :mobile_menu_open, !socket.assigns.mobile_menu_open)}
  end

  @impl true
  def handle_event("close_mobile_menu", _params, socket) do
    {:noreply, assign(socket, :mobile_menu_open, false)}
  end

  @impl true
  def handle_event("select_vehicle", %{"type" => type}, socket) do
    {:noreply, assign(socket, :selected_vehicle, type)}
  end

  @impl true
  def handle_event("next_testimonial", _params, socket) do
    next = rem(socket.assigns.testimonial_index + 1, length(@testimonials))
    {:noreply, assign(socket, :testimonial_index, next)}
  end

  @impl true
  def handle_event("prev_testimonial", _params, socket) do
    prev = rem(socket.assigns.testimonial_index - 1 + length(@testimonials), length(@testimonials))
    {:noreply, assign(socket, :testimonial_index, prev)}
  end

  @impl true
  def handle_event("goto_testimonial", %{"index" => index}, socket) do
    {:noreply, assign(socket, :testimonial_index, String.to_integer(index))}
  end

  defp get_plan_for_vehicle(plans, vehicle_type) do
    Enum.find(plans, fn p -> p.vehicle_type == vehicle_type end)
  end

  defp format_price(nil), do: "$0"
  defp format_price(cents) when is_integer(cents), do: "$#{div(cents, 100)}"

  defp monthly_equivalent(yearly_cents) when is_integer(yearly_cents) do
    "$#{div(div(yearly_cents, 12), 100)}"
  end

  defp monthly_equivalent(_), do: "$0"

  defp format_merch_price(nil), do: "$0"
  defp format_merch_price(cents) when is_integer(cents), do: "$#{:erlang.float_to_binary(cents / 100, decimals: 2)}"
  defp format_merch_price(_), do: "$0"
end
