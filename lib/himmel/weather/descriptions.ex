defmodule Himmel.Weather.Descriptions do
  alias WeatherInfo.Description

  def get_description(weather_code, day_or_night) do
    description =
      all()
      |> Map.get(to_string(weather_code))
      |> Map.get(day_or_night)

    %Description{
      text: description.text,
      image: description.image
    }
  end

  def all do
    %{
      "0" => %{
        day: %{
          text: "Sunny",
          image: "/images/weather_icons/clear-day.png"
        },
        night: %{
          text: "Clear",
          image: "/images/weather_icons/clear-night.png"
        }
      },
      "1" => %{
        day: %{
          text: "Mainly Sunny",
          image: "/images/weather_icons/clear-day.png"
        },
        night: %{
          text: "Mainly Clear",
          image: "/images/weather_icons/clear-night.png"
        }
      },
      "2" => %{
        day: %{
          text: "Partly Cloudy",
          image: "/images/weather_icons/partly-cloudy-day.png"
        },
        night: %{
          text: "Partly Cloudy",
          image: "/images/weather_icons/partly-cloudy-night.png"
        }
      },
      "3" => %{
        day: %{
          text: "Cloudy",
          image: "/images/weather_icons/cloudy.png"
        },
        night: %{
          text: "Cloudy",
          image: "/images/weather_icons/cloudy.png"
        }
      },
      "45" => %{
        day: %{
          text: "Foggy",
          image: "/images/weather_icons/fog.png"
        },
        night: %{
          text: "Foggy",
          image: "/images/weather_icons/fog.png"
        }
      },
      "48" => %{
        day: %{
          text: "Rime Fog",
          image: "/images/weather_icons/fog.png"
        },
        night: %{
          text: "Rime Fog",
          image: "/images/weather_icons/fog.png"
        }
      },
      "51" => %{
        day: %{
          text: "Light Drizzle",
          image: "/images/weather_icons/drizzle.png"
        },
        night: %{
          text: "Light Drizzle",
          image: "/images/weather_icons/drizzle.png"
        }
      },
      "53" => %{
        day: %{
          text: "Drizzle",
          image: "/images/weather_icons/drizzle.png"
        },
        night: %{
          text: "Drizzle",
          image: "/images/weather_icons/drizzle.png"
        }
      },
      "55" => %{
        day: %{
          text: "Heavy Drizzle",
          image: "/images/weather_icons/extreme-day-drizzle.png"
        },
        night: %{
          text: "Heavy Drizzle",
          image: "/images/weather_icons/extreme-night-drizzle.png"
        }
      },
      "56" => %{
        day: %{
          text: "Light Freezing Drizzle",
          image: "/images/weather_icons/drizzle.png"
        },
        night: %{
          text: "Light Freezing Drizzle",
          image: "/images/weather_icons/drizzle.png"
        }
      },
      "57" => %{
        day: %{
          text: "Freezing Drizzle",
          image: "/images/weather_icons/drizzle.png"
        },
        night: %{
          text: "Freezing Drizzle",
          image: "/images/weather_icons/drizzle.png"
        }
      },
      "61" => %{
        day: %{
          text: "Light Rain",
          image: "/images/weather_icons/rain.png"
        },
        night: %{
          text: "Light Rain",
          image: "/images/weather_icons/rain.png"
        }
      },
      "63" => %{
        day: %{
          text: "Rain",
          image: "/images/weather_icons/rain.png"
        },
        night: %{
          text: "Rain",
          image: "/images/weather_icons/rain.png"
        }
      },
      "65" => %{
        day: %{
          text: "Heavy Rain",
          image: "/images/weather_icons/extreme-day-rain.png"
        },
        night: %{
          text: "Heavy Rain",
          image: "/images/weather_icons/extreme-night-rain.png"
        }
      },
      "66" => %{
        day: %{
          text: "Freezing Rain",
          image: "/images/weather_icons/sleet.png"
        },
        night: %{
          text: "Freezing Rain",
          image: "/images/weather_icons/sleet.png"
        }
      },
      "67" => %{
        day: %{
          text: "Freezing Rain",
          image: "/images/weather_icons/sleet.png"
        },
        night: %{
          text: "Freezing Rain",
          image: "/images/weather_icons/sleet.png"
        }
      },
      "71" => %{
        day: %{
          text: "Light Snow",
          image: "/images/weather_icons/snow.png"
        },
        night: %{
          text: "Light Snow",
          image: "/images/weather_icons/snow.png"
        }
      },
      "73" => %{
        day: %{
          text: "Snow",
          image: "/images/weather_icons/snowflake.png"
        },
        night: %{
          text: "Snow",
          image: "/images/weather_icons/snowflake.png"
        }
      },
      "75" => %{
        day: %{
          text: "Heavy Snow",
          image: "/images/weather_icons/snowflake.png"
        },
        night: %{
          text: "Heavy Snow",
          image: "/images/weather_icons/snowflake.png"
        }
      },
      "77" => %{
        day: %{
          text: "Snow Grains",
          image: "/images/weather_icons/snow.png"
        },
        night: %{
          text: "Snow Grains",
          image: "/images/weather_icons/snow.png"
        }
      },
      "80" => %{
        day: %{
          text: "Light Showers",
          image: "/images/weather_icons/rain.png"
        },
        night: %{
          text: "Light Showers",
          image: "/images/weather_icons/rain.png"
        }
      },
      "81" => %{
        day: %{
          text: "Showers",
          image: "/images/weather_icons/rain.png"
        },
        night: %{
          text: "Showers",
          image: "/images/weather_icons/rain.png"
        }
      },
      "82" => %{
        day: %{
          text: "Heavy Showers",
          image: "/images/weather_icons/extreme-day-rain.png"
        },
        night: %{
          text: "Heavy Showers",
          image: "/images/weather_icons/extreme-night-rain.png"
        }
      },
      "85" => %{
        day: %{
          text: "Snow Showers",
          image: "/images/weather_icons/snowflake.png"
        },
        night: %{
          text: "Snow Showers",
          image: "/images/weather_icons/snowflake.png"
        }
      },
      "86" => %{
        day: %{
          text: "Snow Showers",
          image: "/images/weather_icons/snowflake.png"
        },
        night: %{
          text: "Snow Showers",
          image: "/images/weather_icons/snowflake.png"
        }
      },
      "95" => %{
        day: %{
          text: "Thunderstorm",
          image: "/images/weather_icons/thunderstorms-rain.png"
        },
        night: %{
          text: "Thunderstorm",
          image: "/images/weather_icons/thunderstorms-rain.png"
        }
      },
      "96" => %{
        day: %{
          text: "Thunderstorm With Hail",
          image: "/images/weather_icons/thunderstorms-overcast-rain.png"
        },
        night: %{
          text: "Thunderstorm With Hail",
          image: "/images/weather_icons/thunderstorms-overcast-rain.png"
        }
      },
      "99" => %{
        day: %{
          text: "Thunderstorm With Hail",
          image: "/images/weather_icons/thunderstorms-overcast-rain.png"
        },
        night: %{
          text: "Thunderstorm With Hail",
          image: "/images/weather_icons/thunderstorms-overcast-rain.png"
        }
      }
    }
  end
end
