defmodule JunoWrapper.Auth.HTTP do
  @behaviour JunoWrapper.Auth.Client

  @impl true
  def build(client_id, client_secret) do
    Tesla.client([
      Tesla.Middleware.FormUrlencoded,
      {Tesla.Middleware.BasicAuth, %{username: client_id, password: client_secret}},
      {Tesla.Middleware.Headers, [{"content-type", "application/x-www-form-urlencoded"}]}
    ])
  end
end
