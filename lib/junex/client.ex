defmodule Junex.Client do
  @moduledoc false

  alias Junex.Config

  import Junex.Utils, only: [version: 0]

  @doc """
  Same as `Junex.create_client/1` however uses config from `config.exs`
  """
  def create(access_token) when is_binary(access_token) do
    config = Config.get()

    with {:ok, _config} <- Config.parse_config(config, [:resource_token]),
         {:ok, client} <-
           create(access_token, config[:resource_token]) do
      {:ok, client}
    else
      error ->
        error
    end
  end

  @doc """
  Returns a new client to perform other requests!
  """
  @spec create(String.t(), String.t()) :: {:ok, %Tesla.Client{}}
  def create(access_token, resource_token)
      when is_binary(access_token) and is_binary(resource_token) do
    client =
      Tesla.client([
        Tesla.Middleware.JSON,
        {Tesla.Middleware.Headers,
         [
           {"authorization", "Bearer #{access_token}"},
           {"X-Resource-Token", resource_token},
           {"user-agent", "junex/#{version()}"},
           {"X-Api-Version", 2}
         ]}
      ])

    {:ok, client}
  end
end
