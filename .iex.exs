alias Himmel.Places
alias Himmel.Places.{Place, Coordinates}
alias Himmel.Accounts
alias Himmel.Accounts.User
alias Himmel.Repo

user = List.first(Repo.all(User)) || nil

place = %{name: "Hamburg", coordinates: %{latitude: 18.1, longitude: 8.1}}
places = %{0 => place}
