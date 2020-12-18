defmodule Junex.Auth do
  @moduledoc """
  Exposes the get_access_token function, to get the needed token to make all other requests
  """

  alias Tesla.Middleware.JSON
  alias Junex.Config

  import Junex.Utils

  import Tesla, only: [post: 3]

  @doc """
  Same as Junex.get_access_token/1, however, uses config from `config.exs` 
  """
  def get_access_token do
    config = Config.get()

    with {:ok, config} <- Config.parse_config(config, [:client_id, :client_secret]),
         {:ok, result} <-
           get_access_token(
             client_id: Keyword.get(config, :client_id),
             client_secret: Keyword.get(config, :client_secret),
             mode: Keyword.get(config, :mode)
           ) do
      {:ok, result}
    else
      error ->
        error
    end
  end

  @doc """
  Return a access_token to be used on other Junex requests

  You can get the client_id and client_secret on the Integration section
  on your Juno account and generate the pair!
  """
  @spec get_access_token(Keyword.t()) ::
          {:ok, String.t()} | {:error, atom() | {atom(), atom()}}
  def get_access_token(params) do
    with {:ok, kw} <- parse_kw(params, [:mode, :client_id, :client_secret]),
         :ok <- check_mode(kw[:mode]),
         {:ok, tesla_client} <- create_client(kw[:client_id], kw[:client_secret]),
         {:ok, response_env} <- post(tesla_client, get_auth_url(kw[:mode]), auth_body()),
         {:ok, response} <- JSON.decode(response_env, keys: :string) do
      check_status_code({:ok, response}, "access_token")
    else
      {:param_error, error} ->
        {:error, error}

      {:error, {JSON, _, _}} ->
        parse_json_error()

      error ->
        check_status_code(error)
    end
  end

  defp create_client(client_id, client_secret) do
    client =
      Tesla.client([
        Tesla.Middleware.FormUrlencoded,
        {Tesla.Middleware.BasicAuth, %{username: client_id, password: client_secret}},
        {Tesla.Middleware.Headers, [{"content-type", "application/x-www-form-urlencoded"}]}
      ])

    {:ok, client}
  end
end
