class SessionsController < ApplicationController
  def create
    user = User.from_omniauth(request.env["omniauth.auth"])
    session[:user_id] = user.id
    redirect_to root_path, notice: t("flash.signed_in")
  end

  def destroy
    session[:user_id] = nil
    redirect_to root_path, notice: t("flash.signed_out")
  end
end
