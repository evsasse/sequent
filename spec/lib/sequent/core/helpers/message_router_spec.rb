# frozen_string_literal: true

require 'spec_helper'

describe Sequent::Core::Helpers::MessageRouter do
  let(:message_router) { Sequent::Core::Helpers::MessageRouter.new }

  let(:handler) { double('handler') }
  let(:other_handler) { double('other handler') }

  describe '#match_message' do
    subject do
      handlers = message_router.match_message(message)
      # `match_message` must be consistent with `matches_message?`
      expect(handlers.present?).to eq(message_router.matches_message?(message))
      handlers
    end

    class MyMessage < Sequent::Event; end

    let(:attrs) { {aggregate_id: 'x', sequence_number: 1} }

    context 'given no registered matchers' do
      let(:message) { MyMessage.new(attrs) }

      it 'returns an empty set' do
        expect(subject).to eq(Set.new)
      end
    end

    context 'given a registered IsA' do
      before do
        message_router.register_matchers(
          Sequent::Core::Helpers::MessageMatchers::IsA.new(MyMessage),
          handler,
        )
      end

      context 'and the message matches on class' do
        let(:message) { MyMessage.new(attrs) }

        it 'returns the registered handlers' do
          expect(subject).to eq(Set[handler])
        end

        context 'and the message class is registered multiple times' do
          before do
            message_router.register_matchers(
              Sequent::Core::Helpers::MessageMatchers::IsA.new(MyMessage),
              other_handler,
            )
          end

          context 'and the handlers are different' do
            it 'returns all registered handlers' do
              expect(subject).to eq(Set[handler, other_handler])
            end
          end

          context 'and the handlers are equal' do
            let(:other_handler) { handler }

            it 'returns unique handlers' do
              expect(subject).to eq(Set[handler])
            end
          end
        end
      end

      context 'and the message does not match' do
        class MyOtherMessage < Sequent::Event; end

        let(:message) { MyOtherMessage.new(attrs) }

        it 'returns an empty set' do
          expect(subject).to eq(Set.new)
        end
      end
    end

    context 'given a registered message module' do
      module MyModule; end

      class MyMessageWithModule < Sequent::Event
        include MyModule
      end

      class OtherMessageWithModule < Sequent::Event
        include MyModule
      end

      before do
        message_router.register_matchers(
          Sequent::Core::Helpers::MessageMatchers::IsA.new(MyModule),
          handler,
        )
      end

      context 'and the message matches on module' do
        let(:message) { MyMessageWithModule.new(attrs) }

        it 'returns the registered handlers' do
          expect(subject).to eq(Set[handler])
        end

        context 'and the message module is registered multiple times' do
          before do
            message_router.register_matchers(
              Sequent::Core::Helpers::MessageMatchers::IsA.new(MyModule),
              other_handler,
            )
          end

          context 'and the handlers are different' do
            it 'returns all registered handlers' do
              expect(subject).to eq(Set[handler, other_handler])
            end
          end

          context 'and the handlers are equal' do
            let(:other_handler) { handler }

            it 'returns unique handlers' do
              expect(subject).to eq(Set[handler])
            end
          end
        end

        context 'and a registered message class that includes the module' do
          before do
            message_router.register_matchers(
              Sequent::Core::Helpers::MessageMatchers::IsA.new(MyMessageWithModule),
              other_handler,
            )
          end

          it 'returns all registered handlers' do
            expect(subject).to eq(Set[handler, other_handler])
          end
        end
      end

      context 'and the message does not match' do
        module OtherModule; end

        class MyMessageWithOtherModule < Sequent::Event
          include OtherModule
        end

        let(:message) { MyMessageWithOtherModule.new(attrs) }

        it 'returns an empty set' do
          expect(subject).to eq(Set.new)
        end
      end
    end
  end
end
