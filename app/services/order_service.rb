class OrderService
  attr_reader :params, :session
  
  require "json"
  require "net/http"
  
  URI_ORDERS = URI("http://possible_orders.srv.w55.ru/")
  ERROR = "Программа завершилась с ошибкой."

  def initialize(params)
    @params, @session = params, session
    @current_vm = { "os" => params[:os], "cpu" => params[:cpu].to_i, "ram" => params[:ram].to_i, "hdd_type" => params[:hdd_type], "hdd_capacity" => params[:hdd_capacity].to_i }
  end

  def call
    check_401

    res = Net::HTTP.get_response(URI_ORDERS)
    return ERROR unless valid_503(res)

    hash = JSON.parse(res.body)
    
    res = price_request()
    return ERROR unless valid_503(res)

    if find_vm(hash) && balance_enough(res.body.to_f)
      balance_before = session[:balance]

      session[:balance] -= cost
      @output = { "result" => true, "total" => cost, "balance" => balance_before, "balance_after_transaction" => session[:balance] }.to_json

      render status: 200
    else
      @output = { "result" => false, "error" => "Используется некорректная конфигурация ВМ или недостаточно средств" }.to_json
      render status: 406
    end
    return @output
  end

  private

  def find_vm(hash)
    x = hash["specs"].find { |virtual_machine| #Если в списке ВМ внешнего сервиса найдется такая ВМ, что
      virtual_machine.select { |key, value| #Значения полей этой ВМ будут совпадать с значениями таких же полей current_vm
        value.find { |x|
          (x == @current_vm[key]) || (x.kind_of?(Array) && x[0] == @current_vm["hdd_type"] && @current_vm[key] > x[1]["from"] && @current_vm[key] < x[1]["to"]) #Либо обычные поля хэша, либо hdd_capacity, который в find приходит массивом вида ["sata",{"from"=>20,"to"=>100}]
        }
      }.length == 5 #Совпасть должны все поля
    }
    return true if x
    return false
  end

  def price_request
    str = "http://hw4:5678/cost?"
    @current_vm.each { |k, v| str += "#{k}=#{v}&" }

    uri_calc = URI(str.chop!)
    res = Net::HTTP.get_response(uri_calc)
  end

  def valid_503(res)
    unless res.code == "200"
      render status: 503
      false
    else
      true
    end
  end

  def balance_enough(cost)
    if session[:balance] >= cost
      true
    else
      false
    end
  end
end
