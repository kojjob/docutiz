# frozen_string_literal: true

# Pagy initializer file (8.0.2)
# Customize only what you really need and notice that the core Pagy works also without any of the following lines.

# Instance variables
# See https://ddnexus.github.io/pagy/docs/api/pagy#instance-variables
# Pagy::DEFAULT[:limit] = 20    # default items per page
# Pagy::DEFAULT[:size]  = 7       # default nav bar size
# Pagy::DEFAULT[:outset] = 0     # default initial offset

# Other variables
# See https://ddnexus.github.io/pagy/docs/api/pagy#other-variables
# Pagy::DEFAULT[:page_param] = :page
# Pagy::DEFAULT[:count_args] = [] # extra count method arguments
# Pagy::DEFAULT[:request_path] = "/foo"   # request_path if it's not inferred

# Extras
# See https://ddnexus.github.io/pagy/docs/extras

# Tailwind extra: Add nav helper for Tailwind pagination
require 'pagy/extras/bootstrap'

# Items extra: Allow the client to request a custom number of items per page
# See https://ddnexus.github.io/pagy/docs/extras/items
# require 'pagy/extras/items'
# Pagy::DEFAULT[:max_items] = 100   # default max number of items per page

# Overflow extra: Allow pagination for empty results
# See https://ddnexus.github.io/pagy/docs/extras/overflow
require 'pagy/extras/overflow'
Pagy::DEFAULT[:overflow] = :last_page

# Support extra: Extra support for features like: incremental, auto-incremental, ...
# See https://ddnexus.github.io/pagy/docs/extras/support
# require 'pagy/extras/support'

# Trim extra: Remove the page=1 param from links
# See https://ddnexus.github.io/pagy/docs/extras/trim
require 'pagy/extras/trim'

# Countless extra: Count-less pagination
# See https://ddnexus.github.io/pagy/docs/extras/countless
# require 'pagy/extras/countless'
# Pagy::DEFAULT[:countless_minimal] = false

# Rails
# See https://ddnexus.github.io/pagy/docs/extras/rails
# Rails: enable the increment helpers by default
# See https://ddnexus.github.io/pagy/docs/extras/support
# require 'pagy/extras/support'

# I18n
# See https://ddnexus.github.io/pagy/docs/api/i18n
# Notice: No need to use any pagy*_locale_files, the available locales are already set

# When you are done setting your own custom i18n keys, you may uncomment the following line
# Pagy::I18n.load(locale: 'en', filepath: 'path/to/dictionary.yml')