defmodule Junex.Auth.HTTP do
  @moduledoc """
  Exposes the get_access_token function, to get the needed token to make all other requests
  """

  alias Tesla.Middleware.JSON
  import Tesla, only: [post: 3]

  @sandbox_auth_url "https://sandbox.boletobancario.com/authorization-server/oauth/token"
  @prod_auth_url "https://api.juno.com.br/authorization-server/oauth/token"

  @body %{grant_type: :client_credentials}

  @behaviour Junex.Auth.Callback

  @impl true

  def get_access_token(_client_id, _client_secret, is_sandbox) when not is_boolean(is_sandbox),
    do: {:error, :expected_boolean}

  def get_access_token(client_id, client_secret, is_sandbox)
      when not is_binary(client_id) or (not is_binary(client_secret) and is_boolean(is_sandbox)),
      do: {:error, :client_id_or_client_secret_not_a_string}

  def get_access_token(client_id, client_secret, is_sandbox) do
    tesla_client = create_client(client_id, client_secret)

    {:ok, %{status: status} = response} =
      case is_sandbox do
        true ->
          with {:ok, env} <- post(tesla_client, @sandbox_auth_url, @body) do
            env
          else
            {:error, error} ->
              %{status: 500, body: %{"error" => error}}
          end

        false ->
          with {:ok, env} <- post(tesla_client, @prod_auth_url, @body) do
            env
          else
            {:error, error} ->
              %{status: 500, body: %{"error" => error}}
          end
      end
      |> JSON.decode(keys: :atoms)

    case status do
      401 ->
        {:error, {:unauthenticated, :wrong_credentials}}

      200 ->
        {:ok, response.body[:access_token]}

      500 ->
        {:error, response.body[:error]}

      _ ->
        {:error, :unkown_error}
    end
  end

  defp create_client(client_id, client_secret) do
    Tesla.client([
      Tesla.Middleware.FormUrlencoded,
      {Tesla.Middleware.BasicAuth, %{username: client_id, password: client_secret}},
      {Tesla.Middleware.Headers, [{"content-type", "application/x-www-form-urlencoded"}]}
    ])
  end
end
