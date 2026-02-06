defmodule JumboParkingWeb.PrintfulWebhookController do
  use JumboParkingWeb, :controller

  require Logger

  alias JumboParking.Fulfillment

  @doc """
  Handles incoming Printful webhook events.
  """
  def handle(conn, params) do
    event_type = params["type"]
    data = params["data"]

    Logger.info("Received Printful webhook: #{event_type}")

    case Fulfillment.handle_webhook(event_type, data) do
      :ok ->
        json(conn, %{status: "ok"})

      {:error, reason} ->
        Logger.error("Printful webhook error: #{inspect(reason)}")
        conn
        |> put_status(500)
        |> json(%{status: "error", message: "Failed to process webhook"})
    end
  end
end
