class Administrators::PartnerOrganizationsController < ApplicationController
  before_action :authenticate_administrator!

  def index
    @partner_organizations = PartnerOrganization.all
  end

  def new
    @partner_organization = PartnerOrganization.new
  end

  def create
    @partner_organization = PartnerOrganization.new(partner_organization_params)
    @partner_organization.save!
    redirect_to action: :index
  end

  def partner_organization_params
    params.require(:partner_organization).permit(:name, :description, :payment_network, :status, :country_id)
  end
end