module Readyset
  module ModelExtension
    extend ActiveSupport::Concern

    prepended do
      require 'active_support'

      # Defines a new class method on a model that wraps the ActiveRecord query in `body` in a call
      # to `Readyset.route`.
      #
      # NOTE: `body` should consist of nothing other than an ActiveRecord query! If you need to run
      # actions before or after the query execution, you should wrap the invocation of the named
      # query in another method.
      #
      # @param [Symbol] name the name of the method that will be defined
      # @param [Proc] body a lambda that wraps an ActiveRecord query
      def self.readyset_query(name, body)
        unless body.respond_to?(:call)
          raise ArgumentError, 'The query body needs to be callable.'
        end

        if dangerous_class_method?(name)
          raise ArgumentError, "You tried to define a ReadySet query named \"#{name}\" " \
            "on the model \"#{self.name}\", but Active Record already defined " \
            'a class method with the same name.'
        end

        if method_defined_within?(name, ActiveRecord::Relation)
          raise ArgumentError, "You tried to define a ReadySet query named \"#{name}\" " \
            "on the model \"#{self.name}\", but ActiveRecord::Relation already defined " \
            'an instance method with the same name.'
        end

        singleton_class.define_method(name) do |*args|
          Readyset.route { body.call(*args) }
        end
      end
    end
  end
end
