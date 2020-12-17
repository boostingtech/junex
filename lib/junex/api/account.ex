defmodule Junex.API.Account do
  @moduledoc """
  Provides access interface to get account information
  """

  alias Tesla.Middleware.JSON

  import Tesla, only: [get: 3]

  import Junex.Utils,
    only: [modes: 0, check_status_code: 1, check_status_code: 2, check_status_code: 3]

  @doc """
  List all possible banks for Juno transfers
  """
  @spec list_banks(%Tesla.Client{}, atom()) ::
          {:ok, list(map())}
          | {:error, atom() | String.t() | {atom(), atom()}}
  def list_banks(%Tesla.Client{} = client, kw) when Keyword.get(kw, :mode) in modes() do
    mode = Keyword.get(kw, :mode)

    with {:ok, response_env} <- get(client, get_url(mode) <> "/data/banks", []),
         {:ok, response} <- JSON.decode(response_env, keys: :string) do
      check_status_code(status, body, "_embedded", "banks")
    else
      error ->
        check_status_code(error)
    end
  end

  def list_banks(_invalid, _mode), do: {:error, :wrong_opts}

  @doc """
  Return you current balance!
  """
  @spec get_balance(%Tesla.Client{}, Keyword.t()) :: {:ok, map()} | {:error, atom()}
  def get_balance(%Tesla.Client{} = client, kw) when Keyword.get(kw, :mode) in modes() do
    mode = Keyword.get(kw, :mode)

    with {:ok, response_env} <- get(client, get_url(mode) <> "/balance", []),
         {:ok, response} <- JSON.decode(response_env, keys: :string) do
      check_status_code(status, body)
    else
      error ->
        check_status_code(error)
    end
  end

  def get_balance(_invalid, _mode), do: {:error, :wrong_opts}
end
