defmodule Junex.Client do
  @moduledoc """
  Provides access integration to create a custom Tesla client
  """

  import Junex.Utils, only: [kw_to_map: 1, parse_map: 2, version: 0]

  @doc """
  Returns a new client to perform other requests!
  """
  @spec create(Keyword.t()) :: {:ok, %Tesla.Client{}}
  def create(kw) do
    with map <- kw_to_map(kw),
         :ok <- parse_map(map, [:access_token, :resource_token]) do
      client =
        Tesla.client([
          Tesla.Middleware.JSON,
          {Tesla.Middleware.Headers,
           [
             {"authorization", "Bearer #{map[:access_token]}"},
             {"X-Resource-Token", map[:resource_token]},
             {"user-agent", "junex/#{version()}"},
             {"X-Api-Version", 2}
           ]}
        ])

      {:ok, client}
    else
      error ->
        error
    end
  end
end
