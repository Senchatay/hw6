class OrdersController < ApplicationController
  before_action :set_order, only: %i[ show edit update destroy ]
  skip_before_action :verify_authenticity_token
  skip_before_action :check_aut, only: %i[check]

  def check
    output = { "result" => false }
    if valid_401?
      output = OrderService.new(params, session).call
    else
      output.merge!({ "status" => 401 })
    end

    render json: output.except("status"), status: output["status"]

    # case output["status"]
    # when 200
    #   render json: output.except("status"), status: 200
    # when 401
    #   render json: output.except("status"), status: 401
    # when 406
    #   render json: output.except("status"), status: 406
    # when 503
    #   render json: output.except("status"), status: 503
    # end
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

  def valid_401?
    return false unless session[:login] #render(status: 401) &&
    true
  end
end
