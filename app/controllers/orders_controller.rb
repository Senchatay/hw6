class OrdersController < ApplicationController
  before_action :set_order, only: %i[ show edit update destroy ]
  skip_before_action :verify_authenticity_token
  skip_before_action :check_aut, only: %i[check]

  def check #(cpu, ram, hdd_type, hdd_capacity, os)
    unless session[:login]
      render status: 401
      # redirect_to login_path
      return
    end
    require "json"
    require "net/http"

    uri_orders = URI("http://possible_orders.srv.w55.ru/")
    res = Net::HTTP.get_response(uri_orders)
    unless res.code == "200"
      render status: 503 
      return
    end
    
    hash = JSON.parse(res.body)
    current_vm = { "os" => params[:os], "cpu" => params[:cpu].to_i, "ram" => params[:ram].to_i, "hdd_type" => params[:hdd_type], "hdd_capacity" => params[:hdd_capacity].to_i }
    
    finded = false
    x = hash["specs"].find { |virtual_machine| #Если в списке ВМ внешнего сервиса найдется такая ВМ, что
      virtual_machine.select { |key, value| #Значения полей этой ВМ будут совпадать с значениями таких же полей current_vm
        value.find { |x|
          (x == current_vm[key]) || (x.kind_of?(Array) && x[0] == current_vm["hdd_type"] && current_vm[key] > x[1]["from"] && current_vm[key] < x[1]["to"]) #Либо обычные поля хэша, либо hdd_capacity, который в find приходит массивом вида ["sata",{"from"=>20,"to"=>100}]
        }
      }.length == 5 #Совпасть должны все поля
    }
    finded = true if x
    
    str = "http://hw4:5678/cost?"
    current_vm.each { |k, v| str += "#{k}=#{v}&" }
    uri_calc = URI(str.chop!)
    cost = Net::HTTP.get_response(uri_calc)
    unless cost.code == "200"
      render status: 503 
      return
    end
    cost = cost.body.to_f
    balance_enough = true if session[:balance] >= cost

    if finded && balance_enough
      balance_before = session[:balance]
      session[:balance] -= cost

      @output = { "result" => true, "total" => cost, "balance" => balance_before, "balance_after_transaction" => session[:balance] }.to_json

      # render json: @output
      render status: 200
      return @output
      # elsif finded
      #   error = "Недостаточно средств."
      # elsif balance_enough
      #   error = "Не найдено подходящих Виртуальных Машин."
    else
      @output = { "result" => false, "error" => "Используется некорректная конфигурация ВМ или недостаточно средств" }.to_json
      render status: 406
      return @output
    end
  end

  def first
    @order = Order.first
    render :show
  end

  def approve
    render json: params
  end

  def calc
    # render plain: "OK"
    @x = rand(100)
  end

  # GET /orders or /orders.json
  def index
    @orders = Order.all
    @users = User.all
    @users.first
    puts "params: #{params.inspect}"
  end

  # GET /orders/1 or /orders/1.json
  def show
  end

  # GET /orders/new
  def new
    @order = Order.new
  end

  # GET /orders/1/edit
  def edit
  end

  # POST /orders or /orders.json
  def create
    # byebug params[:order]
    @order = Order.new(order_params)

    respond_to do |format|
      if @order.save
        format.html { redirect_to order_url(@order), notice: "Order was successfully created." }
        format.json { render :show, status: :created, location: @order }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @order.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /orders/1 or /orders/1.json
  def update
    respond_to do |format|
      if @order.update(order_params)
        format.html { redirect_to order_url(@order), notice: "Order was successfully updated." }
        format.json { render :show, status: :ok, location: @order }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @order.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /orders/1 or /orders/1.json
  def destroy
    @order.destroy

    respond_to do |format|
      format.html { redirect_to orders_url, notice: "Order was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_order
    @order = Order.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def order_params
    params.require(:order).permit(:name, :status, :cost)
  end
end
