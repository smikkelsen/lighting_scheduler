class API::V1::TagsController < API::V1::ApplicationController
  before_action :set_tag, only: [:activate_random_display]

  def index
    @tags = Tag.all
    render json: @tags.to_json
  end

  def activate_random_display
    @tag.activate_random_display
  end

  private

  def set_tag
    @tag = Tag.find(params[:id])
  end

  def tag_params
    params.require(:tag).permit()
  end
end
