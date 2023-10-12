defmodule HimmelWeb.Utils do
  alias Himmel.Services.{IP, Places}
  alias Himmel.Places
  alias Himmel.Weather

  def get_user_location_weather(socket) do
    socket
    |> IP.get_user_ip()
    |> IP.get_ip_details()
    |> Places.create_place_from_ip_details()
    |> Weather.get_weather()
  end
end
