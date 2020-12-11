defmodule Junex.AuthTest do
  use ExUnit.Case, async: true

  alias Junex.Auth

  import Mox

  setup :verify_on_exit!

  describe "get_access_token/3" do
    test "returns 401 when credentials are invalid" do
      client_id = "teste1"
      client_secret = "teste2"
      mode = :sandbox

      Mox.expect(Junex.AuthMock, :get_access_token, 1, fn ^client_id, ^client_secret, ^mode ->
        {:error, {:unauthenticated, :wrong_credentials}}
      end)

      assert {:error, {:unauthenticated, :wrong_credentials}} =
               Auth.get_access_token(client_id, client_secret, mode)
    end

    test "returns error when is_sandbox is not a boolean" do
      client_id = "teste1"
      client_secret = "teste2"

      Mox.expect(Junex.AuthMock, :get_access_token, 1, fn ^client_id, ^client_secret, "test" ->
        {:error, :expected_boolean}
      end)

      assert {:error, :expected_boolean} = Auth.get_access_token(client_id, client_secret, "test")
    end

    test "returns ok and token if data is correct" do
      client_id = "teste1"
      client_secret = "teste2"
      mode = true

      Mox.expect(Junex.AuthMock, :get_access_token, 1, fn ^client_id, ^client_secret, ^mode ->
        {:ok, "access_token"}
      end)

      assert {:ok, access_token} = Auth.get_access_token(client_id, client_secret, mode)
      assert is_binary(access_token)
    end
  end
end
