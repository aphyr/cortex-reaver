module CortexReaver
  class Controller < Ramaze::Controller
    trait :app => :cortex_reaver
    engine :Erubis
    layout :text
    helper :form, :auth, :navigation, :template, :workflow, :error
  end
end

# Require controllers
module CortexReaver
  require File.join(LIB_DIR, 'controller', 'main')
  require File.join(LIB_DIR, 'controller', 'user')
  require File.join(LIB_DIR, 'controller', 'page')
  require File.join(LIB_DIR, 'controller', 'journal')
  require File.join(LIB_DIR, 'controller', 'photograph')
  require File.join(LIB_DIR, 'controller', 'project')
  require File.join(LIB_DIR, 'controller', 'comment')
  require File.join(LIB_DIR, 'controller', 'tag')
  require File.join(LIB_DIR, 'controller', 'documentation')
  require File.join(LIB_DIR, 'controller', 'admin')
end
