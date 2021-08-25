# frozen_string_literal: true

SolidusAfterpay::Engine.routes.draw do
  get '/callbacks/confirm', to: '/solidus_afterpay/callbacks#confirm'
  get '/callbacks/cancel', to: '/solidus_afterpay/callbacks#cancel'
end
