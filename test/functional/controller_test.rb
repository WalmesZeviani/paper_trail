require 'test_helper'

class ControllerTest < ActionController::TestCase
  tests WidgetsController

  setup do
    @request.env['REMOTE_ADDR'] = '127.0.0.1'
  end

  # Mimick what RequestStore will do outside of the test env, since it is
  # middleware, and doesn't get executed in controller / request specs
  teardown do
    RequestStore.store[:paper_trail] = nil
  end

  test 'disable on create' do
    @request.env['HTTP_USER_AGENT'] = 'Disable User-Agent'
    post :create, params_wrapper({ widget: { name: 'Flugel' } })
    assert_equal 0, assigns(:widget).versions.length
  end

  test 'disable on update' do
    @request.env['HTTP_USER_AGENT'] = 'Disable User-Agent'
    post :create, params_wrapper({ widget: { name: 'Flugel' } })
    w = assigns(:widget)
    assert_equal 0, w.versions.length
    put :update, params_wrapper({ id: w.id, widget: { name: 'Bugle' } })
    widget = assigns(:widget)
    assert_equal 0, widget.versions.length
  end

  test 'disable on destroy' do
    @request.env['HTTP_USER_AGENT'] = 'Disable User-Agent'
    post :create, params_wrapper({ widget: { name: 'Flugel' } })
    w = assigns(:widget)
    assert_equal 0, w.versions.length
    delete :destroy, params_wrapper({ id: w.id })
    assert_equal 0, PaperTrail::Version.with_item_keys('Widget', w.id).size
  end

  test 'create' do
    post :create, params_wrapper({ widget: { name: 'Flugel' } })
    widget = assigns(:widget)
    assert_equal 1, widget.versions.length
    assert_equal 153, widget.versions.last.whodunnit.to_i
    assert_equal '127.0.0.1', widget.versions.last.ip
    assert_equal 'Rails Testing', widget.versions.last.user_agent
  end

  test 'update' do
    w = Widget.create :name => 'Duvel'
    assert_equal 1, w.versions.length
    put :update, params_wrapper({ id: w.id, widget: { name: 'Bugle' } })
    widget = assigns(:widget)
    assert_equal 2, widget.versions.length
    assert_equal 153, widget.versions.last.whodunnit.to_i
    assert_equal '127.0.0.1', widget.versions.last.ip
    assert_equal 'Rails Testing', widget.versions.last.user_agent
  end

  test 'destroy' do
    w = Widget.create :name => 'Roundel'
    assert_equal 1, w.versions.length
    delete :destroy, params_wrapper({ id: w.id })
    widget = assigns(:widget)
    assert_equal 2,               widget.versions.length
    assert_equal '127.0.0.1',     widget.versions.last.ip
    assert_equal 'Rails Testing', widget.versions.last.user_agent
    assert_equal 153,             widget.versions.last.whodunnit.to_i
  end

  test "controller metadata methods should get evaluated if PT enabled for controller" do
    @request.env['HTTP_USER_AGENT'] = 'User-Agent'
    post :create, params_wrapper({ widget: { name: 'Flugel' } })
    assert PaperTrail.enabled_for_controller?
    assert_equal 153, PaperTrail.whodunnit
    assert PaperTrail.controller_info.present?
    assert PaperTrail.controller_info.keys.include?(:ip)
    assert PaperTrail.controller_info.keys.include?(:user_agent)
  end

  test "controller metadata methods should not get evaluated if PT disabled for controller" do
    @request.env['HTTP_USER_AGENT'] = 'Disable User-Agent'
    post :create, params_wrapper({ widget: { name: 'Flugel' } })
    assert_equal 0, assigns(:widget).versions.length
    assert !PaperTrail.enabled_for_controller?
    assert PaperTrail.whodunnit.nil?
    assert PaperTrail.controller_info.nil?
  end
end
