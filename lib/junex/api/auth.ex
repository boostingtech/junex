defmodule Junex.Auth do
  @moduledoc """
  Exposes the get_access_token function, to get the needed token to make all other requests
  """

  alias Tesla.Middleware.JSON

  import Junex.Utils,
    only: [
      get_auth_url: 1,
      kw_to_map: 1,
      parse_map: 2,
      check_mode: 1,
      auth_body: 0,
      check_status_code: 1,
      check_status_code: 2
    ]

  import Tesla, only: [post: 3]

  @doc """
  Return a access_token to be used on other Junex requests

  You can get the client_id and client_secret on the Integration section
  on your Juno account and generate the pair!
  """
  @spec get_access_token(Keyword.t()) ::
          {:ok, String.t()} | {:error, atom() | {atom(), atom()}}
  def get_access_token(opts) do
    with map <- kw_to_map(opts),
         :ok <- parse_map(map, [:mode, :client_id, :client_secret]),
         :ok <- check_mode(map[:mode]),
         {:ok, tesla_client} <- create_client(map[:client_id], map[:client_secret]),
         {:ok, response_env} <- post(tesla_client, get_auth_url(map[:mode]), auth_body()),
         {:ok, response} <- JSON.decode(response_env, keys: :string) do
      check_status_code(response, "access_token")
    else
      {:param_error, error} ->
        {:error, error}

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
