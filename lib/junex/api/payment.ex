defmodule Junex.API.Payment do
  @moduledoc false

  alias Tesla.Middleware.JSON

  import Tesla, only: [post: 3]

  import Junex.Utils

  @type card_info :: %{
          creditCardHash: String.t()
        }
  @type payment_billing_info :: %{
          email: String.t(),
          address: %{
            street: String.t(),
            number: integer(),
            complement: String.t(),
            city: String.t(),
            state: String.t(),
            postCode: String.t()
          }
        }
  @type payment_info :: %{
          chargeId: String.t(),
          billing: payment_billing_info(),
          creditCardDetails: card_info()
        }

  @doc """
  Returns a payment_billing_info map to use on Junex.get_payment_info/1
  """
  @spec get_payment_billing_info(Keyword.t()) :: payment_billing_info()
  def get_payment_billing_info(params) do
    required_fields = [:email, :st_number, :street, :complement, :city, :state, :post_code]

    case parse_kw(params, required_fields) do
      {:ok, kw} ->
        {:ok,
         %{
           email: kw[:email],
           address: %{
             street: kw[:street],
             number: kw[:st_number],
             complement: kw[:complement],
             city: kw[:city],
             state: kw[:state],
             postCode: kw[:post_code]
           }
         }}

      error ->
        error
    end
  end

  @doc """
  Returns a payment_info map to be used on Junex.create_payment/2
  """
  @spec get_payment_info(Keyword.t()) ::
          {:ok, payment_info()}
          | {:param_error, :wrong_params}
  def get_payment_info(params) do
    case parse_kw(params, [:charge_id, :payment_billing_info, :card_info]) do
      {:ok, kw} ->
        {:ok,
         %{
           chargeId: kw[:charge_id],
           billing: kw[:payment_billing_info],
           creditCardDetails: kw[:card_info]
         }}

      error ->
        error
    end
  end

  @doc """
  Return a card_info map to use on Junex.get_payment_info/1
  """
  @spec get_card_info(String.t()) :: card_info()
  def get_card_info(card_hash) when is_binary(card_hash) do
    %{
      creditCardHash: card_hash
    }
  end

  def get_card_info(_), do: {:error, :expected_string}

  @doc """
  Creates and returns a new Payment
  """
  @spec create_payment(%Tesla.Client{}, Keyword.t()) ::
          {:ok, map()} | {:error, atom() | String.t() | {atom(), atom()}}
  def create_payment(%Tesla.Client{} = client, params) do
    with {:ok, kw} <- parse_kw(params, [:payment_info, :mode]),
         :ok <- check_mode(kw[:mode]),
         {:ok, response_env} <-
           post(client, get_url(kw[:mode]) <> "/payments", kw[:payment_info]),
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
end
