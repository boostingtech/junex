defmodule Junex.Utils do
  @moduledoc """
  Provides common configs
  """

  @sandbox_auth_url "https://sandbox.boletobancario.com/authorization-server/oauth/token"
  @prod_auth_url "https://api.juno.com.br/authorization-server/oauth/token"
  @auth_body %{grant_type: :client_credentials}

  @prod_url "https://api.juno.com.br"
  @sandbox_url "https://sandbox.boletobancario.com/api-integration"

  @version Mix.Project.config()[:version]

  @payment_types [:boleto, :credit_card]

  @modes [:prod, :sandbox]

  def modes, do: @modes
  def version, do: @version
  def auth_body, do: @auth_body
  def payment_types, do: @payment_types

  def get_url(:prod), do: @prod_url
  def get_url(:sandbox), do: @sandbox_url
  def get_auth_url(:sandbox), do: @sandbox_auth_url
  def get_auth_url(:prod), do: @prod_auth_url

  def parse_kw(kw, required_keys) do
    kw_keys = Keyword.keys(kw)

    if Enum.sort(kw_keys) != Enum.sort(required_keys) do
      {:param_error, :wrong_params}
    else
      {:ok, kw}
    end
  end

  def check_mode(mode) do
    if mode in modes() do
      :ok
    else
      {:param_error, :invalid_mode}
    end
  end

  def check_payment_type(pt) do
    if pt in payment_types() do
      :ok
    else
      {:param_error, :invalid_payment_type}
    end
  end

  # ------- Junex Response Utils -------

  def check_status_code({:error, %Tesla.Env{status: status, body: body}}) do
    case status do
      401 ->
        {:error, :unauthenticated}

      422 ->
        {:error, :unprocessable_entity}

      400 ->
        {:error, {:bad_request, :invalid_request_data}}

      500 ->
        {:error, body["error"] || :internal_server_error}

      _ ->
        {:error, :unkown_error}
    end
  end

  def check_status_code({:ok, %Tesla.Env{status: status, body: body}}) do
    case status do
      200 ->
        {:ok, body}

      201 ->
        {:ok, body}
    end
  end

  def check_status_code({:ok, %Tesla.Env{status: status, body: body}}, key) do
    check_status_code({:ok, %Tesla.Env{status: status, body: body[key]}})
  end

  def check_status_code({:ok, %Tesla.Env{status: status, body: body}}, key1, key2) do
    check_status_code({:ok, %Tesla.Env{status: status, body: body[key1][key2]}})
  end

  # ------- Junex Error Utils -------

  def parse_json_error, do: {:error, :json_parsing_failed}
end
