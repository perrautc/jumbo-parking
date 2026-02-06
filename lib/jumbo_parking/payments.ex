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

  @doc """
  Creates a Stripe Checkout session for a store order.
  """
  def create_order_checkout_session(order, success_url, cancel_url) do
    order = JumboParking.Repo.preload(order, :items)

    line_items =
      Enum.map(order.items, fn item ->
        %{
          price_data: %{
            currency: "usd",
            unit_amount: item.unit_price,
            product_data: %{
              name: item.product_name,
              description: item.variant_name || "Default"
            }
          },
          quantity: item.quantity
        }
      end)

    # Add shipping as a line item if applicable
    line_items =
      if order.shipping_cost && order.shipping_cost > 0 do
        line_items ++
          [
            %{
              price_data: %{
                currency: "usd",
                unit_amount: order.shipping_cost,
                product_data: %{
                  name: "Shipping"
                }
              },
              quantity: 1
            }
          ]
      else
        line_items
      end

    StripeClient.create_checkout_session(%{
      mode: "payment",
      line_items: line_items,
      customer_email: order.email,
      metadata: %{order_id: order.id, order_number: order.order_number},
      success_url: success_url,
      cancel_url: cancel_url,
      shipping_address_collection: %{
        allowed_countries: ["US"]
      }
    })
  end
end
