defmodule JumboParking.Repo do
  use Ecto.Repo,
    otp_app: :jumbo_parking,
    adapter: Ecto.Adapters.Postgres
end
