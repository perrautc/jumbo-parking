defmodule JumboParkingWeb.StripeController do
  use JumboParkingWeb, :controller

  alias JumboParking.Payments

  def success(conn, %{"session_id" => session_id}) do
    case Payments.confirm_booking_payment(session_id) do
      {:ok, _booking} ->
        conn
        |> put_flash(:info, "Payment successful! Your booking is confirmed.")
        |> redirect(to: ~p"/")

      {:error, _reason} ->
        conn
        |> put_flash(:error, "There was an issue confirming your payment.")
        |> redirect(to: ~p"/")
    end
  end

  def cancel(conn, _params) do
    conn
    |> put_flash(:info, "Payment was cancelled. You can try again.")
    |> redirect(to: ~p"/booking")
  end
end
