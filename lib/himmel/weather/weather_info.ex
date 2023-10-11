defmodule WeatherInfo.Current do
  use Domo

  defstruct [:description, :day_or_night, :temperature]

  @type day_or_night :: :day | :night

  @type t :: %__MODULE__{
          description: WeatherInfo.Description.t() | nil,
          day_or_night: day_or_night() | nil,
          temperature: non_neg_integer() | nil
        }
end

defmodule WeatherInfo.Day do
  use Domo

  defstruct [:date, :description, :temperature, :sunrise, :sunset, :weekday]

  @type temperature :: %{
          high: non_neg_integer(),
          low: non_neg_integer()
        }

  @type weekday :: String.t()
  precond(weekday: &(&1 in ~w(Monday Tuesday Wednesday Thursday Friday Saturday Sunday Today)))

  @type t :: %__MODULE__{
          date: Date.t() | nil,
          description: WeatherInfo.Description.t() | nil,
          temperature: temperature() | nil,
          sunrise: DateTime.t() | nil,
          sunset: DateTime.t() | nil,
          weekday: weekday() | nil
        }
end

defmodule WeatherInfo.Hour do
  use Domo

  defstruct [:description, :hour, :day_or_night, :temperature]

  @type hour :: non_neg_integer()
  precond(hour: &(&1 in 0..23))

  @type day_or_night :: :day | :night

  @type t :: %__MODULE__{
          hour: hour() | nil,
          temperature: non_neg_integer() | nil,
          description: WeatherInfo.Description.t() | nil,
          day_or_night: day_or_night() | nil
        }
end

defmodule WeatherInfo.Description do
  use Domo

  defstruct [:text, :image]

  @type t ::
          %__MODULE__{
            text: String.t() | nil,
            image: String.t() | nil
          }
end

defmodule WeatherInfo do
  alias WeatherInfo.{Current, Day, Hour}
  use Domo

  defstruct current: nil, daily: nil, hourly: nil, last_updated: nil

  @type t :: %__MODULE__{
          current: Current.t() | nil,
          daily: [Day.t()] | nil,
          hourly: [Hour.t()] | nil,
          last_updated: DateTime.t() | nil
        }
end
