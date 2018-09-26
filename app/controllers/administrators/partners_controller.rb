class Administrators::PartnersController < ApplicationController
  before_action :authenticate_administrator!

  def new
    @partner = Partner.new
  end

  def create
    password = (0..8).map { ('a'..'z').to_a[rand(26)] }.join
    @partner = Partner.new(partner_params)
    @partner.password = password
    @partner.password_confirmation = password
    @partner.save!
    redirect_to action: :index
  end

  def index
    @partner = Partner.all
  end

  private

  def partner_params
    params.require(:partner).permit(:first_name, :middle_name, :last_name, :email)
  end
end