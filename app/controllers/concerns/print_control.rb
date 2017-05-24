require 'active_support/concern'
#
#
# ARGS                            # <a href="..?print[collation]=xx&print[paper]=yy.."
#                                 # first value is default
#
#   collation                     # 'list' | 'record'
#   paper                         # 'A4' | 'label' | ...
#   template                      # '' | 'slip' | 'quote'
#   cmd                           # '' | 'print_label' - a particular method on the printing_class
#
# PRINTPROMPT
#   print[medium]                 # 'display' | 'email' | 'printer' | 'download'
#   print[output_type]            # 'html' | 'pdf' | 'text'
#   print[printer]                # what printer to send output to
#   print[email_to]               # email address
#   print[message]                # body of email
#   print[range]                  # which pages should print
#   print[copies]                 # number of copies
#
# PRINTJOB
#   id,
#   account_id,                   # what 'system' / customer
#   printer_id,                   # on what printer
#   printed_by_id,                # what id has the printed_by entity
#   printed_by_type,              # what entity - like user
#   view_template_path,           # what template
#   name,                         # label the job
#   printing_class,               # what entity provides the data
#   print_driver,                 # what 'driver' - like :pdf, :cab, :zebra, :csv, :html, etc
#   print_format,                 # data collation - like 'record', 'list'
#   state,                        # record the progress
#   paper,                        # what material - like 'label32x42', 'A4', etc
#   copies,                       # number of identical prints
#   print_sql,                    # how to find what will be printed
#   created_at,
#   updated_at
#
# TEMPLATE
#   id
#   account_id,                   # what 'system' / customer
#   template_key,                 # a key to search the template by - provided by ARGS[template]
#   template_path,                # where the template is stored - like stock_items/print/zebra.html.haml
#   template_content,             # or what the template contains - all HTML, CSS etc.
#   template_print_driver         # identification of a particular driver -if necessary - like the :zebra
#   template_paper                # identification of a particular paper -if necessary - like the :label10x32
#   created_at
#   updated_at

#
#   PrintControl#print ->
#   resource_class#print_list | resource#print | resource#send params[:print][:cmd] -> (PrintEngine)
#   PrintJob#create ->
#   BackgroundPrinterJob#perform_later pj ->
#   PrintDrivers#print_with PrintDrivers#rendered_on | PrintDrivers#send_with PrintDrivers#rendered_on ->
#   [Pdf|Html|Cab|Csv|Label]Printer#do_render -> ActionPrinter#do_render
#   [Pdf|Html|Cab|Csv|Label]Printer#do_print ->



module PrintControl
  extend ActiveSupport::Concern

  included do

    PRINTSUCCESS = 1
    NOQUEUE = -1
    NOUSER = -2
    PRINTRECERROR = -3
    PRINTCMDERROR = -4
    PRINTLISTERROR = -5
    PRINTEXCEPTION = -99

  end
  #
  # print this view - let the Class handle everything
  # returning either the ID to a print_job or false (in which case something went terribly wrong)
  #
  # always an Ajax call - hence will always update the print_jobs link with 'yellow'-blink
  # POST /printers/print.js
  # params[:id] holds records to be printed
  #
  # from the print-dialog:
  #
  # from a link tag
  def print
    authorize resource, :print?
    if resources.any?
      params[:context]                    = self
      params[:printed_by]                 = current_user || User.first
      params[:print]                      ||= {}
      params[:print][:collation]          ||= 'list'
      params[:print_job]                  ||= {}
      # params[:print_job][:view_template]  ||= current_user.account.find_print_template(params[:print][:template]) || Template.new( template_path: 'list.html.haml')
      # params[:print_job][:print_driver]   = params[:print][:print_driver] || params[:print_job][:view_template].template_print_driver
      # params[:print_job][:paper]          = params[:print_job][:view_template].template_paper || params[:print][:paper] || "A4"
      params[:print_job][:paper]          = params[:print][:paper] || "A4"
      #
      # ok so we have items to print!
      status = case params[:print][:medium]
      when "display"  ; display_print_result and return
      when "email"    ; email_print_result
      when "printer"  ; print_print_result
      when "download" ; download_print_result and return
      else
        flash[:error] = t('output.medium.no_medium_found');
        301
      end
    end
    render :print, layout: false, status: status and return

  # rescue Exception => e
  #   scoop_from_error e
  end

  #
  # send HTML or PDF down the wire
  #
  def display_print_result
    params[:print][:output_type] ||= 'html'
    case params[:print][:output_type].downcase
      # when 'html'; render params[:print][:view_template_path], layout: 'print'
    when 'html';  render "stock_items/print/_stock_items_list", layout: 'print'
    when 'pdf';   download_print_result
    end
  end

  #
  # send PDF down the wire
  #
  def download_print_result
    params[:print][:output_type] ||= 'pdf'
    params[:print][:medium]="download"
    print_resources
  end

  #
  # send PDF via email
  #
  def email_print_result
    params[:print][:output_type] ||= 'pdf'
    if params[:print][:email_to].blank?
      flash[:error] = t('output.email.email_address_missing')
      return 301
    else
      print_resources
      flash[:info] = t('output.email.email_sent')
      return 200
    end
  end

  def print_print_result
    params[:print][:output_type] ||= 'pdf'
    if (result = print_resources) > 0
      flash[:info] = t(:resources_printed_correct)
      status = 200
    else
      case result
      when NOQUEUE; flash[:error] = t(:noqueue_created)
      when NOUSER; flash[:error] = t(:no_user_present)
      when PRINTRECERROR; flash[:error] = t(:printing_record_error)
      when PRINTCMDERROR; flash[:error] = t(:print_command_error)
      when PRINTLISTERROR; flash[:error] = t(:printing_list_error)
      when PRINTEXCEPTION ; flash[:error] = t(:exception_in_print_engine)
      end
      status = 301
    end
    status
  end


  #
  # print_resources will try to add a print_job
  # return error code
  def print_resources
    if resource_class == PrintJob
      resources.each do |res|
        return NOQUEUE unless Delayed::Job.enqueue res, :queue => 'printing'
      end
      return PRINTSUCCESS
    else
      return NOUSER if params[:printed_by].nil?
      case params[:print][:collation]
        when 'record'
          if params[:print][:cmd].blank?
            resources.each do |res|
              return PRINTRECERROR unless res.print_record params
            end
          else
            resources.each do |res|
              return PRINTCMDERROR unless res.send(params[:print][:cmd],params)
            end
          end

        when 'list'
          params[:resources] = resources
          return PRINTLISTERROR unless resource_class.print_list( params )

      end
    end

    return PRINTSUCCESS

  end

end
