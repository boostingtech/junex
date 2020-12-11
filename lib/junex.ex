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
end
