defmodule Junex.Client do
  @moduledoc """
  Main Module! Defines all possible functions to call Juno API
  """

  import Tesla, only: [post: 3, get: 3]
  alias Tesla.Middleware.JSON

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
  @type card_info :: %{
          creditCardHash: String.t()
        }
  @type payment_info :: %{
          chargeId: String.t(),
          billing: payment_billing_info(),
          creditCardDetails: card_info()
        }

  @doc """
  Return a card_info map to use on Junex.Client.get_payment_info/2
  """
  @spec get_card_info(String.t()) :: card_info()
  def get_card_info(card_hash) when is_binary(card_hash) do
    %{
      creditCardHash: card_hash
    }
  end

  @doc """
  Returns a payment_billing_info map to use on Junex.Client.get_payment_info/2
  """
  @spec get_payment_billing_info(
          String.t(),
          String.t(),
          integer(),
          String.t(),
          String.t(),
          String.t(),
          String.t()
        ) :: payment_billing_info()
  def get_payment_billing_info(email, street, st_number, compl, city, state, post_code)
      when is_binary(email) and is_binary(street) and is_binary(st_number) and is_binary(compl) and
             is_binary(city) and is_binary(state) and is_binary(post_code) do
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

  @doc """
  Returns a payment_info map to be used on Junex.Client.create_payment/3

  ## Parameters
    - charge_id: Result of one entries of Junex.Client.create_charges/4
    - card_info: Build mannualy or got from Junex.Client.get_card_info/1
    - payment_billing_info: Build mannually or got from Junex.Client.get_payment_billing_info/7
  """
  @spec get_payment_info(String.t(), card_info(), payment_billing_info()) :: payment_info()
  def get_payment_info(charge_id, card_info, payment_billing_info) do
    %{
      chargeId: charge_id,
      billing: payment_billing_info,
      creditCardDetails: card_info
    }
  end

  @doc """
  Creates and returns a new Payment

  ## Parameters
    - client: Got from Junex.Client.create/2
    - payment_info: Build mannualy or got from Junex.Client.get_payment_info/3
    - mode: :prod | :sandbox
  """
  @spec create_payment(%Tesla.Client{}, payment_info(), atom()) ::
          {:ok, map()} | {:error, atom() | String.t() | {atom(), atom()}}
  def create_payment(%Tesla.Client{} = client, payment_info, mode)
      when is_map(payment_info) and mode in @modes do
    {:ok, %{status: status, body: body}} =
      case post(client, get_url(mode) <> "/payments", payment_info) do
        {:ok, env} ->
          env

        {:error, error} ->
          get_conn_error(error)
      end
      |> JSON.decode(keys: :string)

    check_status_code(status, body)
  end

  @doc """
  List all possible banks for Juno transfers

  ## Parameters
    - client: from Junex.Client.create/2
    - mode: :prod | :sandbox

  ## Examples
    iex> Junex.Client.list_banks(client, :sandbox)
    {:ok, [%{"name" => "", "number" => ""}]}
  """
  @spec list_banks(%Tesla.Client{}, atom()) ::
          {:ok, list(map())}
          | {:error, atom() | String.t() | {atom(), atom()}}
  def list_banks(%Tesla.Client{} = client, mode) when mode in @modes do
    {:ok, %{status: status, body: body}} =
      case get(client, get_url(mode) <> "/data/banks", []) do
        {:ok, env} ->
          IO.inspect(env)
          env

        {:error, error} ->
          get_conn_error(error)
      end
      |> JSON.decode(keys: :string)

    check_status_code(status, body, "_embedded", "banks")
  end

  def list_banks(%Tesla.Client{} = _client, mode) when mode not in @modes,
    do: get_atom_error()

  def list_banks(_invalid, _mode), do: get_client_error()

  @doc """
  Return you current balance!

  ## Parameters
    - client: Get from Junex.Client.create/2
    - mode: :prod | :sandbox

  ## Examples
    iex> Junex.Client.get_balance(client, :sandbox)
    {:ok, %{"links" => _, "balance" => _, "transferableBalance" => _, "withheldBalance" => _}}
  """
  @spec get_balance(%Tesla.Client{}, atom()) :: {:ok, map()} | {:error, atom()}
  def get_balance(%Tesla.Client{} = client, mode) when mode in @modes do
    {:ok, %{status: status, body: body}} =
      case get(client, get_url(mode) <> "/balance", []) do
        {:ok, env} ->
          env

        {:error, error} ->
          get_conn_error(error)
      end
      |> JSON.decode(keys: :string)

    check_status_code(status, body)
  end

  def get_balance(%Tesla.Client{} = _client, mode) when mode not in @modes,
    do: get_atom_error()

  def get_balance(_invalid, _mode), do: get_client_error()

  @doc """
  Returns a new client to perform other requests!

  ## Params
    - access_token: Got from Junex.Auth.get_access_token
    - resource_token: You can generate one on your Juno's account, is the "Private Token"

  ## Examples
      Junex.Client.create(
        access_token: System.get_env("ACCESS_TOKEN"),
        resource_token: System.get_env("RESOURCE_TOKEN")
      )
  """
  @spec create(String.t(), String.t()) :: {:ok, %Tesla.Client{}}
  def create(access_token, resource_token)
      when is_binary(access_token) and is_binary(resource_token) do
    client =
      Tesla.client([
        Tesla.Middleware.JSON,
        {Tesla.Middleware.Headers,
         [
           {"authorization", "Bearer #{access_token}"},
           {"X-Resource-Token", resource_token},
           {"user-agent", "junex/#{@version}"},
           {"X-Api-Version", 2}
         ]}
      ])

    {:ok, client}
  end

  def create(access_token, resource_token)
      when not is_binary(access_token) or not is_binary(resource_token) do
    {:error, :expected_token_to_be_string}
  end
end
