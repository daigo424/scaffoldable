require "ransack"
require "kaminari"
require "active_type"

require "scaffoldable/railtie"
require "scaffoldable/engine"

require "scaffoldable/helpers/scaffoldable/batchable_helper"
require "scaffoldable/helpers/scaffoldable/confirmable_helper"
require "scaffoldable/helpers/scaffoldable/form_helper"

require "scaffoldable/classes/proc"

module Scaffoldable
  # refs: https://railsguides.jp/configuring.html
  extend ActiveSupport::Autoload
  extend ActiveSupport::Concern

  included do
    extend Scaffoldable::Base
  end
end
