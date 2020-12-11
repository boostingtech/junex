defmodule Junex.Client do
  @moduledoc """
  Main Module! Defines all possible functions to call Juno API
  """

  import Tesla, only: [post: 3, get: 3]
  alias Tesla.Middleware.JSON

  @prod_url "https://api.juno.com.br"
  @sandbox_url "https://sandbox.boletobancario.com/api-integration"

  @version Mix.Project.config()[:version]

  @modes [:prod, :sandbox]

  @payment_types [:boleto, :credit_card]

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
  @type billing :: %{name: String.t(), document: String.t(), email: String.t(), phone: String.t()}

  @doc """
  Returns a new charge to be used on Junex.Client.create_charge/2
  """
  @spec get_new_charge(String.t(), integer(), String.t(), float()) :: total_charge_info()
  def get_new_charge(description, installments, payment_type, amount)
      when is_binary(description) and is_integer(installments) and installments > 1 and
             payment_type in @payment_types and is_float(amount) do
    case payment_type do
      :boleto ->
        %{
          description: description,
          installments: installments,
          paymentTypes: "BOLETO",
          totalAmount: amount
        }

      :credit_card ->
        %{
          description: description,
          installments: installments,
          paymentTypes: "CREDIT_CARD",
          totalAmount: amount
        }
    end
  end

  @doc """
  Retuns a new charge with installments == 1 to be used on Junex.Client.create_charge/2
  """
  @spec get_new_charge(String.t(), String.t(), float()) :: charge_info()
  def get_new_charge(description, payment_type, amount)
      when is_binary(description) and
             payment_type in @payment_types and is_float(amount) do
    case payment_type do
      :boleto ->
        %{
          description: description,
          installments: 1,
          paymentTypes: "BOLETO",
          totalAmount: amount
        }

      :credit_card ->
        %{
          description: description,
          installments: 1,
          paymentTypes: "CREDIT_CARD",
          totalAmount: amount
        }
    end
  end

  @doc """
  Return a new billing map to be used on Junex.Client.create_charge/2
  """
  @spec get_billing(String.t(), String.t(), String.t(), String.t()) :: billing()
  def get_billing(name, doc, email, phone)
      when is_binary(name) and is_binary(doc) and is_binary(email) and is_binary(phone) do
    %{
      name: name,
      document: doc,
      email: email,
      phone: phone
    }
  end

  @doc """
  Creates and return a new charge

  ## Parameters
    - client: Got from Junex.Client.create/2
    - charge_info: Build mannualy or generated with Junex.Client.get_new_charge/3 or /4
    - billing: Build mannualy or generated with Junex.Client.get_billing/4
    - mode: :prod | :sandbox
  """
  @spec create_charge(
          %Tesla.Client{},
          total_charge_info() | charge_info(),
          billing(),
          atom()
        ) ::
          {:ok, map()} | {:error, atom() | String.t() | {atom(), atom()}}
  def create_charge(%Tesla.Client{} = client, charge_info, billing, mode)
      when is_map(charge_info) and is_map(billing) and mode in @modes do
    {:ok, %{status: status, body: body}} =
      case post(client, get_url(mode) <> "/charges", %{charge: charge_info, billing: billing}) do
        {:ok, env} ->
          env

        {:error, error} ->
          get_conn_error(error)
      end
      |> JSON.decode(keys: :string)

    check_status_code(status, body, "_embedded")
  end

  @doc """
  Returns the latest charge status

  ## Parameters
    - client: Got from Junex.Client.create/2
    - charge_id: One of results do Junex.Client.create_charge/4
    - mode: :prod | :sandbox
  """
  @spec check_charge_status(%Tesla.Client{}, String.t(), atom()) :: {:ok, map()}
  def check_charge_status(%Tesla.Client{} = client, charge_id, mode)
      when is_binary(charge_id) and mode in @modes do
    {:ok, %{status: status, body: body}} =
      case get(client, get_url(mode) <> "/charges/#{charge_id}", []) do
        {:ok, env} ->
          env

        {:error, error} ->
          get_conn_error(error)
      end
      |> JSON.encode(keys: :string)
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
  @spec list_banks(Tesla.client(), atom()) ::
          {:ok, list(map())}
          | {:error, atom() | String.t() | {atom(), atom()}}
  def list_banks(%Tesla.Client{} = client, mode) when is_atom(mode) and mode in @modes do
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

  def list_banks(%Tesla.Client{} = _client, mode) when not is_atom(mode) or mode not in @modes,
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
  def get_balance(%Tesla.Client{} = client, mode) when is_atom(mode) and mode in @modes do
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

  def get_balance(%Tesla.Client{} = _client, mode) when not is_atom(mode) or mode not in @modes,
    do: get_atom_error()

  def get_balance(_invalid, _mode), do: get_client_error()

  @doc """
  Returns a new client to perform other requests!

  ## Params
    - access_token: Got from Junex.Auth.get_access_token
    - resource_token: You can generate one on your Juno's account, is the "Private Token"

  ## Examples
    iex> Junex.Client.create("access_token", "resource_token")
    {:ok, client}
  """
  @spec create(String.t(), String.t()) :: {:ok, Tesla.client()}
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
      when not is_binary(access_token) or not is_binary(resource_token),
      do: {:error, :expected_token_to_be_string}

  defp check_status_code(status, body, key) do
    case status do
      401 ->
        {:error, :unauthenticated}

      400 ->
        {:error, {:bad_request, :invalid_request_data}}

      200 ->
        {:ok, body[key]}

      201 ->
        {:ok, body[key]}

      500 ->
        {:error, body["error"]}

      _ ->
        {:error, :unkown_error}
    end
  end

  defp check_status_code(status, body, key1, key2) do
    case status do
      401 ->
        {:error, :unauthenticated}

      400 ->
        {:error, {:bad_request, :invalid_request_data}}

      200 ->
        {:ok, body[key1][key2]}

      201 ->
        {:ok, body[key1][key2]}

      500 ->
        {:error, body["error"]}

      _ ->
        {:error, :unkown_error}
    end
  end

  defp check_status_code(status, body) do
    case status do
      401 ->
        {:error, :unauthenticated}

      400 ->
        {:error, {:bad_request, :invalid_request_data}}

      200 ->
        {:ok, body}

      201 ->
        {:ok, body}

      500 ->
        {:error, body["error"]}

      _ ->
        {:error, :unkown_error}
    end
  end

  defp get_url(:prod), do: @prod_url
  defp get_url(:sandbox), do: @sandbox_url

  defp get_conn_error(error), do: %{status: 500, body: %{"error" => error}}

  defp get_atom_error, do: {:error, :expected_mode_to_be_valid}

  defp get_client_error, do: {:error, :expected_tesla_client}
end
