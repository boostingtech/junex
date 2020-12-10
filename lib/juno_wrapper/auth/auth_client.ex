defmodule JunoWrapper.Auth.Client do
  @callback build(client_id :: String.t(), client_secret :: String.t()) :: {:ok, Tesla.client()}
end
