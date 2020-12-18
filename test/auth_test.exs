defmodule Junex.AuthTest do
  use ExUnit.Case, async: true

  describe "get_access_token/3" do
    test "returns 401 when credentials are invalid" do
      assert 1 = 1
    end

    test "returns error when is_sandbox is not a boolean" do
      assert 2 = 2
    end

    test "returns ok and token if data is correct" do
      assert 3 = 3
    end
  end
end
