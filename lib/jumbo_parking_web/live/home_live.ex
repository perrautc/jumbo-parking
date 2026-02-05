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

  @merch_items [
    %{
      name: "Classic Logo Tee",
      description: "Premium black cotton t-shirt with the Jumbo Parking logo front and center.",
      price: "$29.99",
      image: "merch-tshirt.png",
      badge: "Popular"
    },
    %{
      name: "Snapback Hat",
      description: "Black snapback cap with embroidered Jumbo Parking logo. One size fits all.",
      price: "$24.99",
      image: "merch-hat.png",
      badge: nil
    },
    %{
      name: "Coffee Mug",
      description: "Start your morning right with this 11oz ceramic mug featuring our signature branding.",
      price: "$14.99",
      image: "merch-mug.png",
      badge: nil
    },
    %{
      name: "Executive Pen",
      description: "Sleek black ballpoint pen with Jumbo Parking branding. Perfect for the office.",
      price: "$9.99",
      image: "merch-pen.png",
      badge: nil
    },
    %{
      name: "Vehicle Decal",
      description: "Durable vinyl decal for your car or truck window. Weather-resistant and long-lasting.",
      price: "$7.99",
      image: "merch-decal.png",
      badge: "New"
    },
    %{
      name: "Bumper Sticker Pack",
      description: "Set of 3 premium stickers featuring Jumbo Parking designs. Great for laptops too.",
      price: "$5.99",
      image: "merch-decal.png",
      badge: nil
    }
  ]

  @impl true
  def mount(_params, _session, socket) do
    pricing_plans = Parking.list_pricing_plans()

    socket =
      socket
      |> assign(:page_title, "Secure Parking & Storage Solutions")
      |> assign(:pricing_plans, pricing_plans)
      |> assign(:selected_vehicle, "truck")
      |> assign(:testimonial_index, 0)
      |> assign(:testimonials, @testimonials)
      |> assign(:merch_items, @merch_items)
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
end
