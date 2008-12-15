module CortexReaver
  class ConfigController < Ramaze::Controller
    map '/config'
    layout '/text_layout'
    template :edit, :form
    engine :Erubis

    helper :error,
      :auth,
      :form,
      :workflow

  end
end
