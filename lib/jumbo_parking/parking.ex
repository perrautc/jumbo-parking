defmodule JumboParking.Parking do
  @moduledoc """
  The Parking context - all business logic for lots, spaces, customers, bookings, pricing, and activity.
  """

  import Ecto.Query, warn: false
  alias JumboParking.Repo

  alias JumboParking.Parking.{ParkingLot, PricingPlan, Customer, ParkingSpace, Booking, ActivityLog, VehicleType, MerchItem, SiteSetting}

  # ── Parking Lots ────────────────────────────────────────────

  def list_lots do
    Repo.all(from l in ParkingLot, order_by: l.name)
  end

  def list_active_lots do
    Repo.all(from l in ParkingLot, where: l.active == true, order_by: l.name)
  end

  def get_lot!(id), do: Repo.get!(ParkingLot, id)

  def get_lot(id), do: Repo.get(ParkingLot, id)

  def create_lot(attrs) do
    result =
      %ParkingLot{}
      |> ParkingLot.changeset(attrs)
      |> Repo.insert()

    case result do
      {:ok, lot} ->
        log_activity("lot_created", "Parking lot created: #{lot.name}", "lot", lot.id)
        {:ok, lot}

      error ->
        error
    end
  end

  def update_lot(%ParkingLot{} = lot, attrs) do
    result =
      lot
      |> ParkingLot.changeset(attrs)
      |> Repo.update()

    case result do
      {:ok, lot} ->
        log_activity("lot_updated", "Parking lot updated: #{lot.name}", "lot", lot.id)
        {:ok, lot}

      error ->
        error
    end
  end

  def delete_lot(%ParkingLot{} = lot) do
    # Check if lot has spaces
    space_count = Repo.aggregate(from(s in ParkingSpace, where: s.parking_lot_id == ^lot.id), :count, :id)

    if space_count > 0 do
      {:error, :has_spaces}
    else
      result = Repo.delete(lot)

      case result do
        {:ok, lot} ->
          log_activity("lot_deleted", "Parking lot deleted: #{lot.name}", "lot", lot.id)
          {:ok, lot}

        error ->
          error
      end
    end
  end

  def change_lot(%ParkingLot{} = lot, attrs \\ %{}) do
    ParkingLot.changeset(lot, attrs)
  end

  def lot_space_counts(lot_id) do
    from(s in ParkingSpace, where: s.parking_lot_id == ^lot_id)
    |> Repo.all()
    |> Enum.reduce(%{total: 0, available: 0, occupied: 0, reserved: 0, maintenance: 0}, fn space, acc ->
      acc
      |> Map.update!(:total, &(&1 + 1))
      |> Map.update!(String.to_existing_atom(space.status), &(&1 + 1))
    end)
  end

  def all_lots_with_counts do
    lots = list_lots()

    Enum.map(lots, fn lot ->
      counts = lot_space_counts(lot.id)
      Map.put(lot, :space_counts, counts)
    end)
  end

  # ── Vehicle Types ─────────────────────────────────────────

  def list_vehicle_types do
    Repo.all(from vt in VehicleType, order_by: vt.sort_order)
  end

  def list_active_vehicle_types do
    Repo.all(from vt in VehicleType, where: vt.active == true, order_by: vt.sort_order)
  end

  def get_vehicle_type!(id), do: Repo.get!(VehicleType, id)

  def get_vehicle_type(id), do: Repo.get(VehicleType, id)

  def get_vehicle_type_by_slug(slug) do
    Repo.get_by(VehicleType, slug: slug)
  end

  def create_vehicle_type(attrs) do
    result =
      %VehicleType{}
      |> VehicleType.changeset(attrs)
      |> Repo.insert()

    case result do
      {:ok, vehicle_type} ->
        log_activity("vehicle_type_created", "Vehicle type created: #{vehicle_type.name}", "vehicle_type", vehicle_type.id)
        {:ok, vehicle_type}

      error ->
        error
    end
  end

  def update_vehicle_type(%VehicleType{} = vehicle_type, attrs) do
    result =
      vehicle_type
      |> VehicleType.changeset(attrs)
      |> Repo.update()

    case result do
      {:ok, vehicle_type} ->
        log_activity("vehicle_type_updated", "Vehicle type updated: #{vehicle_type.name}", "vehicle_type", vehicle_type.id)
        {:ok, vehicle_type}

      error ->
        error
    end
  end

  def delete_vehicle_type(%VehicleType{} = vehicle_type) do
    # Check if vehicle type is in use
    pricing_count = Repo.aggregate(from(p in PricingPlan, where: p.vehicle_type == ^vehicle_type.slug), :count, :id)
    customer_count = Repo.aggregate(from(c in Customer, where: c.vehicle_type == ^vehicle_type.slug), :count, :id)
    space_count = Repo.aggregate(from(s in ParkingSpace, where: s.vehicle_type == ^vehicle_type.slug), :count, :id)

    if pricing_count > 0 or customer_count > 0 or space_count > 0 do
      {:error, :in_use}
    else
      result = Repo.delete(vehicle_type)

      case result do
        {:ok, vehicle_type} ->
          log_activity("vehicle_type_deleted", "Vehicle type deleted: #{vehicle_type.name}", "vehicle_type", vehicle_type.id)
          {:ok, vehicle_type}

        error ->
          error
      end
    end
  end

  def change_vehicle_type(%VehicleType{} = vehicle_type, attrs \\ %{}) do
    VehicleType.changeset(vehicle_type, attrs)
  end

  def vehicle_type_options do
    list_active_vehicle_types()
    |> Enum.map(fn vt -> {vt.name, vt.slug} end)
  end

  def vehicle_type_slug_options do
    list_active_vehicle_types()
    |> Enum.map(fn vt -> vt.slug end)
  end

  # ── Pricing Plans ─────────────────────────────────────────

  def list_pricing_plans, do: Repo.all(PricingPlan)

  def get_pricing_plan!(id), do: Repo.get!(PricingPlan, id)

  def get_pricing_plan_by_vehicle_type(type) do
    Repo.get_by(PricingPlan, vehicle_type: type)
  end

  def create_pricing_plan(attrs) do
    %PricingPlan{}
    |> PricingPlan.changeset(attrs)
    |> Repo.insert()
  end

  def update_pricing_plan(%PricingPlan{} = plan, attrs) do
    plan
    |> PricingPlan.changeset(attrs)
    |> Repo.update()
  end

  def delete_pricing_plan(%PricingPlan{} = plan) do
    Repo.delete(plan)
  end

  def change_pricing_plan(%PricingPlan{} = plan, attrs \\ %{}) do
    PricingPlan.changeset(plan, attrs)
  end

  # ── Customers ─────────────────────────────────────────────

  def list_customers do
    Repo.all(from c in Customer, order_by: [desc: c.inserted_at], preload: [:parking_space])
  end

  def get_customer!(id) do
    Customer
    |> Repo.get!(id)
    |> Repo.preload(:parking_space)
  end

  def get_customer(id), do: Repo.get(Customer, id)

  def create_customer(attrs) do
    result =
      %Customer{}
      |> Customer.changeset(attrs)
      |> Repo.insert()

    case result do
      {:ok, customer} ->
        log_activity("customer_created", "New customer registered: #{customer.first_name} #{customer.last_name}", "customer", customer.id)
        {:ok, customer}

      error ->
        error
    end
  end

  def update_customer(%Customer{} = customer, attrs) do
    result =
      customer
      |> Customer.changeset(attrs)
      |> Repo.update()

    case result do
      {:ok, customer} ->
        log_activity("customer_updated", "Customer updated: #{customer.first_name} #{customer.last_name}", "customer", customer.id)
        {:ok, customer}

      error ->
        error
    end
  end

  def delete_customer(%Customer{} = customer) do
    # Release any assigned space first
    if space = Repo.get_by(ParkingSpace, customer_id: customer.id) do
      release_space(space)
    end

    result = Repo.delete(customer)

    case result do
      {:ok, customer} ->
        log_activity("customer_deleted", "Customer deleted: #{customer.first_name} #{customer.last_name}", "customer", customer.id)
        {:ok, customer}

      error ->
        error
    end
  end

  def change_customer(%Customer{} = customer, attrs \\ %{}) do
    Customer.changeset(customer, attrs)
  end

  def search_customers(query_string) do
    search = "%#{query_string}%"

    from(c in Customer,
      where:
        ilike(c.first_name, ^search) or
          ilike(c.last_name, ^search) or
          ilike(c.email, ^search) or
          ilike(c.vehicle_plate, ^search),
      order_by: [desc: c.inserted_at],
      preload: [:parking_space]
    )
    |> Repo.all()
  end

  def filter_customers(opts \\ %{}) do
    Customer
    |> maybe_filter_status(opts["status"])
    |> maybe_filter_vehicle_type(opts["vehicle_type"])
    |> maybe_search(opts["search"])
    |> order_by([c], desc: c.inserted_at)
    |> preload(:parking_space)
    |> Repo.all()
  end

  defp maybe_filter_status(query, nil), do: query
  defp maybe_filter_status(query, ""), do: query
  defp maybe_filter_status(query, "all"), do: query
  defp maybe_filter_status(query, status), do: where(query, [c], c.status == ^status)

  defp maybe_filter_vehicle_type(query, nil), do: query
  defp maybe_filter_vehicle_type(query, ""), do: query
  defp maybe_filter_vehicle_type(query, "all"), do: query
  defp maybe_filter_vehicle_type(query, type), do: where(query, [c], c.vehicle_type == ^type)

  defp maybe_search(query, nil), do: query
  defp maybe_search(query, ""), do: query

  defp maybe_search(query, search) do
    search = "%#{search}%"

    where(
      query,
      [c],
      ilike(c.first_name, ^search) or ilike(c.last_name, ^search) or
        ilike(c.email, ^search) or ilike(c.vehicle_plate, ^search)
    )
  end

  # ── Parking Spaces ────────────────────────────────────────

  def list_spaces do
    Repo.all(from s in ParkingSpace, order_by: s.number, preload: [:customer, :parking_lot])
  end

  def list_spaces_by_lot do
    list_spaces()
    |> Enum.group_by(& &1.parking_lot)
    |> Enum.sort_by(fn {lot, _} -> if lot, do: lot.name, else: "" end)
  end

  def get_space!(id) do
    ParkingSpace
    |> Repo.get!(id)
    |> Repo.preload([:customer, :parking_lot])
  end

  def create_space(attrs) do
    result =
      %ParkingSpace{}
      |> ParkingSpace.changeset(attrs)
      |> Repo.insert()

    case result do
      {:ok, space} ->
        space = Repo.preload(space, [:customer, :parking_lot])
        log_activity("space_created", "Parking space created: #{space.number}", "space", space.id)
        {:ok, space}

      error ->
        error
    end
  end

  def delete_space(%ParkingSpace{} = space) do
    if space.status == "available" do
      result = Repo.delete(space)

      case result do
        {:ok, space} ->
          log_activity("space_deleted", "Parking space deleted: #{space.number}", "space", space.id)
          {:ok, space}

        error ->
          error
      end
    else
      {:error, :not_available}
    end
  end

  def bulk_create_spaces(lot_id, prefix, start_num, end_num, vehicle_type, section \\ nil) do
    results =
      for i <- start_num..end_num do
        number = "#{prefix}#{String.pad_leading("#{i}", 3, "0")}"

        create_space(%{
          parking_lot_id: lot_id,
          number: number,
          vehicle_type: vehicle_type,
          section: section,
          status: "available"
        })
      end

    successes = Enum.filter(results, &match?({:ok, _}, &1))
    errors = Enum.filter(results, &match?({:error, _}, &1))

    {:ok, %{created: length(successes), errors: length(errors)}}
  end

  def get_available_spaces(vehicle_type \\ nil) do
    ParkingSpace
    |> where([s], s.status == "available")
    |> maybe_filter_space_vehicle_type(vehicle_type)
    |> order_by([s], s.number)
    |> preload([:parking_lot])
    |> Repo.all()
  end

  defp maybe_filter_space_vehicle_type(query, nil), do: query
  defp maybe_filter_space_vehicle_type(query, ""), do: query
  defp maybe_filter_space_vehicle_type(query, "all"), do: query
  defp maybe_filter_space_vehicle_type(query, type), do: where(query, [s], s.vehicle_type == ^type)

  def filter_spaces(opts \\ %{}) do
    ParkingSpace
    |> maybe_filter_lot(opts["lot_id"])
    |> maybe_filter_space_vehicle_type(opts["vehicle_type"])
    |> maybe_filter_space_status(opts["status"])
    |> maybe_search_space(opts["search"])
    |> order_by([s], s.number)
    |> preload([:customer, :parking_lot])
    |> Repo.all()
  end

  defp maybe_filter_lot(query, nil), do: query
  defp maybe_filter_lot(query, ""), do: query
  defp maybe_filter_lot(query, "all"), do: query

  defp maybe_filter_lot(query, lot_id) when is_binary(lot_id) do
    case Integer.parse(lot_id) do
      {id, ""} -> where(query, [s], s.parking_lot_id == ^id)
      _ -> query
    end
  end

  defp maybe_filter_lot(query, lot_id) when is_integer(lot_id) do
    where(query, [s], s.parking_lot_id == ^lot_id)
  end

  defp maybe_filter_space_status(query, nil), do: query
  defp maybe_filter_space_status(query, ""), do: query
  defp maybe_filter_space_status(query, "all"), do: query
  defp maybe_filter_space_status(query, status), do: where(query, [s], s.status == ^status)

  defp maybe_search_space(query, nil), do: query
  defp maybe_search_space(query, ""), do: query

  defp maybe_search_space(query, search) do
    search = "%#{search}%"
    where(query, [s], ilike(s.number, ^search) or ilike(s.section, ^search))
  end

  def assign_space(%ParkingSpace{} = space, %Customer{} = customer) do
    result =
      space
      |> ParkingSpace.changeset(%{customer_id: customer.id, status: "occupied"})
      |> Repo.update()

    case result do
      {:ok, space} ->
        log_activity("space_assigned", "Space #{space.number} assigned to #{customer.first_name} #{customer.last_name}", "space", space.id)
        {:ok, Repo.preload(space, [:customer, :parking_lot], force: true)}

      error ->
        error
    end
  end

  def release_space(%ParkingSpace{} = space) do
    result =
      space
      |> ParkingSpace.changeset(%{customer_id: nil, status: "available", reserved_from: nil, reserved_until: nil})
      |> Repo.update()

    case result do
      {:ok, space} ->
        log_activity("space_released", "Space #{space.number} released", "space", space.id)
        {:ok, Repo.preload(space, [:customer, :parking_lot], force: true)}

      error ->
        error
    end
  end

  def set_space_maintenance(%ParkingSpace{} = space) do
    result =
      space
      |> ParkingSpace.changeset(%{customer_id: nil, status: "maintenance", reserved_from: nil, reserved_until: nil})
      |> Repo.update()

    case result do
      {:ok, space} ->
        log_activity("space_maintenance", "Space #{space.number} set to maintenance", "space", space.id)
        {:ok, Repo.preload(space, [:customer, :parking_lot], force: true)}

      error ->
        error
    end
  end

  def mark_space_available(%ParkingSpace{} = space) do
    result =
      space
      |> ParkingSpace.changeset(%{status: "available"})
      |> Repo.update()

    case result do
      {:ok, space} ->
        log_activity("space_available", "Space #{space.number} marked as available", "space", space.id)
        {:ok, Repo.preload(space, [:customer, :parking_lot], force: true)}

      error ->
        error
    end
  end

  # ── Bookings ──────────────────────────────────────────────

  def list_bookings do
    Repo.all(from b in Booking, order_by: [desc: b.inserted_at], preload: [:customer, :space])
  end

  def get_booking!(id) do
    Booking
    |> Repo.get!(id)
    |> Repo.preload([:customer, :space])
  end

  def create_booking(attrs) do
    result =
      %Booking{}
      |> Booking.changeset(attrs)
      |> Repo.insert()

    case result do
      {:ok, booking} ->
        log_activity("booking_created", "New booking created", "booking", booking.id)
        {:ok, booking}

      error ->
        error
    end
  end

  def update_booking(%Booking{} = booking, attrs) do
    result =
      booking
      |> Booking.changeset(attrs)
      |> Repo.update()

    case result do
      {:ok, booking} ->
        log_activity("booking_updated", "Booking updated to #{attrs[:status] || booking.status}", "booking", booking.id)
        {:ok, booking}

      error ->
        error
    end
  end

  def preload_booking(%Booking{} = booking, associations) do
    Repo.preload(booking, associations)
  end

  # ── Pricing Calculation ──────────────────────────────────

  def calculate_price(vehicle_type, plan) do
    case get_pricing_plan_by_vehicle_type(vehicle_type) do
      nil ->
        0

      pricing ->
        case plan do
          "daily" -> pricing.price_daily || 0
          "weekly" -> pricing.price_weekly || 0
          "monthly" -> pricing.price_monthly || 0
          "yearly" -> pricing.price_yearly || 0
          _ -> 0
        end
    end
  end

  # ── Dashboard Stats ──────────────────────────────────────

  def dashboard_stats do
    total_spaces = Repo.aggregate(ParkingSpace, :count, :id)
    available = Repo.aggregate(from(s in ParkingSpace, where: s.status == "available"), :count, :id)
    occupied = Repo.aggregate(from(s in ParkingSpace, where: s.status == "occupied"), :count, :id)
    reserved = Repo.aggregate(from(s in ParkingSpace, where: s.status == "reserved"), :count, :id)
    maintenance = Repo.aggregate(from(s in ParkingSpace, where: s.status == "maintenance"), :count, :id)

    total_customers = Repo.aggregate(Customer, :count, :id)
    active_customers = Repo.aggregate(from(c in Customer, where: c.status == "active"), :count, :id)

    monthly_revenue = calculate_monthly_revenue()

    occupancy_rate =
      if total_spaces > 0 do
        round(occupied / total_spaces * 100)
      else
        0
      end

    %{
      total_spaces: total_spaces,
      available: available,
      occupied: occupied,
      reserved: reserved,
      maintenance: maintenance,
      total_customers: total_customers,
      active_customers: active_customers,
      monthly_revenue: monthly_revenue,
      occupancy_rate: occupancy_rate
    }
  end

  defp calculate_monthly_revenue do
    customers = Repo.all(from c in Customer, where: c.status == "active")

    Enum.reduce(customers, 0, fn customer, acc ->
      price = calculate_price(customer.vehicle_type, customer.plan)

      monthly =
        case customer.plan do
          "daily" -> price * 30
          "weekly" -> price * 4
          "monthly" -> price
          "yearly" -> div(price, 12)
          _ -> 0
        end

      acc + monthly
    end)
  end

  def recent_customers(limit \\ 5) do
    from(c in Customer, order_by: [desc: c.inserted_at], limit: ^limit, preload: [:parking_space])
    |> Repo.all()
  end

  # ── Activity Logs ─────────────────────────────────────────

  def list_recent_activities(limit \\ 10) do
    from(a in ActivityLog, order_by: [desc: a.inserted_at], limit: ^limit)
    |> Repo.all()
  end

  def log_activity(action, description, entity_type \\ nil, entity_id \\ nil) do
    %ActivityLog{}
    |> ActivityLog.changeset(%{
      action: action,
      description: description,
      entity_type: entity_type,
      entity_id: entity_id
    })
    |> Repo.insert()
  end

  # ── Site Settings ──────────────────────────────────────────

  def get_setting(key) do
    case Repo.get_by(SiteSetting, key: key) do
      nil -> SiteSetting.default_value(key)
      setting -> setting.value
    end
  end

  def get_setting_bool(key) do
    get_setting(key) == "true"
  end

  def set_setting(key, value) do
    case Repo.get_by(SiteSetting, key: key) do
      nil ->
        %SiteSetting{}
        |> SiteSetting.changeset(%{key: key, value: value})
        |> Repo.insert()

      setting ->
        setting
        |> SiteSetting.changeset(%{value: value})
        |> Repo.update()
    end
  end

  def list_settings do
    Repo.all(SiteSetting)
  end

  # ── Merch Items ────────────────────────────────────────────

  def list_merch_items do
    Repo.all(from m in MerchItem, order_by: m.sort_order)
  end

  def list_active_merch_items do
    Repo.all(from m in MerchItem, where: m.active == true, order_by: m.sort_order)
  end

  def get_merch_item!(id), do: Repo.get!(MerchItem, id)

  def create_merch_item(attrs) do
    result =
      %MerchItem{}
      |> MerchItem.changeset(attrs)
      |> Repo.insert()

    case result do
      {:ok, item} ->
        log_activity("merch_created", "Merch item created: #{item.name}", "merch", item.id)
        {:ok, item}

      error ->
        error
    end
  end

  def update_merch_item(%MerchItem{} = item, attrs) do
    result =
      item
      |> MerchItem.changeset(attrs)
      |> Repo.update()

    case result do
      {:ok, item} ->
        log_activity("merch_updated", "Merch item updated: #{item.name}", "merch", item.id)
        {:ok, item}

      error ->
        error
    end
  end

  def delete_merch_item(%MerchItem{} = item) do
    result = Repo.delete(item)

    case result do
      {:ok, item} ->
        log_activity("merch_deleted", "Merch item deleted: #{item.name}", "merch", item.id)
        {:ok, item}

      error ->
        error
    end
  end

  def change_merch_item(%MerchItem{} = item, attrs \\ %{}) do
    MerchItem.changeset(item, attrs)
  end

  def toggle_merch_item_active(%MerchItem{} = item) do
    update_merch_item(item, %{active: !item.active})
  end
end
