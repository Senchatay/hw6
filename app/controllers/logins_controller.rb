class LoginsController < ApplicationController
    skip_before_action :check_aut
  def show
  end

  def create
    redirect_to :login, notice: LoginService.new(params, session).call
  rescue
    redirect_to login_path, notice: "Неверный пароль"
  end

  def destroy
    session.delete(:login)
    redirect_to :login, notice: "Вы вышли"
  end
end
