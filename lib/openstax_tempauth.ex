defmodule OpenStax.TempAuth do
  @moduledoc ~S"""
  OpenStax TempAuth provides bindings for OpenStack TempAuth v1.0 API for the
  Elixir programming language.

  It supports adding multiple endpoints in the runtime, but if you want you may
  add only one during startup.

  ## Installation

  Add the following tuple to `deps` in your `mix.exs`:

      {:openstax_tempauth, "~> 0.1"}

  and `:openstax_tempauth` to your `app_list`.


  ## Examples

  If you use username/password authentication, and Tenant ID as your identifier,
  use the following code in order to add the new tempauth endpoint:

      OpenStax.TempAuth.Endpoint.register(:my_storage, :"1.0", "https://auth.example.com/auth/v1.0", "user:group", "secret")

  """

  use Application


  def version do
    "0.1.0"
  end


  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(OpenStax.TempAuth.Endpoint, [[name: OpenStax.TempAuth.Endpoint]]),
      supervisor(OpenStax.TempAuth.AuthSupervisor, [[name: OpenStax.TempAuth.AuthSupervisor]])
    ]

    opts = [strategy: :one_for_one, name: OpenStax.TempAuth]
    Supervisor.start_link(children, opts)
  end
end
