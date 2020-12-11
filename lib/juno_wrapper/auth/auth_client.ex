defmodule JunoWrapper.Auth.Callback do
  @moduledoc """
  Defines the callback to the Mock Module
  """

  @callback get_access_token(
              String.t(),
              String.t(),
              boolean()
            ) ::
              {:ok, String.t()}
              | {:error, atom() | {atom(), atom()}}
end
