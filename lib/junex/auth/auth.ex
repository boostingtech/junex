defmodule Junex.Auth do
  @moduledoc """
  This Module defines the client's function behaviour
  and exposes the get_access_token function
  """

  def get_access_token(client_id, client_secret, is_sandbox) do
    client().get_access_token(client_id, client_secret, is_sandbox)
  end

  defp client do
    Application.get_env(:juno_wrapper, :auth_client)
  end
end
