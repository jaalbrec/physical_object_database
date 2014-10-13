#authentication methods for testing in Capybara

module FeatureHelpers
  def sign_in(username = "user@example.com")
    page.set_rack_session(username: username)
    SessionInfoModule.session = page.get_rack_session
  end
  
  def sign_out
    sign_in(nil)
  end

  def confirm_popup
    page.driver.browser.accept_js_confirms
  end

  def reject_popup
    page.driver.browser.reject_js_confirms
  end

  def conclude_jquery
    loop until page.evaluate_script('jQuery.active').zero?
  end

end

RSpec.configure do |config|
  config.include FeatureHelpers, type: :feature
end
