defmodule Junex.Auth do
  @moduledoc """
  Exposes the get_access_token function, to get the needed token to make all other requests
  """

  alias Tesla.Middleware.JSON
  import Tesla, only: [post: 3]

  @sandbox_auth_url "https://sandbox.boletobancario.com/authorization-server/oauth/token"
  @prod_auth_url "https://api.juno.com.br/authorization-server/oauth/token"

  @body %{grant_type: :client_credentials}

  @doc """
  Return a access_token to be used on other Junex requests

  You can get the client_id and client_secret on the Integration section
  on your Juno account and generate the pair!

  ## Parameters
    - client_id: string
    - client_secret: string
    - mode: :prod | :sandbox

  ## Examples

      Junex.Auth.get_access_token("client_id", "client_secret", true)
  """
  @spec get_access_token(String.t(), String.t(), atom()) ::
          {:ok, String.t()} | {:error, atom() | {atom(), atom()}}
  def get_access_token(_client_id, _client_secret, mode) when not is_atom(mode),
    do: {:error, :expected_atom}

  def get_access_token(client_id, client_secret, mode)
      when not is_binary(client_id) or (not is_binary(client_secret) and is_atom(mode)),
      do: {:error, :client_id_or_client_secret_not_a_string}

  def get_access_token(client_id, client_secret, mode) do
    with {:ok, tesla_client} <- create_client(client_id, client_secret),
         {:ok, response_env} <- post(tesla_client, get_auth_url(mode), @body),
         {:ok, response} <- JSON.decode(response_env) do
      {:ok, response.body["access_token"]}
    else
      {:error, %{status: 401}} ->
        {:error, {:unauthenticated, :wrong_credentials}}

      {:error, %{status: 500}} ->
        {:error, response.body["error"]}

      _ ->
        {:error, :unkown_error}
    end
  end

  @doc """
  Same as get_access_token/3 but raises if any error occurs
  """
  def get_access_token!(client_id, client_secret, mode) do
    case get_access_token(client_id, client_secret, mode) do
      {:ok, token} ->
        token

      {:error, error} ->
        raise "Error on getting access_token: #{error}"
    end
  end

  defp get_auth_url(:sandbox), do: @sandbox_auth_url
  defp get_auth_url(:prod), do: @prod_auth_url

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
