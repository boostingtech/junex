defmodule JunoWrapper.Auth do
  alias Tesla.Middleware.JSON
  import Tesla, only: [post: 3]

  @sandbox_auth_url "https://sandbox.boletobancario.com/authorization-server/oauth/token"
  @prod_auth_url "https://api.juno.com.br/authorization-server/oauth/token"

  # @body "grant_type: :client_credentials"
  @body %{grant_type: :client_credentials}

  def get_access_token(client_id, client_secret, is_sandbox) do
    client = create_client(client_id, client_secret)

    {:ok, response} =
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

    response.body["access_token"]
  end

  defp create_client(client_id, client_secret) do
    Tesla.client([
      Tesla.Middleware.FormUrlencoded,
      {Tesla.Middleware.BasicAuth, %{username: client_id, password: client_secret}},
      {Tesla.Middleware.Headers, [{"content-type", "application/x-www-form-urlencoded"}]}
    ])
  end
end
