defmodule Himmel.Services.IP do
  import Phoenix.LiveView, only: [get_connect_info: 2]
  alias Himmel.Utils
  require Logger

  @doc "Gets the IP of the requesting client"
  def get_user_ip(socket) do
    case Mix.env() do
      :dev ->
        # run this code if in development
        peer_data = get_connect_info(socket, :peer_data)
        peer_data.address |> :inet.ntoa() |> to_string()

      :prod ->
        # run this code if in production
        get_connect_info(socket, :x_headers)
        |> Enum.find(fn {key, _} -> key == "x-forwarded-for" end)
        |> elem(1)
        |> String.split(",")
        |> hd()
    end
  end

  @doc "Gets the coordinates and city from an IP address"
  def get_ip_details(ip) do
    token = Application.get_env(:ipinfo, :token)
    url = "https://ipinfo.io/#{ip}?token=#{token}"

    case Utils.web_request(url) do
      {:ok, %Finch.Response{status: 200, body: body}} ->
        Jason.decode!(body)

      {:ok, %Finch.Response{status: status}} ->
        Logger.error("Received status #{status} from IPinfo")

        # TODO: Handle other status codes by returning a default value and notify the liveview that the IPinfo request failed
        %{city: "Stavanger", loc: "58.97,5.7331"}

      {:error, error} ->
        Logger.error("Received error #{inspect(error)} from IPinfo")

        # TODO: Handle errors by returning a default value and notify the liveview of a Mint transport error
        %{city: "Edinburgh", loc: "55.9533,3.1883"}
    end
  end
end
