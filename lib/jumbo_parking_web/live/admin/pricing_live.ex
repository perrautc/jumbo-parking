defmodule JumboParkingWeb.Admin.PricingLive do
  use JumboParkingWeb, :live_view

  alias JumboParking.Parking
  alias JumboParking.Parking.PricingPlan

  @impl true
  def mount(_params, _session, socket) do
    plans = Parking.list_pricing_plans()

    socket =
      socket
      |> assign(:page_title, "Pricing Plans")
      |> assign(:active_tab, :pricing)
      |> assign(:plans, plans)
      |> assign(:show_modal, false)
      |> assign(:editing_plan, nil)
      |> assign(:form, nil)

    {:ok, socket, layout: {JumboParkingWeb.Layouts, :admin}}
  end

  @impl true
  def handle_event("new", _params, socket) do
    changeset = Parking.change_pricing_plan(%PricingPlan{})

    socket =
      socket
      |> assign(:editing_plan, nil)
      |> assign(:form, to_form(changeset))
      |> assign(:show_modal, true)

    {:noreply, socket}
  end

  @impl true
  def handle_event("edit", %{"id" => id}, socket) do
    plan = Parking.get_pricing_plan!(String.to_integer(id))
    changeset = Parking.change_pricing_plan(plan)

    socket =
      socket
      |> assign(:editing_plan, plan)
      |> assign(:form, to_form(changeset))
      |> assign(:show_modal, true)

    {:noreply, socket}
  end

  @impl true
  def handle_event("close_modal", _params, socket) do
    {:noreply, assign(socket, show_modal: false, editing_plan: nil, form: nil)}
  end

  @impl true
  def handle_event("validate", %{"pricing_plan" => params}, socket) do
    plan = socket.assigns.editing_plan || %PricingPlan{}

    changeset =
      plan
      |> Parking.change_pricing_plan(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  @impl true
  def handle_event("save", %{"pricing_plan" => params}, socket) do
    # Convert price fields from dollars to cents
    params = convert_prices_to_cents(params)

    case socket.assigns.editing_plan do
      nil ->
        case Parking.create_pricing_plan(params) do
          {:ok, _plan} ->
            {:noreply,
             socket
             |> put_flash(:info, "Pricing plan created")
             |> assign(:show_modal, false)
             |> assign(:plans, Parking.list_pricing_plans())}

          {:error, changeset} ->
            {:noreply, assign(socket, :form, to_form(changeset))}
        end

      plan ->
        case Parking.update_pricing_plan(plan, params) do
          {:ok, _plan} ->
            {:noreply,
             socket
             |> put_flash(:info, "Pricing plan updated")
             |> assign(:show_modal, false)
             |> assign(:plans, Parking.list_pricing_plans())}

          {:error, changeset} ->
            {:noreply, assign(socket, :form, to_form(changeset))}
        end
    end
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    plan = Parking.get_pricing_plan!(String.to_integer(id))

    case Parking.delete_pricing_plan(plan) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Pricing plan deleted")
         |> assign(:plans, Parking.list_pricing_plans())}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to delete pricing plan")}
    end
  end

  defp convert_prices_to_cents(params) do
    params
    |> maybe_convert_to_cents("price_daily")
    |> maybe_convert_to_cents("price_weekly")
    |> maybe_convert_to_cents("price_monthly")
    |> maybe_convert_to_cents("price_yearly")
  end

  defp maybe_convert_to_cents(params, field) do
    case params[field] do
      nil -> params
      "" -> params
      value when is_binary(value) ->
        case Float.parse(value) do
          {float_val, _} -> Map.put(params, field, round(float_val * 100))
          :error -> params
        end
      value when is_number(value) ->
        Map.put(params, field, round(value * 100))
    end
  end

  defp format_price(nil), do: "-"
  defp format_price(cents) when is_integer(cents), do: "$#{:erlang.float_to_binary(cents / 100, decimals: 2)}"

  defp price_to_dollars(nil), do: ""
  defp price_to_dollars(cents) when is_integer(cents), do: :erlang.float_to_binary(cents / 100, decimals: 2)

end
