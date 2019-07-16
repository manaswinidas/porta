require 'test_helper'

class Master::Providers::SwitchesControllerTest < ActionController::TestCase

  setup do
    master = Account.master rescue FactoryBot.create(:simple_master)
    login_as FactoryBot.create(:simple_user, account: master)

    host! master.domain
  end

  test 'should return 404 in case of wrong switch' do
    put :update, provider_id: provider.id, id: 'unknown'
    assert_response :not_found
  end

  test 'should enable the switch when denied' do
    switch = settings.switches.fetch(:web_hooks)
    assert switch.denied?

    put :update, provider_id: provider.id, id: 'web_hooks'
    assert_response :found

    assert switch.reload.allowed?
  end

  test 'should disable the switch when hidden' do
    switch = settings.switches.fetch(:finance)
    assert switch.allow

    delete :destroy, provider_id: provider.id, id: switch.name
    assert_response :found

    assert switch.reload.denied?
  end

  test 'should disable the switch when visible' do
    rolling_updates_off
    provider.settings.allow_multiple_users!

    delete :destroy, provider_id: provider.id, id: :multiple_users
    assert_response :found
  end

  # @return [Account]
  def provider
    @_provider ||= FactoryBot.create(:simple_provider)
  end

  def allowed_switch(name)
    switch = settings.switches.fetch(name)
    assert switch.allow && switch.show!
    switch
  end

  delegate :settings, to: :provider
end
