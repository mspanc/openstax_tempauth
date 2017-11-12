defmodule OpenStax.TempAuth.Endpoint do
  @moduledoc """
  This module is responsible for storing configuration of TempAuth endpoints.
  """

  @doc """
  Starts a new agent for storing configuration.
  """
  def start_link(opts \\ []) do
    Agent.start_link(fn -> %{} end, opts)
  end


  @doc """
  Registers new endpoint that uses username/password for authentication.

  Endpoint URL is a URL to the authentication service.

  Version has to be :"1.0" at the moment as this is the only supported
  version by this library.

  According to the specification Tenant's ID and Name are mutually exclusive
  so you have to specify only one of them (put nil as second one).
  """
  def register(endpoint_id, version = :"1.0", endpoint_url, username, password) do
    result = Agent.update(OpenStax.TempAuth.Endpoint, fn(state) ->
      Map.put(state, endpoint_id, %{
        endpoint_url: endpoint_url,
        version: version,
        username: username,
        password: password,
        auth_token: nil
      })
    end)

    case Supervisor.start_child(OpenStax.TempAuth.AuthSupervisor, Supervisor.Spec.worker(OpenStax.TempAuth.AuthWorker, [endpoint_id], [id: "OpenStax.TempAuth.AuthWorker##{endpoint_id}"])) do
      {:ok, _child} ->
        result

      {:error, _reason} ->
        throw :unable_to_start_worker
    end
  end



  @doc """
  Returns current configuration for given endpoint.
  """
  def get_config(endpoint_id) do
    Agent.get(OpenStax.TempAuth.Endpoint, fn(state) ->
      Map.get(state, endpoint_id)
    end)
  end


  @doc """
  Returns current auth token for given endpoint.
  """
  def get_auth_token(endpoint_id) do
    Agent.get(OpenStax.TempAuth.Endpoint, fn(state) ->
      Map.get(Map.get(state, endpoint_id), :auth_token)
    end)
  end


  @doc """
  Sets the auth token for given endpoint.
  """
  def set_auth_token(endpoint_id, auth_token) when is_binary(auth_token) do
    Agent.update(OpenStax.TempAuth.Endpoint, fn(state) ->
      endpoint_config = Map.get(state, endpoint_id)
      Map.put(state, endpoint_id, %{endpoint_config | auth_token: auth_token})
    end)
  end
end
