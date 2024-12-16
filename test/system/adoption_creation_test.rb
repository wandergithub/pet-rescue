require "application_system_test_case"

class AdoptionCreationTest < ApplicationSystemTestCase
  setup do
    user = create(:admin)
    adopter = create(:adopter)
    @pet = create(:pet)
    create(:adopter_application, :successful_applicant, pet_id: @pet.id, person: adopter.person)

    sign_in user
  end

  context "creating an adoption" do
    should "should display adopted pet's applications after it has been adopted" do
      visit staff_adoption_application_reviews_url
      accept_confirm do
        click_on "New Adoption"
      end
      assert has_current_path?(staff_adoption_application_reviews_path)
      assert_text "Adoption Made"
    end
  end
end
