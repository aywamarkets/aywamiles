class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  #protect_from_forgery prepend: true

  def after_sign_in_path_for(entity)
    if entity.is_a?(Administrator)
      administrators_root_path(entity)
    else
      super
    end
  end
end
