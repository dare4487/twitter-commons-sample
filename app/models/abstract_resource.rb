
class AbstractResource < ActiveRecord::Base
  self.abstract_class=true

  attr_accessor :current_user

  def self.logit( log_type, msg )
   Rails.logger.send(log_type, "[OXEN] #{Time.now} [#{log_type.to_s}] #{msg}")
  end

  def logit( log_type, msg )
   Rails.logger.send(log_type, "[OXEN] #{Time.now} [#{log_type.to_s}] #{msg}")
  end

  #
  # this generic search needs a bit more work
  # but it is a ok first draft
  #
  def self.search(lot, query, fields="id")
    fields = fields.join(",") if fields.is_a? Array
    population = lot.pluck fields
    elements = query.split(' ')
    constraints = {and: [], or: [], not: []}
    elements.each do |element|
      case element.slice 0
      when '+'; constraints[:and] += population.collect{ |k,v| k if v =~ /#{element[1..-1]}/i }.compact.flatten
      when '-'; constraints[:not] += population.collect{ |k,v| k if v =~ /#{element[1..-1]}/i }.compact.flatten
      when '*'; constraints[:or] += population.collect{ |k,v| k if b=="#{element[1..-1]}" }.compact.flatten
      else;     constraints[:or] += population.collect{ |k,v| k if v =~ /#{element}/i }.compact.flatten
      end
    end
    population = constraints[:or].empty? ? population.collect{|r| r[0]} : constraints[:or]
    population = population & constraints[:and] if constraints[:and].any?
    population -= constraints[:not].uniq if constraints[:not].any?
    population = [] if constraints[:or].empty? and constraints[:and].empty?
    lot.where id: population
  end


    #
    # filter the lot on filter
    #
    # filter => { updated_at: [ '<', '11-11-2011'], material: { eq: 'alu%'}}
    #
    def self.filter(lot, filter, options={})
      filter.clone.each do |fld,v|
        if v.is_a? Array
          k = v.shift
          lot = filter_proc lot, fld, k, v
        elsif v.is_a? Hash
          v.each do |k,val|
            lot = filter_proc lot, fld, k, val
          end
        elsif v.is_a? String
          lot = lot.where( "? = ?", fld, v )
        else
          raise "filter valueset '#{v}' not recognised?!"
        end
      end
      lot
    end

    def self.filter_proc lot, fld, k, v
      tbl = self.arel_table
      case k.to_sym
      when :lt, :lteq, :eq, :gteq, :gt, :matches
        raise "Exactly one value allowed in filter [lt|eq|gt][|eq]!" if [v].flatten.size > 1
        lot = lot.where tbl[fld].send k.to_sym, [v].flatten.shift
      when :not_eq_any, :not_eq_all, :eq_any, :eq_all, :gteq_any, :gteq_all, :gt_any, :gt_all, :lt_any, :lt_all, :lteq_any, :lteq_all
        raise "At least one value required in filter [|not][lt|eq|gt][_any|_all]!" if [v].flatten.size < 1
        lot = lot.where tbl[fld].send k, [v].flatten
      when :between, :not_between
        raise "Exactly two values allowed in filter [not_]between!" if [v].flatten.size != 2
        lot = lot.where tbl[fld].send k, [v].flatten
      when :in, :in_any, :in_all, :not_in, :not_in_any, :not_in_all
        lot = lot.where tbl[fld].send k, [v].flatten
      when :matches_any, :matches_all, :does_not_match, :does_not_match_any, :does_not_match_all
        lot = lot.where tbl[fld].send k, [v].flatten
      when :matches_regexp, :does_not_match_regexp
        raise "filter [does_not_]match[es]_regexp is not supported"
      when :when, :concat
        raise "filter [when|concat] is not supported"
      else
        raise "filter key '#{k}' not recognised?!"
      end
      lot
    end

  # depreciated ------------ 12/3/2016
  #
  # ancestry related methods - find them on AncestryAbstractResource
  # def self.arrange_array(options={}, hash=nil)
  #   hash ||= arrange(options)
  #
  #   arr = []
  #   hash.each do |node, children|
  #     arr << node
  #     arr += arrange_array(options, children) unless children.nil?
  #   end
  #   arr
  # end
  #
  # def possible_parents
  #  prtns = self.arrange_array(:order => 'name')
  #  return new_record? ? prtns : prtns - subtree
  # end

  def resource_name
   self.class.to_s.underscore.pluralize
  end

  #
  # include Exceptions
  include PrintEngine unless Rails.env=='test'
  #

  # # add the child to an association of children
  # !! remember to implement before_save action on *able tables to meet further foreign_key conditions like account_id, etc
  def attach parent

    # the ordinary *able table
    parent.send( self.class.to_s.underscore.pluralize) << self

    # case child.class.to_s
    # when "Event","WageEvent"
    #   Eventable.create( event: child, eventable: self) unless child.eventables.include?( self)
    # when "Printer"
    #   Printable.create( printer: child, printable: self) unless child.printables.include?( self)
    # else
    #   children = eval child.class.to_s.underscore.pluralize
    #   children << child
    # end
  rescue
    false
  end
  #
  # # remove the child from an association of children
  def detach parent

    # the ordinary *able table
    parent.send( self.class.to_s.underscore.pluralize).delete self

    # case child.class.to_s
    # when "Event","WageEvent"
    #   ev = Eventable.where( event: child, eventable: self)
    #   ev.delete_all
    # when "Printer"
    #   pr = Printable.where( printer: child, printable: self)
    #   pr.delete_all
    # else
    #   children = eval child.class.to_s.downcase.pluralize
    #   children.delete child
    # end
  rescue
    false
  end

  def activate
    update_attributes active: true
  end

  def deactivate
    update_attributes active: false
  end


end
