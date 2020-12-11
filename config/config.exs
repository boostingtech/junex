use Mix.Config

config :junex, :adapter, Tesla.Adapter.Hackney

import_config "#{Mix.env()}.exs"
