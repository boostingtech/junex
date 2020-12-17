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
  def prod_url, do: @prod_url
  def sandbox_url, do: @sandbox_url
  def prod_auth_url, do: @prod_auth_url
  def sandbox_auth_url, do: @sandbox_auth_url
  def @payment_types, do: @payment_types
end
