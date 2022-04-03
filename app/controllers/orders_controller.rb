class OrdersController < ApplicationController
  before_action :set_order, only: %i[ show edit update destroy ]
  skip_before_action :verify_authenticity_token

  def check(cpu, ram, hdd_type, hdd_capacity, os)
    require "json"
    require "net/http"
  
    uri = URI("http://possible_orders.srv.w55.ru/")
    res = Net::HTTP.get_response(uri)
  
    hash = JSON.parse(res.body)
    current_vm = { "os" => os, "cpu" => cpu, "ram" => ram, "hdd_type" => hdd_type, "hdd_capacity" => hdd_capacity }
    
    x = hash["specs"].find { |virtual_machine| #Если в списке ВМ внешнего сервиса найдется такая ВМ, что
      virtual_machine.select { |key, value| #Значения полей этой ВМ будут совпадать с значениями таких же полей current_vm
        value.find { |x|
          (x == current_vm[key]) || (x.kind_of?(Array) && x[0] == current_vm["hdd_type"] && current_vm[key] > x[1]["from"] && current_vm[key] < x[1]["to"]) #Либо обычные поля хэша, либо hdd_capacity, который в find приходит массивом вида ["sata",{"from"=>20,"to"=>100}]
        }
      }.length==5 #Совпасть должны все поля
    }
  #   puts x
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
