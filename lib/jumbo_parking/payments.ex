defmodule JumboParking.Payments do
  @moduledoc """
  The Payments context - handles Stripe payment integration.
  """

  alias JumboParking.Payments.StripeClient
  alias JumboParking.Parking

  @doc """
  Creates a Stripe Checkout session for the given booking.
  The booking must be preloaded with customer data.
  """
  def create_checkout_session(booking, success_url, cancel_url) do
    StripeClient.create_checkout_session(%{
      mode: "payment",
      line_items: [
        %{
          price_data: %{
            currency: "usd",
            unit_amount: booking.total_amount,
            product_data: %{
              name: "Parking Reservation - #{booking.customer.plan}",
              description: "#{booking.customer.vehicle_type} parking"
            }
          },
          quantity: 1
        }
      ],
      customer_email: booking.customer.email,
      metadata: %{booking_id: booking.id},
      success_url: success_url,
      cancel_url: cancel_url
    })
  end

  @doc """
  Retrieves a Stripe Checkout session by ID.
  """
  def retrieve_checkout_session(session_id) do
    StripeClient.retrieve_session(session_id)
  end

  @doc """
  Confirms a booking payment by verifying the Stripe session and updating the booking status.
  """
  def confirm_booking_payment(session_id) do
    with {:ok, session} <- retrieve_checkout_session(session_id),
         "paid" <- session.payment_status,
         booking_id <- session.metadata["booking_id"],
         booking <- Parking.get_booking!(booking_id) do
      Parking.update_booking(booking, %{
        status: "confirmed",
        stripe_session_id: session.id,
        stripe_payment_intent_id: session.payment_intent
      })
    else
      {:error, reason} -> {:error, reason}
      status when is_binary(status) -> {:error, {:payment_not_complete, status}}
      _ -> {:error, :unknown}
    end
  end
end
