class OrderService
  attr_reader :params, :session

  require "json"
  require "net/http"

  URI_ORDERS = URI(ENV["ORDERS_ADDRESS"])

  def initialize(params, session)
    @params, @session = params, session
    @current_vm = params.permit(:os, :cpu, :ram, :hdd_type, :hdd_capacity).to_h
    [:cpu, :ram, :hdd_capacity].each { |key| @current_vm[key] = @current_vm[key].to_i }
  end

  def call
    output = { "result" => false, "status" => 503 }

    res = Net::HTTP.get_response(URI_ORDERS)
    return output unless valid_503?(res)

    configuration_list = JSON.parse(res.body)

    res = price_request()
    return output unless valid_503?(res)
    cost = res.body.to_f

    if find_vm(configuration_list) && balance_enough?(cost)
      balance_before = session[:balance]

      session[:balance] -= cost
      output = { "result" => true, "total" => cost, "balance" => balance_before.round(2), "balance_after_transaction" => session[:balance].round(2), "status" => 200 }
    else
      output = { "result" => false, "error" => "Используется некорректная конфигурация ВМ или недостаточно средств", "status" => 406 }
    end
    output
  end

  private

  def find_vm(configuration_list)
    configuration_list["specs"].any? do |virtual_machine| #Если в списке ВМ внешнего сервиса найдется такая ВМ, что
      spec_capacity_for_current_type = virtual_machine["hdd_capacity"][@current_vm[:hdd_type]]

      range = (spec_capacity_for_current_type["from"]..spec_capacity_for_current_type["to"]) if spec_capacity_for_current_type

      (["os", "cpu", "ram", "hdd_type"].select do |param|
        virtual_machine[param].any?(@current_vm[param])
      end.length == 4) && (@current_vm[:hdd_capacity].in?(range))
    end
  end

  def price_request
    uri_calc = URI(ENV["VM_COST_SERVICE_ADDRESS"] + URI.encode_www_form(@current_vm))
    res = Net::HTTP.get_response(uri_calc)
  end

  def valid_503?(res)
    return false unless res.kind_of?(Net::HTTPSuccess) #render(status: 503) &&
    true
  end

  def balance_enough?(cost)
    session[:balance] >= cost
  end
end
