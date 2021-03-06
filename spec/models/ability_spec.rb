require 'rails_helper'
require 'cancan/matchers'

describe Ability do
  subject { described_class.new(current_user) }

  let(:press) { create(:press) }
  let(:sub_brand) { create(:sub_brand, press: press) }

  let(:monograph) { create(:monograph, user: creating_user, press: press.subdomain) }
  let(:section) { create(:section, user: creating_user) }
  let(:file_set) { create(:file_set, user: creating_user) }

  describe 'a platform-wide admin user' do
    let(:creating_user) { current_user }
    let(:current_user) { create(:platform_admin) }
    let(:role) { create(:role) }
    let(:another_user) { create(:user) }
    let(:another_user_monograph) { create(:monograph, user: another_user, press: press.subdomain) }

    it do
      should be_able_to(:create, Monograph.new)
      should be_able_to(:publish, monograph)
      should be_able_to(:read, monograph)
      should be_able_to(:update, monograph)
      should be_able_to(:destroy, monograph)

      should be_able_to(:create, Section.new)
      should be_able_to(:read, section)
      should be_able_to(:update, section)
      should be_able_to(:destroy, section)

      should be_able_to(:create, FileSet.new)
      should be_able_to(:read, file_set)
      should be_able_to(:update, file_set)
      should be_able_to(:destroy, file_set)

      should be_able_to(:read, role)
      should be_able_to(:update, role)
      should be_able_to(:destroy, role)

      should be_able_to(:update, press)
      should be_able_to(:manage, sub_brand)
    end

    it "can read, update, publish or destroy a monograph created by another user" do
      should be_able_to(:read, another_user_monograph)
      should be_able_to(:update, another_user_monograph)
      should be_able_to(:publish, another_user_monograph)
      should be_able_to(:destroy, another_user_monograph)
    end
  end

  describe 'a press-admin' do
    let(:my_press) { create(:press) }
    let(:other_press) { create(:press) }
    let(:my_sub_brand) { create(:sub_brand, press: my_press, title: ['My own sub-brand']) }
    let(:other_sub_brand) { create(:sub_brand, press: other_press, title: ["Someone else's sub-brand"]) }
    let(:current_user) { create(:press_admin, press: my_press) }

    it do
      should     be_able_to(:update, my_press)
      should_not be_able_to(:update, other_press)
      should     be_able_to(:manage, my_sub_brand)
      should_not be_able_to(:manage, other_sub_brand)
      should     be_able_to(:read, other_sub_brand)
    end

    context "roles" do
      let(:my_press_role) { create(:role, resource: my_press) }
      let(:other_press_role) { create(:role) }
      it do
        should be_able_to(:read, my_press_role)
        should be_able_to(:update, my_press_role)
        should be_able_to(:destroy, my_press_role)

        should_not be_able_to(:read, other_press_role)
        should_not be_able_to(:update, other_press_role)
        should_not be_able_to(:destroy, other_press_role)
      end
    end

    context "creating" do
      let(:monograph_for_my_press) { Monograph.new(press: my_press.subdomain) }
      let(:monograph_for_other_press) { Monograph.new(press: other_press.subdomain) }

      it do
        should be_able_to(:create, monograph_for_my_press)

        should_not be_able_to(:create, monograph_for_other_press)
      end
    end
  end

  describe 'a press editor' do
    let(:my_press) { create(:press) }
    let(:my_sub_brand) { create(:sub_brand, press: my_press, title: ['My own sub-brand']) }
    let(:current_user) { create(:editor, press: my_press) }
    let(:monograph_for_my_press) { Monograph.new(press: my_press.subdomain) }

    it do
      should_not be_able_to(:update, my_press)
      should_not be_able_to(:create, monograph_for_my_press)
      should_not be_able_to(:manage, my_sub_brand)
      should     be_able_to(:read, my_sub_brand)
    end
  end

  describe 'public user' do
    let(:creating_user) { create(:user) }
    let(:current_user) { User.new }

    context "creating" do
      it do
        should_not be_able_to(:create, Monograph.new)
        should_not be_able_to(:create, Section.new)
        should_not be_able_to(:create, FileSet.new)
      end
    end

    context "presses" do
      it do
        should     be_able_to(:index, Press)
        should     be_able_to(:read, press)
        should_not be_able_to(:update, press)
        should_not be_able_to(:manage, sub_brand)
        should     be_able_to(:read, sub_brand)
      end
    end

    context "read/modify/destroy private things" do
      it do
        should_not be_able_to(:read, monograph)
        should_not be_able_to(:publish, monograph)
        should_not be_able_to(:update, monograph)
        should_not be_able_to(:destroy, monograph)

        should_not be_able_to(:read, section)
        should_not be_able_to(:update, section)
        should_not be_able_to(:destroy, section)

        should_not be_able_to(:read, file_set)
        should_not be_able_to(:update, file_set)
        should_not be_able_to(:destroy, file_set)
      end
    end

    context "read/modify/destroy public things" do
      let(:monograph) { create(:public_monograph, user: creating_user, press: press.subdomain) }
      let(:section) { create(:public_section, user: creating_user) }
      let(:file_set) { create(:public_file_set, user: creating_user) }
      it do
        should be_able_to(:read, monograph)
        should_not be_able_to(:update, monograph)
        should_not be_able_to(:destroy, monograph)
        should_not be_able_to(:publish, monograph)

        should be_able_to(:read, section)
        should_not be_able_to(:update, section)
        should_not be_able_to(:destroy, section)

        should be_able_to(:read, file_set)
        should_not be_able_to(:update, file_set)
        should_not be_able_to(:destroy, file_set)
      end
    end

    context "admin only things" do
      let(:role) { create(:role) }
      it do
        should_not be_able_to(:read, role)
        should_not be_able_to(:update, role)
        should_not be_able_to(:destroy, role)
      end
    end
  end
end
