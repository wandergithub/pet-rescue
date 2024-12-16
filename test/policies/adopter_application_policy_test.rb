require "test_helper"

# See https://actionpolicy.evilmartians.io/#/testing?id=testing-policies
class AdopterApplicationPolicyTest < ActiveSupport::TestCase
  include PetRescue::PolicyAssertions

  context "relation_scope" do
    setup do
      policy = -> {
        AdopterApplicationPolicy.new(AdopterApplication, user: @user)
      }
      target = -> { AdopterApplication.all }
      @scope = -> {
        policy.call.apply_scope(target.call, type: :active_record_relation)
          .pluck(:id)
      }
    end

    context "when user is adopter" do
      setup do
        @user = create(:adopter)
      end

      context "when there are applications that do not belong to user" do
        setup do
          @user_applications = [
            create(:adopter_application, person: @user.person),
            create(:adopter_application, person: @user.person)
          ]
          @other_application = create(:adopter_application)
        end

        should "return only user's applications" do
          expected = @user_applications.map(&:id)
          assert_equal(expected, @scope.call)
        end
      end

      context "when user has no applications" do
        setup do
          @other_application = create(:adopter_application)
        end

        should "return empty array" do
          assert_equal([], @scope.call)
        end
      end
    end
  end

  context "#index?" do
    setup do
      @policy = -> {
        AdopterApplicationPolicy.new(AdopterApplication, user: @user)
      }
      @action = -> { @policy.call.apply(:index?) }
    end

    context "when user is nil" do
      setup do
        @user = nil
      end

      should "return false" do
        assert_equal false, @action.call
      end
    end

    context "when user is adopter" do
      setup do
        @user = create(:adopter)
      end

      should "return true" do
        assert_equal true, @action.call
      end
    end

    context "when user is fosterer" do
      setup do
        @user = create(:fosterer)
      end

      should "return false" do
        assert_equal false, @action.call
      end
    end
  end

  context "#create?" do
    setup do
      @pet = create(:pet)
      @policy = -> {
        AdopterApplicationPolicy.new(AdopterApplication, user: @user,
          pet: @pet)
      }
      @action = -> { @policy.call.apply(:create?) }
    end

    context "when user is nil" do
      setup do
        @user = nil
      end

      should "return false" do
        assert_equal false, @action.call
      end
    end

    context "when user is adopter" do
      setup do
        @user = create(:adopter)
      end

      context "when pet application is paused" do
        setup do
          @pet = create(:pet, application_paused: true)
        end

        should "return false" do
          assert_equal false, @action.call
        end
      end

      context "when pet application is not paused" do
        setup do
          @pet = create(:pet, application_paused: false)
        end

        context "when user already has an existing application for the pet" do
          setup do
            _existing_app = create(:adopter_application, pet: @pet, person: @user.person)
          end

          should "return false" do
            assert_equal false, @action.call
          end
        end

        context "when user has not applied for the pet" do
          should "return true" do
            assert_equal true, @action.call
          end
        end
      end
    end

    context "when user is fosterer" do
      setup do
        @user = create(:fosterer)
      end

      should "return false" do
        assert_equal false, @action.call
      end
    end
  end

  context "existing record action" do
    setup do
      @adopter = create(:adopter)
      @adopter_application = create(:adopter_application, person: @adopter.person)
      @policy = -> {
        AdopterApplicationPolicy.new(@adopter_application, user: @user)
      }
    end

    context "#update?" do
      setup do
        @action = -> { @policy.call.apply(:update?) }
      end

      context "when user is nil" do
        setup do
          @user = nil
        end

        should "return false" do
          assert_equal false, @action.call
        end
      end

      context "when adopter account does not belong to user" do
        context "when user is adopter" do
          setup do
            @user = create(:adopter)
          end

          should "return false" do
            assert_equal false, @action.call
          end
        end

        context "when user is fosterer" do
          setup do
            @user = create(:fosterer)
          end

          should "return false" do
            assert_equal false, @action.call
          end
        end

        context "when user is active staff" do
          setup do
            @user = create(:admin)
          end

          should "return false" do
            assert_equal false, @action.call
          end
        end

        context "when user is staff admin" do
          setup do
            @user = create(:super_admin)
          end

          should "return false" do
            assert_equal false, @action.call
          end
        end
      end
    end
  end
end
