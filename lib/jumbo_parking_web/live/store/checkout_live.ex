defmodule JumboParkingWeb.Store.CheckoutLive do
  use JumboParkingWeb, :live_view

  alias JumboParking.Store
  alias JumboParking.Payments

  @impl true
  def mount(_params, session, socket) do
    cart_session_id = session["cart_session_id"]
    cart = if cart_session_id, do: Store.get_or_create_cart(cart_session_id), else: nil

    # Redirect to cart if empty
    if is_nil(cart) || length(cart.items) == 0 do
      {:ok, push_navigate(socket, to: ~p"/store/cart")}
    else
      form = to_form(%{
        "email" => "",
        "shipping_name" => "",
        "shipping_address1" => "",
        "shipping_address2" => "",
        "shipping_city" => "",
        "shipping_state" => "",
        "shipping_zip" => "",
        "shipping_country" => "US"
      })

      socket =
        socket
        |> assign(:page_title, "Checkout")
        |> assign(:cart, cart)
        |> assign(:cart_session_id, cart_session_id)
        |> assign(:form, form)
        |> assign(:shipping_cost, 0)
        |> assign(:submitting, false)
        |> assign(:errors, %{})

      {:ok, socket}
    end
  end

  @impl true
  def handle_event("validate", %{"checkout" => params}, socket) do
    errors = validate_form(params)
    {:noreply, assign(socket, form: to_form(params, as: :checkout), errors: errors)}
  end

  @impl true
  def handle_event("submit", %{"checkout" => params}, socket) do
    errors = validate_form(params)

    if map_size(errors) > 0 do
      {:noreply, assign(socket, errors: errors)}
    else
      socket = assign(socket, :submitting, true)

      cart = socket.assigns.cart
      subtotal = Store.cart_subtotal(cart)
      shipping_cost = calculate_shipping(subtotal)

      # Create order
      order_attrs = %{
        email: params["email"],
        shipping_name: params["shipping_name"],
        shipping_address1: params["shipping_address1"],
        shipping_address2: params["shipping_address2"],
        shipping_city: params["shipping_city"],
        shipping_state: params["shipping_state"],
        shipping_zip: params["shipping_zip"],
        shipping_country: params["shipping_country"] || "US",
        shipping_cost: shipping_cost
      }

      case Store.create_order_from_cart(cart, order_attrs) do
        {:ok, order} ->
          # Create Stripe checkout session
          success_url = url(~p"/store/checkout/success?session_id={CHECKOUT_SESSION_ID}")
          cancel_url = url(~p"/store/checkout/cancel")

          case Payments.create_order_checkout_session(order, success_url, cancel_url) do
            {:ok, session} ->
              # Update order with Stripe session ID
              Store.update_order(order, %{stripe_session_id: session.id})

              {:noreply,
               socket
               |> assign(:submitting, false)
               |> redirect(external: session.url)}

            {:error, _reason} ->
              {:noreply,
               socket
               |> assign(:submitting, false)
               |> put_flash(:error, "Could not create payment session. Please try again.")}
          end

        {:error, _reason} ->
          {:noreply,
           socket
           |> assign(:submitting, false)
           |> put_flash(:error, "Could not create order. Please try again.")}
      end
    end
  end

  defp validate_form(params) do
    errors = %{}

    errors =
      if is_nil(params["email"]) || params["email"] == "" do
        Map.put(errors, :email, "Email is required")
      else
        if String.match?(params["email"], ~r/^[^\s]+@[^\s]+$/) do
          errors
        else
          Map.put(errors, :email, "Invalid email format")
        end
      end

    errors =
      if is_nil(params["shipping_name"]) || params["shipping_name"] == "" do
        Map.put(errors, :shipping_name, "Name is required")
      else
        errors
      end

    errors =
      if is_nil(params["shipping_address1"]) || params["shipping_address1"] == "" do
        Map.put(errors, :shipping_address1, "Address is required")
      else
        errors
      end

    errors =
      if is_nil(params["shipping_city"]) || params["shipping_city"] == "" do
        Map.put(errors, :shipping_city, "City is required")
      else
        errors
      end

    errors =
      if is_nil(params["shipping_state"]) || params["shipping_state"] == "" do
        Map.put(errors, :shipping_state, "State is required")
      else
        errors
      end

    errors =
      if is_nil(params["shipping_zip"]) || params["shipping_zip"] == "" do
        Map.put(errors, :shipping_zip, "ZIP code is required")
      else
        errors
      end

    errors
  end

  defp calculate_shipping(subtotal) do
    # Free shipping over $50
    if subtotal >= 5000, do: 0, else: 599
  end

  def format_price(cents), do: Store.format_price(cents)

  def subtotal(cart), do: Store.cart_subtotal(cart)

  def shipping_cost(cart) do
    calculate_shipping(Store.cart_subtotal(cart))
  end

  def total(cart) do
    subtotal(cart) + shipping_cost(cart)
  end

  @us_states [
    {"Alabama", "AL"}, {"Alaska", "AK"}, {"Arizona", "AZ"}, {"Arkansas", "AR"},
    {"California", "CA"}, {"Colorado", "CO"}, {"Connecticut", "CT"}, {"Delaware", "DE"},
    {"Florida", "FL"}, {"Georgia", "GA"}, {"Hawaii", "HI"}, {"Idaho", "ID"},
    {"Illinois", "IL"}, {"Indiana", "IN"}, {"Iowa", "IA"}, {"Kansas", "KS"},
    {"Kentucky", "KY"}, {"Louisiana", "LA"}, {"Maine", "ME"}, {"Maryland", "MD"},
    {"Massachusetts", "MA"}, {"Michigan", "MI"}, {"Minnesota", "MN"}, {"Mississippi", "MS"},
    {"Missouri", "MO"}, {"Montana", "MT"}, {"Nebraska", "NE"}, {"Nevada", "NV"},
    {"New Hampshire", "NH"}, {"New Jersey", "NJ"}, {"New Mexico", "NM"}, {"New York", "NY"},
    {"North Carolina", "NC"}, {"North Dakota", "ND"}, {"Ohio", "OH"}, {"Oklahoma", "OK"},
    {"Oregon", "OR"}, {"Pennsylvania", "PA"}, {"Rhode Island", "RI"}, {"South Carolina", "SC"},
    {"South Dakota", "SD"}, {"Tennessee", "TN"}, {"Texas", "TX"}, {"Utah", "UT"},
    {"Vermont", "VT"}, {"Virginia", "VA"}, {"Washington", "WA"}, {"West Virginia", "WV"},
    {"Wisconsin", "WI"}, {"Wyoming", "WY"}
  ]

  def us_states, do: @us_states
end
