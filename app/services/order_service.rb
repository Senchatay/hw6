class OrderService
  attr_reader :params, :session

  require "json"
  require "net/http"

  URI_ORDERS = URI("http://possible_orders.srv.w55.ru/")
  ERROR = "Программа завершилась с ошибкой: "

  def initialize(params, session)
    @params, @session = params, session
    @current_vm = params.permit(:os, :cpu, :ram, :hdd_type, :hdd_capacity).to_h
    [:cpu, :ram, :hdd_capacity].each { |key| @current_vm[key] = @current_vm[key].to_i }
  end

  def call
    return ERROR + "401" unless valid_401

    res = Net::HTTP.get_response(URI_ORDERS)
    return ERROR + "503" unless valid_503(res)

    hash = JSON.parse(res.body)

    res = price_request()
    return ERROR + "503" unless valid_503(res)
    cost = res.body.to_f
    output = {}
    if find_vm(hash) && balance_enough(cost)
      balance_before = session[:balance]

      session[:balance] -= cost
      output = { "result" => true, "total" => cost, "balance" => balance_before.round(2), "balance_after_transaction" => session[:balance].round(2) }

      #   render status: 200
    else
      output = { "result" => false, "error" => "Используется некорректная конфигурация ВМ или недостаточно средств" }
      #   render status: 406
    end
    output
  end

  private

  def find_vm(hash)
    hash["specs"].any? do |virtual_machine| #Если в списке ВМ внешнего сервиса найдется такая ВМ, что
      virtual_machine.select { |key, value|
        (value.include?(@current_vm[key])) || (value.kind_of?(Hash) && value.any? { |x| x[0] == @current_vm["hdd_type"] && @current_vm[key].in?(x[1]["from"]..x[1]["to"]) })
      }.length == 5 #Совпасть должны все поля
    end
  end

  def price_request
    str = "http://hw4:5678/cost?"
    str += URI.encode_www_form(@current_vm)
    uri_calc = URI(str)
    res = Net::HTTP.get_response(uri_calc)
  end

  def valid_401
    return false unless session[:login] #render(status: 401) &&
    true
  end

  def valid_503(res)
    return false unless res.kind_of?(Net::HTTPSuccess) #render(status: 503) &&
    true
  end

  def balance_enough(cost)
    session[:balance] >= cost
  end
end
