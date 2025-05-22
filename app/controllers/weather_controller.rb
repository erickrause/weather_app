class WeatherController < ApplicationController
  def new
  end

  def create
    # Uncomment the following lines to test with hardcoded addresses
    # params[:address] = "1600 Amphitheatre Parkway, Mountain View, CA"
    # params[:address] = "1950 S Holly St, Denver, CO 80220"
    # params[:address] = "7515 W Mulberry Dr, Phoenix, AZ 85033"

    if params[:address].present?
      QueryWeatherJob.perform_later(params[:address], session[:session_id])
    else
      flash.now[:alert] = "Please enter an address"
      render :new
    end
  end
end
