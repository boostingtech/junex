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

  @behaviour JunoWrapper.Auth.Callback

  @impl true
  def get_access_token(client_id, client_secret, is_sandbox) do
    {:ok, tesla_client} = client().build(client_id, client_secret)

    {:ok, %{status: status} = response} =
      case is_sandbox do
        true ->
          {:ok, env} = post(tesla_client, @sandbox_auth_url, @body)
          env

        false ->
          {:ok, env} = post(tesla_client, @prod_auth_url, @body)
          env

        _ ->
          {:error, "Expected \"is_sandbox\" to be a boolean"}
      end
      |> JSON.decode(keys: :atoms)

    case status do
      400 ->
        {:error, :missing_grant_type_body}

      401 ->
        {:error, {:unauthenticated, :wrong_credentials}}

      200 ->
        {:ok, response.body[:access_token]}

      _ ->
        {:error, :unkown_error}
    end
  end

  defp client do
    Application.get_env(:juno_wrapper, :auth_client)
  end
end
