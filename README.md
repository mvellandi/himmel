# Himmel: A Weather App inspired by Apple

## Features
Himmel provides current and forecasted weather from any web browser. Users are able to see conditions for their current location and any place they search for. With an account, users can save their favorite places and receive hourly weather updates while the app is open. This app is modified for demo purposes with a guest account and a private admin pin for updating authorization credentials.

## Tech Stack
- **Language**: Elixir  
- **Framework**: Phoenix with LiveView  
- **Database**: PostgreSQL  
- **APIs**: IPinfo, Open-Meteo  
- **CSS**: TailwindCSS  
- **Design**: [Figma](https://www.figma.com/file/dg5sUKM9JKNOKSKUHC1spA/_Project---DA---Capstone-Weather?type=design&mode=design&t=pRx3232w0ePhULsv-1)

## UX Considerations
- Users are able to fully use the app without an account.
- Although a user's current location is automatically inferred by their IP address, it is possibly inaccurate. On mobile devices, an advisory banner is displayed to inform users of this possibility with the option to search for a specific location.
- If the IP address info service is unavailable, the app will default to another location.
- If the weather service is unavailable, the app will display an advisory message.
- The UI is well-designed for mobile and desktop.

## Scalabilty / Performance
- User accounts and authentication
- Cache with 30min TTL
- Hourly weather updates requested only for places with active users
- Updates are sent to the cache and to subscribers via PubSub
- Server-side rendering with html updates via WebSockets

## Background
This application was my capstone project for [Dockyard Academy](https://academy.dockyard.com/), a 3-month live training program in summer 2023. A weather app was chosen because of the challenges in retrieving and processing weather data for specific UI components. To better focus on development, I used the Apple Weather app for design inspiration. In fall 2023, I continued to improve the app by adding a cache, hourly weather updates, a type system for weather info, and error handling among other features. Himmel is a German word meaning "sky" or "heaven".
