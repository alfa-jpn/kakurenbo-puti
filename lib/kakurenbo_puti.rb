require 'active_record'
require 'kakurenbo_puti/version'
require 'kakurenbo_puti/active_record_base'

ActiveRecord::Base.send :extend, KakurenboPuti::ActiveRecordBase
