module CortexReaver
  class DocumentationController < Ramaze::Controller
    map '/documentation'
    layout '/text_layout'
    engine :Erubis

    def formatting
    end
  end
end
