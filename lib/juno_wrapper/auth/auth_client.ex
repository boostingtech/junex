defmodule JunoWrapper.Auth.Callback do
  @callback get_access_token(
              client_id :: String.t(),
              client_secret :: String.t(),
              is_sandbox :: boolean()
            ) ::
              {:ok, String.t()}
              | {:error, :missing_grant_type_body}
              | {:error, {:unauthenticated, :wrong_credentials}}
              | {:error, :unkown_error}
end
