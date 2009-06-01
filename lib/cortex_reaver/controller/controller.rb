module CortexReaver
  class Controller < Ramaze::Controller
    trait :app => :cortex_reaver
    engine :Erubis
    layout :text
    helper :form, :auth, :navigation, :template, :workflow, :error
  end
end
