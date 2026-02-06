defmodule JumboParkingWeb.BookingLive do
  use JumboParkingWeb, :live_view

  alias JumboParking.Parking
  alias JumboParking.Payments

  @impl true
  def mount(_params, _session, socket) do
    pricing_plans = Parking.list_pricing_plans()

    socket =
      socket
      |> assign(:page_title, "Reserve Your Space")
      |> assign(:pricing_plans, pricing_plans)
      |> assign(:form, to_form(%{
        "first_name" => "",
        "last_name" => "",
        "email" => "",
        "phone" => "",
        "company" => "",
        "vehicle_plate" => "",
        "vehicle_model" => "",
        "vehicle_type" => "truck",
        "plan" => "monthly",
        "start_date" => Date.to_string(Date.utc_today()),
        "notes" => ""
      }))
      |> assign(:selected_vehicle, "truck")
      |> assign(:selected_plan, "monthly")
      |> assign(:submitting, false)

    {:ok, socket}
  end

  @impl true
  def handle_event("select_vehicle", %{"type" => type}, socket) do
    # Reset plan if selected plan is unavailable for the vehicle
    plan = if type != "truck" and socket.assigns.selected_plan in ["daily", "weekly"] do
      "monthly"
    else
      socket.assigns.selected_plan
    end

    socket =
      socket
      |> assign(:selected_vehicle, type)
      |> assign(:selected_plan, plan)
      |> assign(:form, to_form(Map.merge(socket.assigns.form.params, %{"vehicle_type" => type, "plan" => plan})))

    {:noreply, socket}
  end

  @impl true
  def handle_event("select_plan", %{"plan" => plan}, socket) do
    socket =
      socket
      |> assign(:selected_plan, plan)
      |> assign(:form, to_form(Map.merge(socket.assigns.form.params, %{"plan" => plan})))

    {:noreply, socket}
  end

  @impl true
  def handle_event("validate", %{"booking" => params}, socket) do
    {:noreply, assign(socket, :form, to_form(params))}
  end

  @impl true
  def handle_event("submit", %{"booking" => params}, socket) do
    socket = assign(socket, :submitting, true)

    customer_attrs = %{
      first_name: params["first_name"],
      last_name: params["last_name"],
      email: params["email"],
      phone: params["phone"],
      company: params["company"],
      vehicle_plate: params["vehicle_plate"],
      vehicle_model: params["vehicle_model"],
      vehicle_type: socket.assigns.selected_vehicle,
      plan: socket.assigns.selected_plan,
      status: "pending",
      notes: params["notes"]
    }

    case Parking.create_customer(customer_attrs) do
      {:ok, customer} ->
        price = Parking.calculate_price(socket.assigns.selected_vehicle, socket.assigns.selected_plan)

        start_date =
          case Date.from_iso8601(params["start_date"] || "") do
            {:ok, date} -> date
            _ -> Date.utc_today()
          end

        booking_attrs = %{
          customer_id: customer.id,
          start_date: start_date,
          status: "pending",
          total_amount: price
        }

        case Parking.create_booking(booking_attrs) do
          {:ok, booking} ->
            booking = Parking.preload_booking(booking, :customer)
            base_url = JumboParkingWeb.Endpoint.url()
            success_url = "#{base_url}/booking/success?session_id={CHECKOUT_SESSION_ID}"
            cancel_url = "#{base_url}/booking/cancel?booking_id=#{booking.id}"

            case Payments.create_checkout_session(booking, success_url, cancel_url) do
              {:ok, session} ->
                Parking.update_booking(booking, %{stripe_session_id: session.id})
                {:noreply, redirect(socket, external: session.url)}

              {:error, _stripe_error} ->
                socket =
                  socket
                  |> assign(:submitting, false)
                  |> put_flash(:error, "Payment setup failed. Please try again.")

                {:noreply, socket}
            end

          {:error, _changeset} ->
            socket =
              socket
              |> assign(:submitting, false)
              |> put_flash(:error, "Failed to create booking. Please try again.")

            {:noreply, socket}
        end

      {:error, changeset} ->
        errors = Enum.map(changeset.errors, fn {field, {msg, _}} -> "#{field}: #{msg}" end) |> Enum.join(", ")

        socket =
          socket
          |> assign(:submitting, false)
          |> put_flash(:error, "Please fix the following errors: #{errors}")

        {:noreply, socket}
    end
  end

  defp get_plan_for_vehicle(plans, vehicle_type) do
    Enum.find(plans, fn p -> p.vehicle_type == vehicle_type end)
  end

  defp format_price(nil), do: "$0"
  defp format_price(cents) when is_integer(cents), do: "$#{div(cents, 100)}"

  defp current_price(plans, vehicle_type, plan) do
    case get_plan_for_vehicle(plans, vehicle_type) do
      nil -> 0
      pricing ->
        case plan do
          "daily" -> pricing.price_daily || 0
          "weekly" -> pricing.price_weekly || 0
          "monthly" -> pricing.price_monthly || 0
          "yearly" -> pricing.price_yearly || 0
          _ -> 0
        end
    end
  end

  defp plan_label("daily"), do: "Daily"
  defp plan_label("weekly"), do: "Weekly"
  defp plan_label("monthly"), do: "Monthly"
  defp plan_label("yearly"), do: "Yearly"
  defp plan_label(_), do: ""

  defp period_suffix("daily"), do: "per day"
  defp period_suffix("weekly"), do: "per week"
  defp period_suffix("monthly"), do: "per month"
  defp period_suffix("yearly"), do: "per year"
  defp period_suffix(_), do: ""

  defp vehicle_label("truck"), do: "Truck & Trailer"
  defp vehicle_label("rv"), do: "RV"
  defp vehicle_label("car"), do: "Car or SUV"
  defp vehicle_label(_), do: ""

  defp available_plans("truck"), do: ["daily", "weekly", "monthly", "yearly"]
  defp available_plans(_), do: ["monthly", "yearly"]
end
