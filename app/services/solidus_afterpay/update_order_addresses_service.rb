# frozen_string_literal: true

module SolidusAfterpay
  class UpdateOrderAddressesService < BaseService
    def initialize(order:, address_params:)
      @order = order
      @address_params = address_params

      super()
    end

    def call
      order.state = 'address'
      order.email = SolidusAfterpay.configuration.dummy_email if order.email.blank?
      order.ship_address_attributes = address_object
      order.bill_address_attributes = address_object
      order.save
    end

    private

    def address_object
      {
        address1: address_params[:address1],
        address2: address_params[:address2],
        name: address_params[:name],
        city: address_params[:suburb],
        zipcode: address_params[:postcode],
        phone: address_params[:phoneNumber],
        country: country,
        state: state
      }
    end

    def country
      @country ||= ::Spree::Country.find_by(iso: address_params[:countryCode])
    end

    def state
      @state ||= ::Spree::State.find_by(country_id: country.id, abbr: address_params[:state])
    end

    attr_reader :order, :address_params
  end
end
