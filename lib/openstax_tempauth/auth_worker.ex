defmodule OpenStax.TempAuth.AuthWorker do
  @moduledoc """
  This module is responsible for periodically requesting Auth Token based on
  passed credentials.
  """

  use Connection

  require Logger

  @request_headers [
    {"Cache-Control", "no-cache, must-revalidate"},
    {"Accept-Encoding", "identity"},
    {"User-Agent", "OpenStax.TempAuth/#{OpenStax.TempAuth.version}"}
  ]
  @request_timeout 30000
  @request_options [timeout: @request_timeout, recv_timeout: @request_timeout, follow_redirect: false]
  @retry_timeout   10000
  @logger_tag      "OpenStax.TempAuth.AuthWorker"


  def start_link(endpoint_id) do
    Connection.start_link(__MODULE__, endpoint_id, [])
  end


  @doc false
  def init(endpoint_id) do
    s = %{endpoint_id: endpoint_id}
    {:connect, :init, s}
  end


  def connect(_, %{endpoint_id: endpoint_id} = s) do
    case request_token(endpoint_id) do
      :ok ->
        {:ok, s}

      {:error, reason} ->
        {:backoff, reason, @retry_timeout}
    end
  end


  def disconect(:refresh, s) do
    {:connect, :refresh, s}
  end


  def handle_info(:refresh, s) do
    {:disconnect, :refresh, s}
  end


  defp request_token(endpoint_id) do
    %{username: username, password: password, endpoint_url: endpoint_url} = 
    OpenStax.TempAuth.Endpoint.get_config(endpoint_id)

    request_headers =
      @request_headers ++ 
      [
        {"x-auth-user", username}, 
        {"x-auth-key", password}
      ]
   


    Logger.info "[#{@logger_tag} #{inspect(endpoint_id)}] Retreiving auth token..."
    case HTTPoison.request(:get, endpoint_url, "", request_headers, @request_options) do
      {:ok, %HTTPoison.Response{status_code: status_code, headers: headers}} ->
        case status_code do
          200 ->
            case List.keyfind(headers, "X-Auth-Token", 0) do
              nil ->
                Logger.warn "[#{@logger_tag} #{inspect(endpoint_id)}] Failed to retrieve auth token: X-Auth-Token header is missing in the response"
                {:error, :header}

              {"X-Auth-Token", auth_token} ->
                Logger.info "[#{@logger_tag} #{inspect(endpoint_id)}] Successfully retreived auth token"
                OpenStax.TempAuth.Endpoint.set_auth_token(endpoint_id, auth_token)
                :ok
            end

          _ ->
            Logger.warn "[#{@logger_tag} #{inspect(endpoint_id)}] Failed to retrieve auth token: got unexpected status code of #{status_code}"
            {:error, {:httpcode, status_code}}
        end

      {:error, reason} ->
        Logger.warn "[#{@logger_tag} #{inspect(endpoint_id)}] Failed to retrieve auth token: got HTTP error #{inspect(reason)}"
        {:error, {:httperror, reason}}
    end
  end
end
