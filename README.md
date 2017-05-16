#ACH-Builder

[![Build Status](https://secure.travis-ci.org/TMXCredit/ach_builder.png)](http://travis-ci.org/TMXCredit/ach_builder)

Ruby helper for creating ACH files. Its API is designed to be as flexible as possible.

Inspired by:
* [ach](http://github.com/jm81/ach) - Ruby helper
* [ACH::Builder](http://github.com/camerb/ACH-Builder) - Perl module

##Example

```ruby
    # attributes for records may be passed as parameters, as well as modified in block
    # these attributes will be passed to all inner entities in a cascade way, if required
    file = ACH::File.new(:company_id => '11-11111', :company_name => 'MY COMPANY') do
      immediate_dest_name 'COMMERCE BANK'
      immediate_origin '123123123'
      immediate_origin_name 'MYCOMPANY'

      ['WEB', 'TEL'].each do |code|
        batch(:entry_class_code => code, :company_entry_descr => 'TV-TELCOM') do
          effective_date Time.now.strftime('%y%m%d')
          origin_dfi_id "00000000"

          entry :customer_name => 'JOHN SMITH',
            :customer_acct     => '61242882282',
            :amount            => '2501',
            :routing_number    => '010010101',
            :bank_account      => '103030030'
          addenda do
            addenda_type_code          '05'
            payment_related_info       'foo bar'
            addenda_sequence_num       1
            entry_details_sequence_num 1
          end
        end
      end
    end

    file.valid? # => false
    file.errors # => {"ACH::File::Header#1"=>{:immediate_dest=>"is required"}}
    file.header.immediate_dest = '123123123'
    file.write('ach_01.txt')
```

##Copyright

Copyright (c) 2013 TMX Credit, released under the MIT license
