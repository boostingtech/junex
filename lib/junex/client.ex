defmodule Junex.Client do
  @moduledoc """
  Main Module! Defines all possible functions to call Juno API
  """

  import Tesla, only: [post: 3, get: 3]
  alias Tesla.Middleware.JSON

  @type card_info :: %{
          creditCardHash: String.t()
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
  Returns a new client to perform other requests!
  """
  @spec create(Keyword.t()) :: {:ok, %Tesla.Client{}}
  def create(kw)
      when is_binary(Keyword.get(kw, :access_token)) and
             is_binary(Keyword.get(kw, :resource_token)) do
    access_token = Keyword.get(kw, :access_token)

    resource_token = Keyword.get(kw, :resource_token)

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
