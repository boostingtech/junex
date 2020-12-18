defmodule Junex do
  @moduledoc """
  Junex is a library for help you to interact to the Juno API in a easier way!

  ## WARNINGS

    1. Although you can build the maps mannualy, like `charge_info` and `payment_billing_info`,
       Junex provide a bunch of helper functions to build the exactly structure that the Juno API requests, so
       consider using them!
    2. All main function receive as last param an atom that could be `:prod` or `:sandbox`
    3. The `create_client` and `get_access_token` functions can also been called with config from `config.exs`

  ## Config
  You can provide config information for Junex in three ways:
    1. On `config.exs` config file
    2. Calling from code, with `Junex.configure/1 or /2`
    3. Providing manually all configs

  The available configs are:
    1. `client_id`
    2. `client_secret`
    3. `resource_token`
    4. `mode`

  Example config on `config.exs`:
      config :junex, :tokens,
         client_id: System.get_env("CLIENT_ID"),
         client_secret: System.get_env("CLIENT_SECRET"),
         resource_token: System.get_env("RESOURCE_TOKEN"),
         mode: :prod

  ## Example of use

  As an example, see how you could create a charge and a payment:

  First, you need an `access_token`, to get one, you need to have a `client_id` and `client_secret` pair.
  You can generate one for production or sandbox on the Juno's Integration screen.

  After that:

      defmodule MyApp.Payment do
        def jwt_token(client_id, client_secret) do
          token_params = [
            client_id: System.get_env("CLIENT_ID"),
            client_secret: System.get_env("CLIENT_SECRET"),
            mode: :sandbox
          ]

          case Junex.get_access_token(token_params) do
            {:ok, token} ->
              token

            {:error, error} ->
              {:error, error}
          end
        end
      end

  Now you have an `access_token` you can make another requests! Let create a charge now:
  For this, you need first to create a client, providing the `access_token` and also the `resource_token`, that
  is the `Private Token` that you also can generate on the Integration screen.

      defmodule MyApp.Payment do
        def charges do
          with {:ok, client} <- Junex.create_client/2 or /1,
               {:ok, charge_info} <- Junex.get_charge_info(params),
               {:ok, charge_billing_info} <- Junex.get_charge_billing_info(params),
               {:ok, charges} <- 
                  Junex.create_charges(client, charge_info: charge_info, charge_billing_info: charge_billing_info) do
              charges
          else
            {:error, error} ->
              {:error, error}
          end
        end
      end

  Ok, charges created and returned as a list, so, if the `payment_type` was `:credit_card`, you can
  generate the payment in sequence

      defmodule MyApp.Payment do
        def payment do
          with {:ok, card_info} <- Junex.get_card_info(params),
               {:ok, payment_billing_info} <- Junex.get_payment_billing_info(params),
               {:ok, params} <- 
                  Junex.get_payment_info(card_info: card_info, payment_billing_info: payment_billing_info),
               payment_results <- charges |> Task.async_stream(&do_payment(&1, params)) do
              payment_results
          else
            error ->
              error
          end
        end

        def do_payment(charge) do
          case Junex.create_payment(client, payment_info: payment_info, mode: :sandbox) do
            {:ok, payment} ->
              payment

            {:error, error} ->
              {:error, error}
          end
        end
      end
  """

  # ----------- Junex Settings -----------

  @doc """
  Provides configuration settings for accessing Juno server. 

  The specified configuration applies globally. Use `Junex.configure/2`
  for setting different configurations on each processes.

  ## Example
      
      Junex.configure(
        client_id: System.get_env("CLIENT_ID"),
        client_secret: System.get_env("CLIENT_SECRET"),
        mode: System.get_env("JUNO_MODE")
      )
  """
  defdelegate configure(tokens), to: Junex.Config, as: :set

  @doc """
  Provides configuration settings for accessing Juno server. 

  ## Options
    The `scope` can have one of the following values.
    * `:global` - configuration is shared for all processes.
    * `:process` - configuration is isolated for each process.

  ## Example
      
      Junex.configure(
        :global,
        client_id: System.get_env("CLIENT_ID"),
        client_secret: System.get_env("CLIENT_SECRET"),
        mode: System.get_env("JUNO_MODE")
      )
  """
  defdelegate configure(scope, tokens), to: Junex.Config, as: :set

  @doc """
  Returns current Junex configuration settings for accessing Juno server.
  """
  defdelegate configure, to: Junex.Config, as: :get

  # ----------- Junex Client -----------

  @doc """
  Returns a new client to perform other requests!

  ## Params
    - access_token: Got from Junex.Auth.get_access_token
    - resource_token: You can generate one on your Juno's account, is the "Private Token"

  ## Examples
      Junex.Client.create(
        System.get_env("ACCESS_TOKEN"),
        System.get_env("RESOURCE_TOKEN")
      )
  """
  defdelegate create_client(access_token, resource_token), to: Junex.Client, as: :create

  @doc """
  Same as `Junex.create_client/2` however uses config from `config.exs`

  ## Params
    - access_token: Got from Junex.get_access_token/1 or /0

  ## Examples
      Junex.create_client(access_token)
  """
  defdelegate create_client(access_token), to: Junex.Client, as: :create

  # ----------- Junex Charges -----------

  @doc """
  Returns a charge_info map to be used on Junex.create_charges/2

  ## Example
      Junex.get_charge_info(
        description: "description",
        amount: 123,
        installments: 2,
        payment_type: :boleto
      )
  """
  defdelegate get_charge_info(values), to: Junex.API.Charge, as: :get_charge_info

  @doc """
  Return a new charge_billing_info map to be used on Junex.create_charges/2

  ## Example
      Junex.get_charge_billing_info(
        name: "name",
        document: "document",
        email: "email",
        phone: "phone"
      )
  """
  defdelegate get_charge_billing_info(values), to: Junex.API.Charge, as: :get_charge_billing_info

  @doc """
  Creates and return a new charge

  ## Parameters
    - client: Got from Junex.create_client/1
    - charge_info: Build mannualy or generated with Junex.get_charge_info/1
    - billing: Build mannualy or generated with Junex.get_charge_billing_info/1
    - mode: :prod | :sandbox

  ## Example
      Junex.create_charges(
        Junex.create_client(params),
        Map.merge(Junex.get_charge_info(), Junex.get_charge_billing_info())
      )
  """
  defdelegate create_charges(client, values), to: Junex.API.Charge, as: :create_charges

  @doc """
  Returns the latest charge status

  ## Parameters
    - client: Got from Junex.create_client/1
    - charge_id: One of results do Junex.create_charges/2
    - mode: :prod | :sandbox

  ## Example
      Junex.check_charge_status(
        Junex.create_client(params),
        client_id: "client_id",
        mode: :sandbox
      )
  """
  defdelegate check_charge_status(client, values), to: Junex.API.Charge, as: :check_charge_status

  # ----------- Junex Account -----------

  @doc """
  List all possible banks for Juno transfers

  ## Parameters
    - client: from Junex.create_client/1
    - mode: :prod | :sandbox

  ## Examples
      Junex.list_banks(Junex.create_client(), :sandbox)
  """
  defdelegate list_banks(client, values), to: Junex.API.Account, as: :list_banks

  @doc """
  Return you current balance!

  ## Parameters
    - client: Get from Junex.create_client/1
    - mode: :prod | :sandbox

  ## Examples
      Junex.get_balance(Junex.create_client(), :sandbox)
  """
  defdelegate get_balance(client, values), to: Junex.API.Account, as: :get_balance

  # ----------- Junex Payment -----------

  @doc """
  Returns a payment_billing_info map to use on Junex.get_payment_info/1

  ## Examples
      Junex.get_payment_billing_info(
        email: "email",
        street: "street",
        st_number: 12,
        city: "city",
        state: "state",
        complement: "complement",
        post_code: "post_code"
      )
  """
  defdelegate get_payment_billing_info(values),
    to: Junex.API.Payment,
    as: :get_payment_billing_info

  @doc """
  Returns a payment_info map to be used on Junex.create_payment/2

  ## Parameters
    - charge_id: Result of one entries of Junex.create_charges/2
    - card_info: Build mannualy or got from Junex.get_card_info/1
    - payment_billing_info: Build mannually or got from Junex.get_payment_billing_info/1

  ## Example
      Junex.get_payment_info(
        charge_id: "charge_id",
        card_info: Junex.get_card_info(params),
        payment_billing_info: Junex.get_payment_billing_info(params)
      )
  """
  defdelegate get_payment_info(values), to: Junex.API.Payment, as: :get_payment_info

  @doc """
  Creates and returns a new Payment

  ## Parameters
    - client: Got from Junex.create_client/1
    - payment_info: Build mannualy or got from Junex.get_payment_info/1
    - mode: :prod | :sandbox

  ## Example
      Junex.create_payment(
        Junex.create_client(params),
        payment_info: Junex.get_payment_info(params),
        mode: :sandbox
      )
  """
  defdelegate create_payment(client, values), to: Junex.API.Payment, as: :create_payment

  @doc """
  Return a card_info map to use on Junex.get_payment_info/1
  """
  defdelegate get_card_info(values), to: Junex.API.Payment, as: :get_card_info

  # ----------- Junex Auth -----------

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
  defdelegate get_access_token(values), to: Junex.Auth, as: :get_access_token

  @doc """
  Same as Junex.get_access_token/1, however, uses config from `config.exs` 
  """
  defdelegate get_access_token, to: Junex.Auth, as: :get_access_token
end
