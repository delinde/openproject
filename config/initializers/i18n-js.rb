#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

# Note: This monkey patch was written to enable configurations like:
#
#   only:
#   -   '*.js'
#   -   '*.*.js'
#   -   '*.*.*.js'
#
# in combination with unevenly nested translations, i.e.
#   en:
#     foo: Foo
#     js:
#       foo: Foo
#         bar:
#           baz: Baz
#
# NB: On some levels, there are String _and_ Hash values.
#
# The original code only expected to see Hashes, while in the above setup, there
# might be other values as well. These may be ignored by `filter`, since these
# values will not contain the relevant translations.
#
# At the moment, we are not posting a pull request including the changes to the
# original author, since s/he is working on a rewrite of i18n-js and s/he does
# not seem to accept even the simplest pull request. We should try again, when
# the `rewrite` branch of i18n-js is released to master.
#
# Written against i18n-js rewrite branch
I18n::JS.module_eval do
  class << self
    def filter_with_uneven_nesting_fix(translations, scopes)
      filter_without_uneven_nesting_fix(translations, scopes) if translations.is_a? Hash
    end
    alias_method_chain :filter, :uneven_nesting_fix
  end
end

# Exporting I18n files at server startup time
I18n::JS.export
