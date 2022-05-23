class DisplaysController < ApplicationController
  before_action :set_display, only: [:activate]

  def index
    @displays = Display.where(workflow_state: 'active')
    render json: @displays.to_json
  end

  def activate
    @display.activate
  end

  def turn_off
    Display.turn_off
  end

  private

  def set_display
    @display = Display.find(params[:id])
  end

  def display_params
    params.require(:display).permit()
  end
end
