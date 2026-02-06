defmodule JumboParking.Parking do
  @moduledoc """
  The Parking context - all business logic for spaces, customers, bookings, pricing, and activity.
  """

  import Ecto.Query, warn: false
  alias JumboParking.Repo

  alias JumboParking.Parking.{PricingPlan, Customer, ParkingSpace, Booking, ActivityLog}

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
    Repo.all(from s in ParkingSpace, order_by: s.number, preload: [:customer])
  end

  def list_spaces_by_zone do
    list_spaces()
    |> Enum.group_by(& &1.zone)
    |> Enum.sort_by(fn {zone, _} -> zone end)
  end

  def get_space!(id) do
    ParkingSpace
    |> Repo.get!(id)
    |> Repo.preload(:customer)
  end

  def create_space(attrs) do
    %ParkingSpace{}
    |> ParkingSpace.changeset(attrs)
    |> Repo.insert()
  end

  def get_available_spaces(zone \\ nil) do
    ParkingSpace
    |> where([s], s.status == "available")
    |> maybe_filter_zone(zone)
    |> order_by([s], s.number)
    |> Repo.all()
  end

  defp maybe_filter_zone(query, nil), do: query
  defp maybe_filter_zone(query, ""), do: query
  defp maybe_filter_zone(query, "all"), do: query
  defp maybe_filter_zone(query, zone), do: where(query, [s], s.zone == ^zone)

  def filter_spaces(opts \\ %{}) do
    ParkingSpace
    |> maybe_filter_zone(opts["zone"])
    |> maybe_filter_space_status(opts["status"])
    |> maybe_search_space(opts["search"])
    |> order_by([s], s.number)
    |> preload(:customer)
    |> Repo.all()
  end

  defp maybe_filter_space_status(query, nil), do: query
  defp maybe_filter_space_status(query, ""), do: query
  defp maybe_filter_space_status(query, "all"), do: query
  defp maybe_filter_space_status(query, status), do: where(query, [s], s.status == ^status)

  defp maybe_search_space(query, nil), do: query
  defp maybe_search_space(query, ""), do: query

  defp maybe_search_space(query, search) do
    search = "%#{search}%"
    where(query, [s], ilike(s.number, ^search) or ilike(s.zone, ^search))
  end

  def assign_space(%ParkingSpace{} = space, %Customer{} = customer) do
    result =
      space
      |> ParkingSpace.changeset(%{customer_id: customer.id, status: "occupied"})
      |> Repo.update()

    case result do
      {:ok, space} ->
        log_activity("space_assigned", "Space #{space.number} assigned to #{customer.first_name} #{customer.last_name}", "space", space.id)
        {:ok, Repo.preload(space, :customer, force: true)}

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
        {:ok, Repo.preload(space, :customer, force: true)}

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
        {:ok, Repo.preload(space, :customer, force: true)}

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
        {:ok, Repo.preload(space, :customer, force: true)}

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
end
