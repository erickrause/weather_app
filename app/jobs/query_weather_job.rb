class QueryWeatherJob < ApplicationJob
  queue_as :default

  def perform(address, session_id)
    location = Geocoder.search(address)&.first

    weather_data =
      query_weather_data_from_cache(location, session_id) ||
        query_weather_data(location)

    Turbo::StreamsChannel.broadcast_replace_to(
      session_id,
      "forecast",
      target: "results",
      partial: "weather/forecast_results",
      locals: {
        current_temperature: weather_data.dig(:current_temperature),
        current_description: weather_data.dig(:current_description),
        city: weather_data.dig(:city),
        forecasts: weather_data.dig(:forecasts)
      }
    )
  end

  private

  def query_weather_data_from_cache(location, session_id)
    weather_data =
      Rails.cache.read(weather_data_cache_key(location.postal_code))

    Turbo::StreamsChannel.broadcast_replace_to(
      session_id,
      "cache_status",
      target: "cache_status",
      partial: "shared/cache_status",
      locals: {
        cached: weather_data.present?
      }
    )

    weather_data
  end

  def query_weather_data(location)
    client = WeatherGovApi::Client.new

    # Weather api only allows for 4 decimal places so we use the rounded values
    current_weather =
      client.current_weather(
        latitude: location.latitude.round(4),
        longitude: location.longitude.round(4)
      )

    # Weather api only allows for 4 decimal places so we use the rounded values
    forecast =
      client.forecast(
        latitude: location.latitude.round(4),
        longitude: location.longitude.round(4)
      )

    weather_data = {
      current_temperature:
        convert_celsius_to_fahrenheit(
          current_weather.data.dig("properties", "temperature", "value")
        ),
      current_description:
        current_weather.data.dig("properties", "textDescription"),
      city: location.city,
      forecasts: forecast.data.dig("properties", "periods")
    }

    Rails.cache.write(
      weather_data_cache_key(location.postal_code),
      weather_data,
      expires_in: 10.seconds
    )

    weather_data
  end

  def weather_data_cache_key(postal_code)
    "weather_data/#{postal_code}"
  end

  def convert_celsius_to_fahrenheit(celsius)
    return nil if celsius.nil?
    ((celsius * 9.0 / 5.0) + 32).round
  end
end
