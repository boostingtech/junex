defmodule Junex.Config do
  @moduledoc false

  def current_scope do
    if Process.get(:_junex, nil), do: :process, else: :global
  end

  @doc """
  Get Juno's tokens configuration values
  """
  def get, do: get(current_scope())

  def get(:global) do
    Application.get_env(:junex, :tokens, nil)
  end

  def get(:process), do: Process.get(:_junex, nil)

  @doc """
  Set Juno's tokens configuration values
  """
  def set(value), do: set(current_scope(), value)

  def set(:global, value), do: Application.put_env(:junex, :tokens, value)

  def set(:process, value) do
    Process.put(:_junex, value)
  end

  @doc """
  Get Juno's tokens configuration values in tuple format
  """

  def get_tuples do
    case Junex.Config.get() do
      nil ->
        []

      tuples ->
        tuples
    end
  end

  @doc """
  Checks if required configs exists
  """
  def parse_config(config, keys) do
    if keys in config do
      {:ok, config}
    else
      {:error, :no_config_found}
    end
  end
end
