defmodule Junex.API.Account do
  @moduledoc """
  Provides access interface to get account information
  """

  alias Tesla.Middleware.JSON

  import Tesla, only: [get: 3]

  import Junex.Utils

  @doc """
  List all possible banks for Juno transfers
  """
  @spec list_banks(%Tesla.Client{}, maybe_improper_list()) ::
          {:error, atom()} | {:ok, list(map())}
  def list_banks(%Tesla.Client{} = client, params) do
    with {:ok, kw} <- parse_kw(params, [:mode]),
         :ok <- check_mode(kw[:mode]),
         {:ok, response_env} <- get(client, get_url(kw[:mode]) <> "/data/banks", []),
         {:ok, response} <- JSON.decode(response_env, keys: :string) do
      check_status_code({:ok, response}, "_embedded", "banks")
    else
      {:param_error, error} ->
        {:error, error}

      {:error, {JSON, _, _}} ->
        parse_json_error()

      error ->
        check_status_code(error)
    end
  end

  @doc """
  Return you current balance!
  """
  @spec get_balance(%Tesla.Client{}, Keyword.t()) :: {:ok, map()} | {:error, atom()}
  def get_balance(%Tesla.Client{} = client, params) do
    with {:ok, kw} <- parse_kw(params, [:mode]),
         :ok <- check_mode(kw[:mode]),
         {:ok, response_env} <- get(client, get_url(kw[:mode]) <> "/balance", []),
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
