defmodule Junex do
  @moduledoc """
  Junex is a library for help you to interact to the Juno API in a easier way!

  ## WARNINGS

    1. Although you can build the maps mannualy, like `charge_info` and `payment_billing_info`,
       Junex provide a bunch of helper functions to build the exactly structure that the Juno API requests, so
       consider using them!
    2. All main function receive as last param an atom that could be `:prod` or `:sandbox`

  # Example

  As an example, see how you could create a charge and a payment:

  First, you need an `access_token`, to get one, you need to have a `client_id` and `client_secret` pair.
  You can generate one for production or sandbox on the Juno's Integration screen.

  After that:

      defmodule MyApp.Payment do
        alias Junex.Auth

        def jwt_token(client_id, client_secret) do
          case Auth.get_access_token(client_id, client_secret, :sandbox) do
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
        alias Junex.Client
        
        def charges do
          {:ok, client} = Client.create(access_token, resource_token)
          charge_info = Client.get_charge_info/3 or /4
          charge_billing_info = Client.get_charge_billing_info/4

          case Client.create_charge(client, charge_info, charge_billing_info, :sandbox) do
            {:ok, charges} ->
              charges

            {:error, error} ->
              {:error, error}
          end
        end
      end

  Ok, charges created and returned as a list, so, if the `payment_type` was `:credit_card`, you can
  generate the payment in sequence

      defmodule MyApp.Payment do
        alias Junex.Client

        def payment do
          {:ok, client} = Clien.create/2
          card_info = Client.get_card_info/1
          payment_billing_info = Client.get_payment_billing_info/3

          for charge <- charges do   
            payment_info = Client.get_payment_info(charge["id"], card_info, payment_billing_info)

            case Client.create_payment(client, payment_info, :sandbox) do
              {:ok, payment} ->
                payment

              {:error, error} ->
                {:error, error}
            end
          end
        end
      end
  """

  # ----------- Junex Settings -----------

  @doc """
  Provides configuration settings for accessing twitter server. 

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
  Provides configuration settings for accessing twitter server. 

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
  Returns current OAuth configuration settings for accessing twitter server.
  """
  defdelegate configure, to: Junex.Config, as: :get

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
  Return a new charge_billing_info map to be used on Junex.Client.create_charges/4

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
    - client: Got from Junex.Client.create/2
    - charge_info: Build mannualy or generated with Junex.Client.get_charge_info/3 or /4
    - billing: Build mannualy or generated with Junex.Client.get_charge_billing_info/4
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
    - client: Got from Junex.Client.create/2
    - charge_id: One of results do Junex.Client.create_charges/4
    - mode: :prod | :sandbox

  ## Example
      Junex.check_charge_status(
        Junex.create_client(params),
        client_id: "client_id",
        mode: :sandbox
      )
  """
  defdelegate check_charge_status(client, values), to: Junex.API.Charge, as: :check_charge_status
end
