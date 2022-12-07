class API::V1::TagsController < API::ApplicationController
  before_action :set_tag, only: [:activate_random_display, :activate_random, :activate_random_pattern]

  def index
    @tags = Tag.all
    render json: @tags.to_json
  end

  def activate_random
    @tag.activate_random
  end

  def activate_random_display
    @tag.activate_random_display
  end

  def activate_random_pattern
    @tag.activate_random_pattern
  end

  private

  def set_tag
    @tag = Tag.find(params[:id])
  end

  def tag_params
    params.require(:tag).permit()
  end
end