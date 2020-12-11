defmodule JunoWrapper.AuthTest do
  use ExUnit.Case, async: true

  alias JunoWrapper.Auth

  import Mox

  setup :verify_on_exit!

  describe "get_access_token/3" do
    test "returns 401 when credentials are invalid" do
      client_id = "teste1"
      client_secret = "teste2"
      is_sandbox = true

      Mox.expect(JunoWrapper.AuthMock, :get_access_token, 1, fn ^client_id,
                                                                ^client_secret,
                                                                ^is_sandbox ->
        {:error, {:unauthenticated, :wrong_credentials}}
      end)

      assert {:error, {:unauthenticated, :wrong_credentials}} =
               Auth.get_access_token(client_id, client_secret, is_sandbox)
    end
  end
end
