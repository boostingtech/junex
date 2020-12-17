defmodule Junex.API.Charge do
  @moduledoc """
  Provides access interface for managing charges.
  """

  import Junex.Utils, except: [get_auth_url: 1, auth_body: 0]

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
  @spec get_charge_info(Keyword.t()) :: total_charge_info()
  def get_charge_info(kw)
      when is_binary(Keyword.get(kw, :description)) and
             is_integer(Keyword.get(kw, :installments)) and
             Keyword.get(kw, :installments) > 0 and
             Keyword.get(kw, :payment_type) in payment_types() and
             is_float(Keyword.get(kw, :amount)) do
    if installments == 1, do: do_get_charge_info(kw), else: do_get_total_charge_info(kw)
  end

  defp do_get_charge_info(kw) do
    description = Keyword.get(kw, :description)
    payment_type = Keyword.get(kw, :payment_type)
    amount = Keyword.get(kw, :amount)
    installments = Keyword.get(kw, :installments) || 1

    case payment_type do
      :boleto ->
        %{
          description: description,
          installments: installments,
          paymentTypes: ["BOLETO"],
          amount: amount
        }

      :credit_card ->
        %{
          description: description,
          installments: installments,
          paymentTypes: ["CREDIT_CARD"],
          amount: amount
        }
    end
  end

  defp do_get_total_charge_info(kw) do
    description = Keyword.get(kw, :description)
    payment_type = Keyword.get(kw, :payment_type)
    amount = Keyword.get(kw, :amount)
    installments = Keyword.get(kw, :installments) || 1

    case payment_type do
      :boleto ->
        %{
          description: description,
          installments: installments,
          paymentTypes: ["BOLETO"],
          amount: amount
        }

      :credit_card ->
        %{
          description: description,
          installments: installments,
          paymentTypes: ["CREDIT_CARD"],
          amount: amount
        }
    end
  end

  @doc """
  Return a new charge_billing_info map to be used on Junex.create_charges/2
  """
  @spec get_charge_billing_info(Keyword.t()) :: charge_billing_info()
  def get_charge_billing_info(kw)
      when is_binary(Keyword.get(kw, :name)) and
             is_binary(Keyword.get(kw, :document)) and
             is_binary(Keyword.get(kw, :email)) and
             is_binary(Keyword.get(kw, :phone)) do
    %{
      name: Keyword.get(kw, :name),
      document: Keyword.get(kw, :document),
      email: Keyword.get(kw, :email),
      phone: Keyword.get(kw, :phone)
    }
  end

  @doc """
  Creates and return a new charge
  """
  @spec create_charges(%Tesla.Client{}, Keyword.t()) ::
          {:ok, map()} | {:error, atom() | String.t() | {atom(), atom()}}
  def create_charges(%Tesla.Client{} = client, kw)
      when is_map(Keyword.get(kw, :charge_info)) and
             is_map(Keyword.get(kw, :billing)) and
             Keyword.get(kw, :mode) in modes do
    charge_info = Keyword.get(kw, :charge_info)
    billing = Keyword.get(kw, :billing)
    mode = Keyword.get(kw, :mode)

    charge_body = %{charge: charge_info, billing: billing}

    with {:ok, response_env} <- post(client, get_url(mode) <> "/charges", charge_body),
         {:ok, response} <- JSON.decode(response_env, keys: :string) do
      check_status_code(status, body, "_embedded", "charges")
    else
      error ->
        check_status_code(error)
    end
  end

  def create_charges(_client, _), do: {:error, :wrong_opts}

  @doc """
  Returns the latest charge status

  ## Parameters
    - client: Got from Junex.Client.create/2
    - charge_id: One of results do Junex.Client.create_charges/4
    - mode: :prod | :sandbox
  """
  @spec check_charge_status(%Tesla.Client{}, Keyword.t()) :: {:ok, map()}
  def check_charge_status(%Tesla.Client{} = client, kw)
      when is_binary(Keyword.get(kw, :client_id)) and Keyword.get(kw, :mode) in modes() do
    charge_id = Keyword.get(kw, :charge_id)
    mode = Keyword.get(kw, :mode)

    with {:ok, response_env} <- get(client, get_url(mode) <> "/charges/#{charge_id}", []),
         {:ok, response} <- JSON.decode(keys: :string) do
      check_status_code(response)
    else
      error -> check_status_code(error)
    end
  end

  def check_charge_status(_client, _), do: {:error, :wrong_opts}
end
