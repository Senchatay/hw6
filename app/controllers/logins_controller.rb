class LoginsController < ApplicationController
    skip_before_action :check_aut
  def show
  end

  def create
    if params[:password] == "123"
      session[:login] = params[:login]
      session[:balance] = 1000 unless session[:balance]
      t = Time.now.hour
      session[:time] = t 
      case t
      when (4..11)
        str="Доброе утро"
      when (12..16)
        str = "Добрый день"
      when (17..22)
        str="Добрый вечер"
      else
        str="Доброй ночи"
      end

      redirect_to :login, notice: str+", #{session[:login]}"
    else
      redirect_to :login, notice: "Неверный пароль"
    end
  end

  def destroy
    session.delete(:login)
    redirect_to :login, notice: "Вы вышли"
  end
end
