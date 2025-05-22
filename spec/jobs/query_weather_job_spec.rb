require "rails_helper"

RSpec.describe QueryWeatherJob, type: :job do
  let(:address) { "1600 Pennsylvania Ave NW, Washington, DC 20500" }
  let(:session_id) { "abc123" }
  let(:location) do
    double(
      city: "Washington",
      postal_code: "20500",
      latitude: 38.8977,
      longitude: -77.0365
    )
  end

  let(:cached_weather_data) do
    {
      current_temperature: 70,
      current_description: "Clear",
      city: "Washington",
      forecasts: [{ name: "Tonight", temperature: 65 }]
    }
  end

  let(:current_weather_response) do
    double(
      data: {
        "properties" => {
          "temperature" => {
            "value" => 20.0
          },
          "textDescription" => "Partly Cloudy"
        }
      }
    )
  end

  let(:forecast_response) do
    double(
      data: {
        "properties" => {
          "periods" => [{ "name" => "Tonight", "temperature" => 18 }]
        }
      }
    )
  end

  before do
    allow(Geocoder).to receive(:search).and_return([location])
    allow(Turbo::StreamsChannel).to receive(:broadcast_replace_to)
  end

  context "when weather data is cached" do
    before do
      allow(Rails.cache).to receive(:read).and_return(cached_weather_data)
    end

    it "uses cached weather data and broadcasts results" do
      described_class.perform_now(address, session_id)

      expect(Rails.cache).to have_received(:read).with("weather_data/20500")
      expect(Turbo::StreamsChannel).to have_received(
        :broadcast_replace_to
      ).with(
        session_id,
        "forecast",
        hash_including(locals: hash_including(current_temperature: 70))
      )
      expect(Turbo::StreamsChannel).to have_received(
        :broadcast_replace_to
      ).with(
        session_id,
        "cache_status",
        hash_including(locals: { cached: true })
      )
    end
  end

  context "when weather data is not cached" do
    let(:client) { instance_double(WeatherGovApi::Client) }

    before do
      allow(Rails.cache).to receive(:read).and_return(nil)
      allow(Rails.cache).to receive(:write)
      allow(WeatherGovApi::Client).to receive(:new).and_return(client)
      allow(client).to receive(:current_weather).and_return(
        current_weather_response
      )
      allow(client).to receive(:forecast).and_return(forecast_response)
    end

    it "queries weather data and writes to cache" do
      described_class.perform_now(address, session_id)

      expect(client).to have_received(:current_weather).with(
        latitude: 38.8977,
        longitude: -77.0365
      )
      expect(client).to have_received(:forecast).with(
        latitude: 38.8977,
        longitude: -77.0365
      )
      expect(Rails.cache).to have_received(:write).with(
        "weather_data/20500",
        hash_including(current_temperature: 68),
        expires_in: 10.seconds
      )
      expect(Turbo::StreamsChannel).to have_received(
        :broadcast_replace_to
      ).with(
        session_id,
        "forecast",
        hash_including(locals: hash_including(current_temperature: 68))
      )
      expect(Turbo::StreamsChannel).to have_received(
        :broadcast_replace_to
      ).with(
        session_id,
        "cache_status",
        hash_including(locals: { cached: false })
      )
    end
  end

  describe "#convert_celsius_to_fahrenheit" do
    let(:job) { described_class.new }

    it "converts 0°C to 32°F" do
      expect(job.send(:convert_celsius_to_fahrenheit, 0)).to eq(32)
    end

    it "converts 100°C to 212°F" do
      expect(job.send(:convert_celsius_to_fahrenheit, 100)).to eq(212)
    end

    it "converts -40°C to -40°F" do
      expect(job.send(:convert_celsius_to_fahrenheit, -40)).to eq(-40)
    end

    it "rounds the result to the nearest integer" do
      expect(job.send(:convert_celsius_to_fahrenheit, 36.6)).to eq(98)
    end

    it "returns nil when input is nil" do
      expect(job.send(:convert_celsius_to_fahrenheit, nil)).to be_nil
    end
  end
end
