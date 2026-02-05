alias JumboParking.Repo
alias JumboParking.Accounts
alias JumboParking.Parking.{PricingPlan, Customer, ParkingSpace, ActivityLog}

import Ecto.Query

# ── Admin User ──────────────────────────────────────────────

IO.puts("Creating admin user...")

{:ok, admin} =
  Accounts.register_user(%{email: "admin@jumboparking.com"})

admin
|> Ecto.Changeset.change(%{
  hashed_password: Bcrypt.hash_pwd_salt("admin123456789"),
  confirmed_at: DateTime.utc_now(:second),
  role: "superadmin"
})
|> Repo.update!()

IO.puts("  Admin user created: admin@jumboparking.com / admin123456789")

# ── Pricing Plans ───────────────────────────────────────────

IO.puts("Creating pricing plans...")

Repo.insert!(%PricingPlan{
  vehicle_type: "truck",
  vehicle_name: "Truck & Trailer",
  description: "Secure parking for tractor-trailers and large commercial vehicles",
  price_daily: 2000,
  price_weekly: 7500,
  price_monthly: 15000,
  price_yearly: 150_000,
  savings: %{"weekly" => "37%", "monthly" => "50%", "yearly" => "17%"},
  features: [
    "24/7 secure access",
    "Surveillance cameras",
    "Loading dock access",
    "Large laydown yards",
    "Cargo transfer facilities"
  ]
})

Repo.insert!(%PricingPlan{
  vehicle_type: "rv",
  vehicle_name: "RV",
  description: "Safe long-term storage for recreational vehicles",
  price_daily: nil,
  price_weekly: nil,
  price_monthly: 12000,
  price_yearly: 120_000,
  savings: %{"yearly" => "17%"},
  features: [
    "24/7 secure access",
    "Surveillance cameras",
    "Wide parking spaces",
    "Easy in/out access",
    "Long-term storage"
  ]
})

Repo.insert!(%PricingPlan{
  vehicle_type: "car",
  vehicle_name: "Car or SUV",
  description: "Convenient parking for cars and SUVs",
  price_daily: nil,
  price_weekly: nil,
  price_monthly: 7000,
  price_yearly: 70_000,
  savings: %{"yearly" => "17%"},
  features: [
    "24/7 secure access",
    "Surveillance cameras",
    "Covered parking options",
    "Easy access",
    "Monthly & yearly plans"
  ]
})

IO.puts("  3 pricing plans created")

# ── Customers ───────────────────────────────────────────────

IO.puts("Creating customers...")

first_names = ~w(John Jane Michael Sarah David Emily Robert Lisa James Maria)
last_names = ~w(Smith Johnson Williams Brown Jones Garcia Miller Davis Rodriguez Martinez)
companies = ["Richardson Transport", "Columbia Logistics", "SC Hauling", "Palmetto Moving", "Metro Freight", nil, nil, nil, nil, nil]
vehicle_models = ["Toyota Camry", "Honda Accord", "Ford F-150", "BMW X5", "Tesla Model 3", "Freightliner Cascadia", "Winnebago Adventurer", "Peterbilt 579", "Airstream Classic", "Chevy Silverado"]

customers =
  for i <- 1..30 do
    vehicle_type = Enum.at(~w(truck rv car), rem(i, 3))

    plan = case vehicle_type do
      "truck" -> Enum.at(~w(daily weekly monthly yearly), rem(i, 4))
      _ -> Enum.at(~w(monthly yearly), rem(i, 2))
    end

    status = if i <= 27, do: "active", else: "pending"

    Repo.insert!(%Customer{
      first_name: Enum.at(first_names, rem(i, length(first_names))),
      last_name: Enum.at(last_names, rem(i, length(last_names))),
      email: "customer#{i}@example.com",
      phone: "(803) 555-#{String.pad_leading("#{1000 + i}", 4, "0")}",
      company: Enum.at(companies, rem(i, length(companies))),
      vehicle_plate: "SC-#{String.pad_leading("#{i * 111}", 4, "0")}",
      vehicle_model: Enum.at(vehicle_models, rem(i, length(vehicle_models))),
      vehicle_type: vehicle_type,
      plan: plan,
      status: status,
      notes: if(rem(i, 7) == 0, do: "VIP customer", else: nil)
    })
  end

IO.puts("  #{length(customers)} customers created")

# ── Parking Spaces ──────────────────────────────────────────

IO.puts("Creating parking spaces...")

zones = [
  {"Zone A - Trucks", "A", 20},
  {"Zone B - RVs", "B", 15},
  {"Zone C - Cars", "C", 15}
]

all_spaces =
  for {zone_name, prefix, count} <- zones, i <- 1..count do
    number = "#{prefix}#{String.pad_leading("#{i}", 3, "0")}"

    Repo.insert!(%ParkingSpace{
      number: number,
      zone: zone_name,
      status: "available"
    })
  end

IO.puts("  #{length(all_spaces)} parking spaces created")

# ── Assign spaces to customers ──────────────────────────────

IO.puts("Assigning spaces to customers...")

active_customers = Enum.filter(customers, &(&1.status == "active"))
available_spaces = all_spaces

# Assign 30 spaces to active customers
{assigned, _remaining} =
  Enum.reduce(Enum.take(active_customers, 30), {0, available_spaces}, fn customer, {count, spaces} ->
    case spaces do
      [space | rest] ->
        space
        |> Ecto.Changeset.change(%{customer_id: customer.id, status: "occupied"})
        |> Repo.update!()

        {count + 1, rest}

      [] ->
        {count, []}
    end
  end)

IO.puts("  #{assigned} spaces assigned to customers")

# Reserve 10 spaces
remaining_spaces = Repo.all(
  from s in ParkingSpace,
  where: s.status == "available",
  limit: 10
)

for space <- Enum.take(remaining_spaces, 10) do
  space
  |> Ecto.Changeset.change(%{
    status: "reserved",
    reserved_from: Date.utc_today(),
    reserved_until: Date.add(Date.utc_today(), 30)
  })
  |> Repo.update!()
end

IO.puts("  10 spaces reserved")

# ── Activity Logs ───────────────────────────────────────────

IO.puts("Creating activity logs...")

activities = [
  {"customer_created", "New customer registered: John Smith", "customer", 1},
  {"space_assigned", "Space A001 assigned to John Smith", "space", 1},
  {"booking_created", "New booking request from Jane Johnson", "booking", 1},
  {"customer_created", "New customer registered: Michael Williams", "customer", 3},
  {"space_assigned", "Space A003 assigned to Michael Williams", "space", 3},
  {"space_released", "Space B005 released", "space", 20},
  {"customer_updated", "Customer Sarah Brown updated plan to yearly", "customer", 4},
  {"booking_created", "New booking request from David Jones", "booking", 2},
  {"space_assigned", "Space C010 assigned to Emily Garcia", "space", 40},
  {"customer_created", "New customer registered: Robert Miller", "customer", 7}
]

now = DateTime.utc_now(:second)

for {idx, {action, description, entity_type, entity_id}} <- Enum.with_index(activities) do
  inserted_at = DateTime.add(now, -(idx * 120 + idx * 60), :second)

  Repo.insert!(%ActivityLog{
    action: action,
    description: description,
    entity_type: entity_type,
    entity_id: entity_id,
    inserted_at: inserted_at
  })
end

IO.puts("  #{length(activities)} activity logs created")

IO.puts("\nSeed data complete!")
IO.puts("  Admin login: admin@jumboparking.com / admin123456789")
IO.puts("  Visit http://localhost:4000 for the public site")
IO.puts("  Visit http://localhost:4000/admin/login for admin panel")
