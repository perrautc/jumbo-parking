defmodule JumboParking.Fulfillment do
  @moduledoc """
  The Fulfillment context - handles order fulfillment routing and processing.
  """

  require Logger

  alias JumboParking.Store
  alias JumboParking.Fulfillment.PrintfulClient

  @doc """
  Processes fulfillment for a paid order.
  Routes items to appropriate fulfillment channels (Printful or in-stock).
  """
  def process_order(order_id) do
    order = Store.get_order!(order_id)

    # Get items grouped by fulfillment type
    printful_items = Store.get_order_items_by_fulfillment(order_id, "printful")
    in_stock_items = Store.get_order_items_by_fulfillment(order_id, "in_stock")

    # Process Printful items
    printful_result =
      if length(printful_items) > 0 do
        submit_to_printful(order, printful_items)
      else
        {:ok, :no_items}
      end

    # Mark in-stock items as processing (admin will ship manually)
    Enum.each(in_stock_items, fn item ->
      Store.update_order_item(item, %{status: "processing"})
    end)

    # Update order status
    new_status =
      cond do
        length(printful_items) > 0 and length(in_stock_items) > 0 -> "processing"
        length(printful_items) > 0 -> "processing"
        length(in_stock_items) > 0 -> "processing"
        true -> "paid"
      end

    Store.update_order(order, %{status: new_status})

    printful_result
  end

  @doc """
  Submits Printful items to Printful API.
  """
  def submit_to_printful(order, items) do
    recipient = %{
      name: order.shipping_name,
      address1: order.shipping_address1,
      address2: order.shipping_address2,
      city: order.shipping_city,
      state_code: order.shipping_state,
      zip: order.shipping_zip,
      country_code: order.shipping_country,
      email: order.email
    }

    printful_items =
      Enum.map(items, fn item ->
        %{
          sync_variant_id: item.variant.printful_variant_id,
          quantity: item.quantity
        }
      end)

    order_params = %{
      external_id: order.order_number,
      recipient: recipient,
      items: printful_items
    }

    case PrintfulClient.create_order(order_params) do
      {:ok, %{"result" => result}} ->
        printful_order_id = result["id"]

        # Update each item with Printful order ID
        Enum.each(items, fn item ->
          Store.update_order_item(item, %{
            printful_order_id: printful_order_id,
            status: "processing"
          })
        end)

        Logger.info("Printful order created: #{printful_order_id} for order #{order.order_number}")
        {:ok, printful_order_id}

      {:error, reason} ->
        Logger.error("Failed to create Printful order for #{order.order_number}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Handles Printful webhook events.
  """
  def handle_webhook(event_type, data) do
    case event_type do
      "package_shipped" ->
        handle_package_shipped(data)

      "order_updated" ->
        handle_order_updated(data)

      "order_canceled" ->
        handle_order_canceled(data)

      _ ->
        Logger.info("Unhandled Printful webhook event: #{event_type}")
        :ok
    end
  end

  defp handle_package_shipped(data) do
    external_id = data["order"]["external_id"]
    shipments = data["shipments"] || []

    case Store.get_order_by_number(external_id) do
      nil ->
        Logger.warning("Order not found for Printful shipment: #{external_id}")
        :ok

      order ->
        # Update items with tracking info
        Enum.each(shipments, fn shipment ->
          tracking_number = shipment["tracking_number"]
          tracking_url = shipment["tracking_url"]

          # Update all Printful items for this order
          order.items
          |> Enum.filter(&(&1.fulfillment_type == "printful"))
          |> Enum.each(fn item ->
            Store.update_order_item(item, %{
              status: "shipped",
              tracking_number: tracking_number,
              tracking_url: tracking_url
            })
          end)
        end)

        # Check if all items are shipped
        updated_order = Store.get_order!(order.id)
        all_shipped = Enum.all?(updated_order.items, &(&1.status == "shipped"))

        if all_shipped do
          Store.update_order(order, %{status: "shipped"})
        end

        Logger.info("Processed shipment for order #{external_id}")
        :ok
    end
  end

  defp handle_order_updated(data) do
    external_id = data["order"]["external_id"]
    status = data["order"]["status"]

    Logger.info("Printful order updated: #{external_id} -> #{status}")
    :ok
  end

  defp handle_order_canceled(data) do
    external_id = data["order"]["external_id"]

    case Store.get_order_by_number(external_id) do
      nil ->
        :ok

      order ->
        order.items
        |> Enum.filter(&(&1.fulfillment_type == "printful"))
        |> Enum.each(fn item ->
          Store.update_order_item(item, %{status: "cancelled"})
        end)

        Logger.info("Printful order cancelled: #{external_id}")
        :ok
    end
  end

  @doc """
  Syncs products from Printful to local database.
  """
  def sync_printful_products do
    case PrintfulClient.list_products() do
      {:ok, %{"result" => products}} ->
        Enum.each(products, fn product ->
          sync_product(product["id"])
        end)

        {:ok, length(products)}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp sync_product(sync_product_id) do
    case PrintfulClient.get_product(sync_product_id) do
      {:ok, %{"result" => result}} ->
        _sync_product = result["sync_product"]
        _sync_variants = result["sync_variants"]
        # TODO: Update local database with Printful product data
        :ok

      {:error, _reason} ->
        :error
    end
  end
end
