module CortexReaver
  class ConfigController < Ramaze::Controller
    map '/config'
    layout(:text_layout)

    alias_view :edit, :form
    engine :Erubis

    helper :error,
      :auth,
      :form,
      :workflow

  end
end
