defmodule JumboParking.Fulfillment.PrintfulClient do
  @moduledoc """
  HTTP client for Printful API integration.
  """

  require Logger

  @base_url "https://api.printful.com"

  defp api_key do
    Application.get_env(:jumbo_parking, :printful_api_key)
  end

  defp headers do
    [
      {"Authorization", "Bearer #{api_key()}"},
      {"Content-Type", "application/json"}
    ]
  end

  @doc """
  Creates an order in Printful.
  """
  def create_order(order_params) do
    url = "#{@base_url}/orders"
    body = Jason.encode!(order_params)

    case http_client().post(url, body, headers: headers()) do
      {:ok, %{status: status, body: body}} when status in 200..299 ->
        {:ok, Jason.decode!(body)}

      {:ok, %{status: status, body: body}} ->
        Logger.error("Printful API error: #{status} - #{body}")
        {:error, {:api_error, status, body}}

      {:error, reason} ->
        Logger.error("Printful HTTP error: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Gets order details from Printful.
  """
  def get_order(printful_order_id) do
    url = "#{@base_url}/orders/#{printful_order_id}"

    case http_client().get(url, headers: headers()) do
      {:ok, %{status: 200, body: body}} ->
        {:ok, Jason.decode!(body)}

      {:ok, %{status: status, body: body}} ->
        {:error, {:api_error, status, body}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Lists all products in the Printful store.
  """
  def list_products do
    url = "#{@base_url}/store/products"

    case http_client().get(url, headers: headers()) do
      {:ok, %{status: 200, body: body}} ->
        {:ok, Jason.decode!(body)}

      {:ok, %{status: status, body: body}} ->
        {:error, {:api_error, status, body}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Gets product details including variants.
  """
  def get_product(sync_product_id) do
    url = "#{@base_url}/store/products/#{sync_product_id}"

    case http_client().get(url, headers: headers()) do
      {:ok, %{status: 200, body: body}} ->
        {:ok, Jason.decode!(body)}

      {:ok, %{status: status, body: body}} ->
        {:error, {:api_error, status, body}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Gets shipping rates for an order.
  """
  def get_shipping_rates(recipient, items) do
    url = "#{@base_url}/shipping/rates"

    body =
      Jason.encode!(%{
        recipient: recipient,
        items: items
      })

    case http_client().post(url, body, headers: headers()) do
      {:ok, %{status: 200, body: body}} ->
        {:ok, Jason.decode!(body)}

      {:ok, %{status: status, body: body}} ->
        {:error, {:api_error, status, body}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Confirms a draft order in Printful.
  """
  def confirm_order(printful_order_id) do
    url = "#{@base_url}/orders/#{printful_order_id}/confirm"

    case http_client().post(url, "", headers: headers()) do
      {:ok, %{status: status, body: body}} when status in 200..299 ->
        {:ok, Jason.decode!(body)}

      {:ok, %{status: status, body: body}} ->
        {:error, {:api_error, status, body}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Cancels an order in Printful.
  """
  def cancel_order(printful_order_id) do
    url = "#{@base_url}/orders/#{printful_order_id}"

    case http_client().delete(url, headers: headers()) do
      {:ok, %{status: status, body: body}} when status in 200..299 ->
        {:ok, Jason.decode!(body)}

      {:ok, %{status: status, body: body}} ->
        {:error, {:api_error, status, body}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp http_client do
    Application.get_env(:jumbo_parking, :http_client, Req)
  end
end
