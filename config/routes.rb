# frozen_string_literal: true

SolidusAfterpay::Engine.routes.draw do
  match '/callbacks/confirm', to: '/solidus_afterpay/callbacks#confirm', via: %i[get post]
  get '/callbacks/cancel', to: '/solidus_afterpay/callbacks#cancel'
  post '/checkouts', to: '/solidus_afterpay/checkouts#create'
end
