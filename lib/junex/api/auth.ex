defmodule Junex.Auth do
  @moduledoc """
  Exposes the get_access_token function, to get the needed token to make all other requests
  """

  alias Tesla.Middleware.JSON
  alias Junex.Utils
  import Tesla, only: [post: 3]

  @sandbox_auth_url Utils.sandbox_auth_url()
  @prod_auth_url Utils.prod_auth_url()

  @modes Utils.modes()

  @doc """
  Return a access_token to be used on other Junex requests

  You can get the client_id and client_secret on the Integration section
  on your Juno account and generate the pair!

  ## Parameters
    - client_id: string
    - client_secret: string
    - mode: :prod | :sandbox

  ## Examples

      Junex.Auth.get_access_token(client_id: "client_id", client_secret: "client_secret", mode: :mode)
  """
  @spec get_access_token(Keyword.t()) ::
          {:ok, String.t()} | {:error, atom() | {atom(), atom()}}
  def get_access_token(opts) when not Keyword.keyword?(opts), do: {:error, :expected_keyword}

  def get_access_token(opts) when not (Keyword.get(opts, :mode, nil) in @modes),
    do: {:error, :wrong_mode}

  def get_access_token(opts)
      when Keyword.get(opts, :client_id, nil) == nil or
             Keyword.get(opts, :client_secret, nil) == nil or
             Keyword.get(opts, :mode, nil) == nil,
      do: {:error, :missing_configs}

  def get_access_token(opts) when not is_atom(Keyword.get(opts, :mode)),
    do: {:error, :expected_atom}

  def get_access_token(opts)
      when not is_binary(Keyword.get(opts, :client_id)) or
             (not is_binary(Keyword.get(opts, :client_secret)) and
                is_atom(Keyword.get(opts, :mode))),
      do: {:error, :client_id_or_client_secret_not_a_string}

  def get_access_token(opts) do
    with {:ok, tesla_client} <- create_client(client_id, client_secret),
         {:ok, response_env} <- post(tesla_client, get_auth_url(mode), @body),
         {:ok, response} <- JSON.decode(response_env) do
      {:ok, response.body["access_token"]}
    else
      {:error, %{status: 401}} ->
        {:error, {:unauthenticated, :wrong_credentials}}

      {:error, %{status: 500, body: body}} ->
        {:error, body["error"]}

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
