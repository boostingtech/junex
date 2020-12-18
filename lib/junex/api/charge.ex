defmodule Junex.API.Charge do
  @moduledoc """
  Provides access interface for managing charges.
  """

  alias Tesla.Middleware.JSON

  import Tesla, only: [post: 3, get: 3]

  import Junex.Utils

  @type total_charge_info :: %{
          description: String.t(),
          installments: integer(),
          totalAmount: float(),
          paymentTypes: String.t()
        }
  @type charge_info :: %{
          description: String.t(),
          installments: integer(),
          amount: float(),
          paymentTypes: String.t()
        }
  @type charge_billing_info :: %{
          name: String.t(),
          document: String.t(),
          email: String.t(),
          phone: String.t()
        }

  @doc """
  Returns a charge_info map to be used on Junex.create_charges/2
  """
  @spec get_charge_info(Keyword.t()) :: total_charge_info() | {:error, atom()}
  def get_charge_info(kw) do
    with map <- kw_to_map(kw),
         :ok <- parse_map(map, [:descriptions, :installments, :payment_type, :amount]),
         :ok <- check_installments(map[:installments]),
         :ok <- check_payment_type(map[:payment_type]) do
      if map[:installments] == 1, do: do_get_charge_info(map), else: do_get_total_charge_info(map)
    else
      {:error, error} ->
        {:error, error}

      {:param_error, error} ->
        {:error, error}
    end
  end

  defp do_get_charge_info(map) do
    case map[:payment_type] do
      :boleto ->
        %{
          description: map[:description],
          installments: map[:installments],
          paymentTypes: ["BOLETO"],
          amount: map[:amount]
        }

      :credit_card ->
        %{
          description: map[:description],
          installments: map[:installments],
          paymentTypes: ["CREDIT_CARD"],
          amount: map[:amount]
        }
    end
  end

  defp do_get_total_charge_info(map) do
    case map[:payment_type] do
      :boleto ->
        %{
          description: map[:description],
          installments: map[:installments],
          paymentTypes: ["BOLETO"],
          amount: map[:amount]
        }

      :credit_card ->
        %{
          description: map[:description],
          installments: map[:installments],
          paymentTypes: ["CREDIT_CARD"],
          amount: map[:amount]
        }
    end
  end

  @doc """
  Return a new charge_billing_info map to be used on Junex.create_charges/2
  """
  @spec get_charge_billing_info(Keyword.t()) :: charge_billing_info()
  def get_charge_billing_info(kw) do
    with map <- kw_to_map(kw),
         :ok <- parse_map(map, [:name, :document, :email, :phone]) do
      %{
        name: Keyword.get(kw, :name),
        document: Keyword.get(kw, :document),
        email: Keyword.get(kw, :email),
        phone: Keyword.get(kw, :phone)
      }
    else
      error ->
        error
    end
  end

  @doc """
  Creates and return a new charge
  """
  @spec create_charges(%Tesla.Client{}, Keyword.t()) ::
          {:ok, map()} | {:error, atom() | String.t() | {atom(), atom()}}
  def create_charges(%Tesla.Client{} = client, kw) do
    with map <- kw_to_map(kw),
         :ok <- parse_map(map, [:mode, :charge_info, :billing]),
         :ok <- check_mode(map[:mode]),
         charge_body <- %{charge: map[:charge_info], billing: map[:billing]},
         {:ok, response_env} <- post(client, get_url(map[:mode]) <> "/charges", charge_body),
         {:ok, response} <- JSON.decode(response_env, keys: :string) do
      check_status_code({:ok, response}, "_embedded", "charges")
    else
      {:param_error, error} ->
        {:error, error}

      {:error, {JSON, _, _}} ->
        parse_json_error()

      error ->
        check_status_code(error)
    end
  end

  @doc """
  Returns the latest charge status
  """
  @spec check_charge_status(%Tesla.Client{}, Keyword.t()) :: {:ok, map()}
  def check_charge_status(%Tesla.Client{} = client, kw) do
    with map <- kw_to_map(kw),
         :ok <- parse_map(map, [:charge_id, :mode]),
         :ok <- check_mode(map[:mode]),
         {:ok, response_env} <-
           get(client, get_url(map[:mode]) <> "/charges/#{map[:charge_id]}", []),
         {:ok, response} <- JSON.decode(response_env, keys: :string) do
      check_status_code({:ok, response})
    else
      {:param_error, error} ->
        {:error, error}

      {:error, {JSON, _, _}} ->
        parse_json_error()

      error ->
        check_status_code(error)
    end
  end

  defp check_installments(installments) do
    if(installments < 1, do: {:error, :invalid_installments_number}, else: :ok)
  end
end
