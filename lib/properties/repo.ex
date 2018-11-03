defmodule Properties.Repo do
  use Ecto.Repo, otp_app: :properties, adapter: Ecto.Adapters.Postgres
end
