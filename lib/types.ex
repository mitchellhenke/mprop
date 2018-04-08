Postgrex.Types.define(Properties.PostgresTypes,
              [Geo.PostGIS.Extension] ++ Ecto.Adapters.Postgres.extensions(),
              json: Poison)
