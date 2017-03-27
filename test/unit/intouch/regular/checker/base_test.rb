require File.expand_path('../../../../../test_helper', __FILE__)

class Intouch::Regular::Checker::BaseTest < ActiveSupport::TestCase
  subject do
    Intouch::Regular::Checker::Base.new(
      issue: issue,
      state: state,
      project: project
    ).required?
  end

  let(:assigner_id) { 1 }
  let(:project) { OpenStruct.new(assigner_ids: [assigner_id]) }

  describe 'notificable for state' do
    before { Issue.any_instance.stubs(:notificable_for_state?).returns(true) }

    describe 'issue assigned to client' do
      let(:client_id) { 2 }
      let(:issue) { Issue.new(assigned_to_id: client_id) }

      describe 'working' do
        let(:state) { 'working' }

        it { subject.must_equal false }
      end

      describe 'feedback' do
        let(:state) { 'feedback' }

        it { subject.must_equal false }
      end

      describe 'unassigned' do
        let(:state) { 'unassigned' }

        it { subject.must_equal true }
      end

      describe 'overdue' do
        let(:state) { 'overdue' }

        it { subject.must_equal true }
      end
    end

    describe 'issue assigned to assigner' do
      let(:issue) { Issue.new(assigned_to_id: assigner_id) }

      describe 'working' do
        let(:state) { 'working' }

        it { subject.must_equal true }
      end

      describe 'feedback' do
        let(:state) { 'feedback' }

        it { subject.must_equal true }
      end

      describe 'unassigned' do
        let(:state) { 'unassigned' }

        it { subject.must_equal true }
      end

      describe 'overdue' do
        let(:state) { 'overdue' }

        it { subject.must_equal true }
      end
    end
  end

  describe 'not notificable' do
    let(:state) { 'some_state' }
    let(:issue) { Issue.new }

    before { Issue.any_instance.stubs(:notificable_for_state?).returns(false) }

    it { subject.must_equal false }
  end
end
