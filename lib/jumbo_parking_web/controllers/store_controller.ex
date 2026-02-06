defmodule JumboParkingWeb.StoreController do
  use JumboParkingWeb, :controller

  alias JumboParking.Store
  alias JumboParking.Payments

  def success(conn, %{"session_id" => session_id}) do
    with {:ok, session} <- Payments.retrieve_checkout_session(session_id),
         order when not is_nil(order) <- Store.get_order_by_stripe_session(session_id),
         "paid" <- session.payment_status do
      # Update order status
      Store.update_order(order, %{
        status: "paid",
        stripe_payment_intent_id: session.payment_intent
      })

      # Clear the cart
      cart_session_id = get_session(conn, "cart_session_id")
      if cart_session_id do
        cart = Store.get_cart(cart_session_id)
        if cart, do: Store.clear_cart(cart)
      end

      redirect(conn, to: ~p"/store/order/#{order.order_number}")
    else
      _ ->
        conn
        |> put_flash(:error, "Could not verify payment. Please contact support.")
        |> redirect(to: ~p"/store/cart")
    end
  end

  def success(conn, _params) do
    conn
    |> put_flash(:error, "Invalid checkout session")
    |> redirect(to: ~p"/store/cart")
  end

  def cancel(conn, _params) do
    conn
    |> put_flash(:info, "Checkout cancelled. Your cart items are still saved.")
    |> redirect(to: ~p"/store/cart")
  end
end
