defmodule JumboParking.Payments.StripeClient do
  @moduledoc """
  Stripe API client wrapper for checkout sessions.
  """

  def create_checkout_session(params) do
    Stripe.Checkout.Session.create(params)
  end

  def retrieve_session(session_id) do
    Stripe.Checkout.Session.retrieve(session_id)
  end
end
