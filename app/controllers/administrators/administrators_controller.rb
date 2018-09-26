class Administrators::AdministratorsController < ApplicationController
  before_action :authenticate_administrator!

  def new
    @administrator = Administrator.new
  end

  def create
    password = (0..8).map { ('a'..'z').to_a[rand(26)] }.join
    @administrator = Administrator.new(administrator_params)
    @administrator.password = password
    @administrator.password_confirmation = password
    @administrator.save!
    redirect_to action: :index
  end

  def index
    @administrators = Administrator.all
  end

  private

  def administrator_params
    params.require(:administrator).permit(:first_name, :middle_name, :last_name, :email)
  end
end