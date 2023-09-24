defmodule Himmel.Places do
  import Phoenix.LiveView, only: [get_connect_info: 2]
  import Himmel.Utils
  alias :ipinfo, as: IPinfo

  @doc "Gets the IP of the requesting client"
  def get_user_ip(socket) do
    peer_data = get_connect_info(socket, :peer_data)
    peer_data.address |> :inet.ntoa() |> to_string()
  end

  @doc "Gets the coordinates and city from an IP address"
  def get_ip_details(ip) do
    with {:ok, %IPinfo{} = handler} <- IPinfo.create(Dotenv.get("IPINFO_TOKEN")),
         {:ok, details} <- IPinfo.details(handler, ip) do
      details
    end
  end

  @doc "Gets a list of search results for a place"
  def find_place(place) when is_binary(place) do
    name = String.split(place) |> Enum.join("+")

    ("https://geocoding-api.open-meteo.com/v1/search?count=20&language=en&format=json&" <>
       "name=#{name}")
    |> json_request()
  end
end
