defmodule JunoWrapper.Auth do
  @moduledoc """
  Exposes the get_access_token function, to get the needed token to make all other requests
  """

  alias Tesla.Middleware.JSON
  import Tesla, only: [post: 3]

  @sandbox_auth_url "https://sandbox.boletobancario.com/authorization-server/oauth/token"
  @prod_auth_url "https://api.juno.com.br/authorization-server/oauth/token"

  # @body "grant_type: :client_credentials"
  @body %{grant_type: :client_credentials}

  def get_access_token(client_id, client_secret, is_sandbox) do
    client = create_client(client_id, client_secret)

    {:ok, %{status: status} = response} =
      case is_sandbox do
        true ->
          {:ok, env} = post(client, @sandbox_auth_url, @body)
          env

        false ->
          {:ok, env} = post(client, @prod_auth_url, @body)
          env

        _ ->
          {:error, "Expected \"is_sandbox\" to be a boolean"}
      end
      |> JSON.decode(keys: :atoms)

    case status do
      400 ->
        {:error, "Missing \"grant_type: client_credentials\" body"}

      401 ->
        {:error, "Unauthenticated, wrong credentials"}

      200 ->
        {:ok, response.body[:access_token]}

      _ ->
        :error
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
