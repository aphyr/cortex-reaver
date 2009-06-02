module Sequel
  class Model
    plugin :validation_helpers
    plugin :cortex_reaver_validation_helpers
  end
end

# Require models
Ramaze::acquire File.join(CortexReaver::LIB_DIR, 'model', '*')
