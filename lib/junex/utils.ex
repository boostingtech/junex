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

  # ------- Junex Response Utils -------

  def check_status_code({:error, %{status: status, body: body}}) do
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

  def check_status_code({:ok, %{status, body}}) do
    case status do
      200 ->
        {:ok, body}

      201 ->
        {:ok, body}
    end
  end

  def check_status_code({:ok, %{status: status, body: body}}, key) do
    check_status_code({:ok, %{status: status, body: body[key]}})
  end

  def check_status_code({:ok, %{status: status, body: body}}, key1, key2) do
    check_status_code({:ok, %{status: status, body: body[key1][key2]}})
  end

  def get_conn_error(error), do: %{status: 500, body: %{"error" => error}}

  def get_atom_error, do: {:error, :expected_mode_to_be_valid}

  def get_client_error, do: {:error, :expected_tesla_client}
end
