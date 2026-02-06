defmodule JumboParkingWeb.Admin.MerchLive do
  use JumboParkingWeb, :live_view

  alias JumboParking.Parking
  alias JumboParking.Parking.MerchItem
  alias JumboParking.Store
  alias JumboParking.Store.ProductVariant

  @impl true
  def mount(_params, _session, socket) do
    items = Parking.list_merch_items() |> JumboParking.Repo.preload(:variants)
    merch_enabled = Parking.get_setting_bool("merch_store_enabled")

    socket =
      socket
      |> assign(:page_title, "Merch Store")
      |> assign(:active_tab, :merch)
      |> assign(:items, items)
      |> assign(:merch_enabled, merch_enabled)
      |> assign(:show_modal, false)
      |> assign(:show_delete_modal, false)
      |> assign(:show_variants_modal, false)
      |> assign(:show_variant_form, false)
      |> assign(:editing_item, nil)
      |> assign(:selected_item, nil)
      |> assign(:editing_variant, nil)
      |> assign(:form, new_form())
      |> assign(:variant_form, new_variant_form())

    {:ok, socket, layout: {JumboParkingWeb.Layouts, :admin}}
  end

  @impl true
  def handle_event("toggle_store", _params, socket) do
    new_value = if socket.assigns.merch_enabled, do: "false", else: "true"
    Parking.set_setting("merch_store_enabled", new_value)

    {:noreply, assign(socket, :merch_enabled, new_value == "true")}
  end

  @impl true
  def handle_event("new", _params, socket) do
    socket =
      socket
      |> assign(:editing_item, nil)
      |> assign(:form, new_form())
      |> assign(:show_modal, true)

    {:noreply, socket}
  end

  @impl true
  def handle_event("edit", %{"id" => id}, socket) do
    item = Parking.get_merch_item!(String.to_integer(id))
    changeset = Parking.change_merch_item(item)

    socket =
      socket
      |> assign(:editing_item, item)
      |> assign(:form, to_form(changeset))
      |> assign(:show_modal, true)

    {:noreply, socket}
  end

  @impl true
  def handle_event("validate", %{"merch_item" => params}, socket) do
    params = convert_price_to_cents(params)

    changeset =
      (socket.assigns.editing_item || %MerchItem{})
      |> Parking.change_merch_item(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  @impl true
  def handle_event("save", %{"merch_item" => params}, socket) do
    params = convert_price_to_cents(params)

    result =
      if socket.assigns.editing_item do
        Parking.update_merch_item(socket.assigns.editing_item, params)
      else
        Parking.create_merch_item(params)
      end

    case result do
      {:ok, _item} ->
        action = if socket.assigns.editing_item, do: "updated", else: "created"

        {:noreply,
         socket
         |> assign(:items, Parking.list_merch_items() |> JumboParking.Repo.preload(:variants))
         |> assign(:show_modal, false)
         |> put_flash(:info, "Merch item #{action} successfully")}

      {:error, changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  @impl true
  def handle_event("toggle_active", %{"id" => id}, socket) do
    item = Parking.get_merch_item!(String.to_integer(id))

    case Parking.toggle_merch_item_active(item) do
      {:ok, _} ->
        {:noreply, assign(socket, :items, Parking.list_merch_items() |> JumboParking.Repo.preload(:variants))}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to update item")}
    end
  end

  @impl true
  def handle_event("open_delete", %{"id" => id}, socket) do
    item = Parking.get_merch_item!(String.to_integer(id))

    socket =
      socket
      |> assign(:selected_item, item)
      |> assign(:show_delete_modal, true)

    {:noreply, socket}
  end

  @impl true
  def handle_event("confirm_delete", _params, socket) do
    item = socket.assigns.selected_item

    case Parking.delete_merch_item(item) do
      {:ok, _} ->
        {:noreply,
         socket
         |> assign(:items, Parking.list_merch_items() |> JumboParking.Repo.preload(:variants))
         |> assign(:show_delete_modal, false)
         |> assign(:selected_item, nil)
         |> put_flash(:info, "Merch item deleted successfully")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to delete item")}
    end
  end

  @impl true
  def handle_event("close_modal", _params, socket) do
    {:noreply,
     assign(socket,
       show_modal: false,
       show_delete_modal: false,
       show_variants_modal: false,
       show_variant_form: false,
       selected_item: nil,
       editing_item: nil,
       editing_variant: nil
     )}
  end

  # Variant Management Events

  @impl true
  def handle_event("manage_variants", %{"id" => id}, socket) do
    item = Parking.get_merch_item!(String.to_integer(id)) |> JumboParking.Repo.preload(:variants)

    {:noreply,
     socket
     |> assign(:selected_item, item)
     |> assign(:show_variants_modal, true)
     |> assign(:show_variant_form, false)
     |> assign(:editing_variant, nil)
     |> assign(:variant_form, new_variant_form())}
  end

  @impl true
  def handle_event("new_variant", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_variant_form, true)
     |> assign(:editing_variant, nil)
     |> assign(:variant_form, new_variant_form())}
  end

  @impl true
  def handle_event("edit_variant", %{"id" => id}, socket) do
    variant = Store.get_variant!(String.to_integer(id))
    changeset = Store.change_variant(variant)

    {:noreply,
     socket
     |> assign(:show_variant_form, true)
     |> assign(:editing_variant, variant)
     |> assign(:variant_form, to_form(changeset))}
  end

  @impl true
  def handle_event("validate_variant", %{"product_variant" => params}, socket) do
    params = convert_variant_price_to_cents(params)

    changeset =
      (socket.assigns.editing_variant || %ProductVariant{})
      |> Store.change_variant(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :variant_form, to_form(changeset))}
  end

  @impl true
  def handle_event("save_variant", %{"product_variant" => params}, socket) do
    params = convert_variant_price_to_cents(params)
    params = Map.put(params, "merch_item_id", socket.assigns.selected_item.id)

    result =
      if socket.assigns.editing_variant do
        Store.update_variant(socket.assigns.editing_variant, params)
      else
        Store.create_variant(params)
      end

    case result do
      {:ok, _variant} ->
        item = Parking.get_merch_item!(socket.assigns.selected_item.id) |> JumboParking.Repo.preload(:variants)
        items = Parking.list_merch_items() |> JumboParking.Repo.preload(:variants)
        action = if socket.assigns.editing_variant, do: "updated", else: "created"

        {:noreply,
         socket
         |> assign(:items, items)
         |> assign(:selected_item, item)
         |> assign(:show_variant_form, false)
         |> assign(:editing_variant, nil)
         |> assign(:variant_form, new_variant_form())
         |> put_flash(:info, "Variant #{action} successfully")}

      {:error, changeset} ->
        {:noreply, assign(socket, :variant_form, to_form(changeset))}
    end
  end

  @impl true
  def handle_event("delete_variant", %{"id" => id}, socket) do
    variant = Store.get_variant!(String.to_integer(id))

    case Store.delete_variant(variant) do
      {:ok, _} ->
        item = Parking.get_merch_item!(socket.assigns.selected_item.id) |> JumboParking.Repo.preload(:variants)
        items = Parking.list_merch_items() |> JumboParking.Repo.preload(:variants)

        {:noreply,
         socket
         |> assign(:items, items)
         |> assign(:selected_item, item)
         |> put_flash(:info, "Variant deleted successfully")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to delete variant")}
    end
  end

  @impl true
  def handle_event("cancel_variant_form", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_variant_form, false)
     |> assign(:editing_variant, nil)
     |> assign(:variant_form, new_variant_form())}
  end

  defp new_form do
    to_form(%{"name" => "", "description" => "", "price" => "", "image_url" => "", "badge" => "", "external_url" => "", "sku" => "", "sort_order" => "0", "fulfillment_type" => "in_stock"})
  end

  defp new_variant_form do
    to_form(%{"sku" => "", "name" => "", "size" => "", "color" => "", "price" => "", "stock_quantity" => "0"})
  end

  defp convert_variant_price_to_cents(params) do
    case params["price"] do
      nil -> params
      "" -> params
      price_str ->
        case Float.parse(price_str) do
          {price, _} -> Map.put(params, "price", round(price * 100))
          :error -> params
        end
    end
  end

  defp convert_price_to_cents(params) do
    case params["price"] do
      nil -> params
      "" -> params
      price_str ->
        case Float.parse(price_str) do
          {price, _} -> Map.put(params, "price", round(price * 100))
          :error -> params
        end
    end
  end

  def format_price(nil), do: "-"
  def format_price(cents) when is_integer(cents), do: "$#{:erlang.float_to_binary(cents / 100, decimals: 2)}"
  def format_price(_), do: "-"

  def price_to_dollars(nil), do: ""
  def price_to_dollars(""), do: ""
  def price_to_dollars(cents) when is_integer(cents), do: :erlang.float_to_binary(cents / 100, decimals: 2)
  def price_to_dollars(_), do: ""

  def badge_color("popular"), do: "bg-[#c8d935]/20 text-[#c8d935]"
  def badge_color("new"), do: "bg-blue-500/20 text-blue-400"
  def badge_color("sale"), do: "bg-red-500/20 text-red-400"
  def badge_color(_), do: ""
end
