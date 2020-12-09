```sh
** (FunctionClauseError) no function clause matching in :httpc.request/5    
    
    The following arguments were given to :httpc.request/5:
    
        # 1
        :post
    
        # 2
        {'https://sandbox.boletobancario.com/authorization-server/oauth/token',
         [
           {'authorization', 'Basic YWE6YWE='},
           {'content-type', 'application/x-www-form-urlencoded'} 
         ], 'application/x-www-form-urlencoded', %{grant_type: "client_credentials"}}
    
        # 3
        [autoredirect: false]
    
        # 4
        []
    
        # 5
        :default
    
    (inets 7.3) httpc.erl:149: :httpc.request/5
    (tesla 1.4.0) lib/tesla/adapter/httpc.ex:52: Tesla.Adapter.Httpc.request/2
    (tesla 1.4.0) lib/tesla/adapter/httpc.ex:22: Tesla.Adapter.Httpc.call/2
    (juno_wrapper 0.1.0) lib/juno_wrapper/auth/auth.ex:15: JunoWrapper.Auth.get_access_token/3
```

```elixir
defmodule JunoWrapper.Auth do
  alias Tesla.Middleware.JSON
  import Tesla, only: [post: 3]

  @sandbox_auth_url "https://sandbox.boletobancario.com/authorization-server/oauth/token"
  @prod_auth_url "https://api.juno.com.br/authorization-server/oauth/token"

  @body %{grant_type: "client_credentials"}

  def get_access_token(client_id, client_secret, is_sandbox) do
    client = create_client(client_id, client_secret)

    case is_sandbox do
      true ->
        {:ok, env} = post(client, @sandbox_auth_url, @body)
        env

      false ->
        {:ok, env} = post(client, @prod_auth_url, @body)
        env

      _ ->
        {:error, "Expected \"is_sandbox\" to be a boolean"}
    end
    |> JSON.decode(keys: :atoms)
  end

  defp create_client(client_id, client_secret) do
    Tesla.client([
      {Tesla.Middleware.BasicAuth, %{username: client_id, password: client_secret}},
      {Tesla.Middleware.Headers, [{"content-type", "application/x-www-form-urlencoded"}]}
    ])
  end
end
```
