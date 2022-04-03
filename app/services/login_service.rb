class LoginService
  attr_reader :params, :session

  def initialize(params, session)
    @params, @session = params, session
  end

  def call
    check_password
    modify_session
    message
  end

  private

  def check_password
    raise if params[:password] != "123"
  end

  def modify_session
    session[:login] = params[:login]
    session[:balance] = 1000 #unless session[:balance]
    t = Time.now.hour
    session[:time] = t
  end

  def message
    case session[:time]
    when (4..11)
      str = "Доброе утро"
    when (12..16)
      str = "Добрый день"
    when (17..22)
      str = "Добрый вечер"
    else
      str = "Доброй ночи"
    end
    @notice_message = str + ", #{session[:login]}"
  end

  #     if params[:password] == "123"
  #       session[:login] = params[:login]
  #       session[:balance] = 1000 unless session[:balance]
  #       t = Time.now.hour
  #       session[:time] = t
  #       case t
  #       when (4..11)
  #         str="Доброе утро"
  #       when (12..16)
  #         str = "Добрый день"
  #       when (17..22)
  #         str="Добрый вечер"
  #       else
  #         str="Доброй ночи"
  #       end

  #       redirect_to :login, notice: str+", #{session[:login]}"
  #     else
  #       redirect_to :login, notice: "Неверный пароль"
  #     end
  #   end
end
