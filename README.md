# Kakurenbo\-Puti
kakurenbo-puti provides an ActiveRecord-friendly soft-delete gem.
This gem does not override methods of ActiveRecord.

I think that kakurenbo-puti is cho-iketeru! (very cool!)

[![Build Status](https://travis-ci.org/alfa-jpn/kakurenbo-puti.svg?branch=master)](https://travis-ci.org/alfa-jpn/kakurenbo-puti)
[![Coverage Status](https://coveralls.io/repos/alfa-jpn/kakurenbo-puti/badge.svg)](https://coveralls.io/r/alfa-jpn/kakurenbo-puti)
[![Code Climate](https://codeclimate.com/github/alfa-jpn/kakurenbo-puti/badges/gpa.svg)](https://codeclimate.com/github/alfa-jpn/kakurenbo-puti)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'kakurenbo-puti'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install kakurenbo-puti

## Usage
At first, add `soft_destroyed_at` column to your model.

```shell
$ rails g migration AddSoftDestroyedAtToYourModel soft_destroyed_at:datetime:index
$ rake db:migrate
```

Next, call `soft_deletable` in model.

```ruby

class Member < ActiveRecord::Base
  soft_deletable
end

```


### Scopes

```ruby
# Get models without soft-deleted
Model.without_soft_destroyed

# Get models only soft-deleted
Model.only_soft_destroyed
```

### Soft-delete record

```ruby
model.soft_destroy

# or
model.soft_destroy!

# check soft_destroyed
model.soft_destroyed? # => true
```

### Restore record

```ruby
model.restore

# or
model.restore!
```

## Advanced

### Definition of the dependency
Use dependent_associations option of `soft-deletable`.
This option is useable only in `belongs_to`.

```ruby

class Parent < ActiveRecord::Base
  soft_deletable
  has_many :children
end

class Child < ActiveRecord::Base
  soft_deletable dependent_associations: [:parent]
  belongs_to :parent
end

# create instance
parent = Parent.create!
child  = Child.create!

# add child
parent.children << child

child.destroyed? # false

# soft-destroy parent
parent.soft_destroy

child.destroyed? # true

```

### Change column of datetime of soft-delete.

```ruby

class Member < ActiveRecord::Base
  soft_deletable :column => :deleted_at
end

```

# License
This gem is released under the MIT license.
