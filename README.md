# **Weather App**

A simple weather app that using Rails and Hotwire.  Entering an address will query Weather.gov and give the current weather and forecast.

## **Setup**

#### **Install Gems/Packages:**

You'll need ruby installed. [RVM](https://rvm.io/) or [asdf](https://asdf-vm.com/) should install the correct version automatically.

```sh
$ bundle
```

#### **Run the Server:**
```sh
$ ./bin/dev
```

## **Design**

I ended up pushing the logic for weather cache lookup and streaming to a background job.  Parsing the postal code was using an external api.  Since that was already querying a third party service, I made the judgement call to push all of the external calls to the background job where an external api call wouldn't potentially lock the rails server's thread.  Data is pushed back to the frontend via turbo streams.

## **External APIs**

Currently using [geocoder](https://github.com/alexreisner/geocoder) gem to both parse the postal code for caching and conversion to lat/long for lookup in the weather api.
The weather data is pulled from [weather.gov](https://www.weather.gov/) via the [weather_gov_api](https://rubygems.org/gems/weather_gov_api) gem.  During testing it became obvious that the data coming back from the api was quite inconsistent.  Current temperature and the weather's short description are sometimes just empty.

## **Screenshot**
<img width="512" alt="Monosnap Weather App 2025-05-21 23-20-32" src="https://github.com/user-attachments/assets/08946050-02ee-4dda-be3f-201195da8408" />
