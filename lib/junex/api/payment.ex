defmodule Junex.API.Payment do
  @moduledoc """
  Provides access to interact with Payments
  """

  alias Tesla.Middleware.JSON

  import Tesla, only: [post: 3, get: 3]

  import Junex.Utils, only: [modes: 1, check_status_code: 1, check_status_code: 2]

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
  def get_payment_billing_info(kw)
      when is_binary(Keyword.get(k2, :email)) and
             is_binary(Keyword.get(kw, :street)) and
             is_binary(Keyword.get(kw, :st_number)) and
             is_binary(Keyword.get(kw, :complement)) and
             is_binary(Keyword.get(kw, :city)) and
             is_binary(Keyword.get(kw, :state)) and
             is_binary(Keyword.get(kw, :post_code)) do
    email = Keyword.get(kw, :email)
    street = Keyword.get(kw, :street)
    st_number = Keyword.get(kw, :st_number)
    compl = Keyword.get(kw, :complement)
    city = Keyword.get(kw, :city)
    state = Keyword.get(kw, :state)
    post_code = Keyword.get(kw, :post_code)

    %{
      email: email,
      address: %{
        street: street,
        number: st_number,
        complement: compl,
        city: city,
        state: state,
        postCode: post_code
      }
    }
  end

  def get_payment_billing_info(_), do: {:error, :wrong_opts}

  @doc """
  Returns a payment_info map to be used on Junex.create_payment/2
  """
  @spec get_payment_info(Keyword.t()) :: payment_info()
  def get_payment_info(kw)
      when is_binary(Keyword.get(kw, :charge_id)) and
             is_map(Keyword.get(kw, :payment_billing_info)) and
             is_map(Keyword.get(kw, :card_info)) do
    %{
      chargeId: Keyword.get(kw, :charge_id),
      billing: Keyword.get(kw, :payment_billing_info),
      creditCardDetails: Keyword.get(kw, :card_info)
    }
  end

  def get_payment_info(_), do: {:error, :wrong_opts}

  @doc """
  Creates and returns a new Payment
  """
  @spec create_payment(%Tesla.Client{}, Keyword.t()) ::
          {:ok, map()} | {:error, atom() | String.t() | {atom(), atom()}}
  def create_payment(%Tesla.Client{} = client, kw)
      when is_map(Keyword.get(kw, :payment_info)) and
             Keyword.get(kw, :mode) in modes() do
    payment_info = Keyword.get(kw, :payment_info)
    mode = Keyword.get(kw, :mode)

    with {:ok, response_env} <- post(client, get_url(mode) <> "/payments", payment_info),
         {:ok, response} <- JSON.decode(response_env, keys: :string) do
      check_status_code(response)
    else
      error ->
        check_status_code(error)
    end
  end

  def create_payment(_client, _), do: {:error, :wrong_opts}
end
