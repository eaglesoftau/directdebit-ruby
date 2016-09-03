module DirectDebit
  module Ezidebit
    class Payment  < EzidebitObject

      #TODO: Use Base API URL and add action to it
      ADD_PAYMENT_ACTION = 'https://px.ezidebit.com.au/INonPCIService/AddPayment'
      PAYMENT_DETAIL_ACTION = 'https://px.ezidebit.com.au/INonPCIService/GetPaymentDetail'
      GET_PAYMENTS_ACTION = 'https://px.ezidebit.com.au/INonPCIService/GetPayments'
      GET_SCHEDULED_PAYMENTS_ACTION = 'https://px.ezidebit.com.au/INonPCIService/GetScheduledPayments'
      CLEAR_SCHEDULE_ACTION = 'https://px.ezidebit.com.au/INonPCIService/ClearSchedule'

      #This method is used to add a single payment to a customer's account
      def add_payment(options={})
        create_request("nonpci", ADD_PAYMENT_ACTION) do |xml|
          xml['px'].AddPayment do
            xml['px'].DigitalKey DirectDebit::Ezidebit::api_digital_key
            options.each { |key,value| xml['px'].send(key, value)}
          end
        end
        response = request_it!
        parse(response, "add_payment_response")
      end

      #This method will get payment details
      def get_payment_detail(payment_reference = "")
        create_request("nonpci", PAYMENT_DETAIL_ACTION) do |xml|
          xml['px'].GetPaymentDetail do
            xml['px'].DigitalKey DirectDebit::Ezidebit::api_digital_key
            xml['px'].PaymentReference payment_reference
          end
        end
        response = request_it!
        parse(response, "get_payment_detail")
      end

      def get_payments(date_from = "", date_to = "", date_field = "SETTLEMENT",
          payment_type = "ALL", payment_method = "DR", payment_source = "SCHEDULED" )
          create_request("nonpci", GET_PAYMENTS_ACTION) do |xml|
            xml['px'].GetPayments do
              xml['px'].DigitalKey DirectDebit::Ezidebit::api_digital_key
              xml['px'].PaymentType payment_type
              xml['px'].PaymentMethod payment_method
              xml['px'].PaymentSource payment_source
              xml['px'].DateFrom date_from
              xml['px'].DateTo date_to
              xml['px'].DateField date_field
              #xml['px'].EziDebitCustomerID ""
              #xml['px'].YourSystemReference ""
              #xml['px'].YourSystemReference ""
          end
        end
        response = request_it!
        parse(response, "get_payments")
      end

      def get_scheduled_payments(date_from = "", date_to = "", ezi_debit_customer_id = "", your_system_reference = "")
          create_request("nonpci", GET_SCHEDULED_PAYMENTS_ACTION) do |xml|
            xml['px'].GetScheduledPayments do
              xml['px'].DigitalKey DirectDebit::Ezidebit::api_digital_key
              xml['px'].DateFrom date_from
              xml['px'].DateTo date_to
              xml['px'].EziDebitCustomerID ezi_debit_customer_id
              xml['px'].YourSystemReference your_system_reference
          end
        end
        response = request_it!
        parse(response, "get_scheduled_payments")
      end


      def clear_schedule(ezi_debit_customer_id, keep_manual_payments="NO")
          create_request("nonpci", CLEAR_SCHEDULE_ACTION) do |xml|
            xml['px'].ClearSchedule do
              xml['px'].DigitalKey DirectDebit::Ezidebit::api_digital_key
              xml['px'].EziDebitCustomerID ezi_debit_customer_id
              xml['px'].KeepManualPayments keep_manual_payments
          end
        end
        response = request_it!
        parse(response, "clear_schedule")
      end



      def parse(response, type, generic_tag = nil)
        if response
          xml = Nokogiri::XML(response.body)
          if(generic_tag == nil)
            return self.send("parse_#{type}", xml)
          else
            return self.send("parse_#{type}", xml, generic_tag)
          end
        else
         return false
        end
      end


      def parse_add_payment_response(xml)
        data   = {}
         data[:Status] = xml.xpath("//ns:AddPaymentResponse/ns:AddPaymentResult/ns:Data",
          {ns: 'https://px.ezidebit.com.au/'} ).text
        data[:Error] = xml.xpath("//ns:AddPaymentResponse/ns:AddPaymentResult/ns:Error",
          {ns: 'https://px.ezidebit.com.au/'} ).text
        data[:ErrorMessage] = xml.xpath("//ns:AddPaymentResponse/ns:AddPaymentResult/ns:ErrorMessage",
          {ns: 'https://px.ezidebit.com.au/'} ).text
        data
      end

      def parse_clear_schedule(xml)
        data   = {}
         data[:Status] = xml.xpath("//ns:ClearScheduleResponse/ns:ClearScheduleResult/ns:Data",
          {ns: 'https://px.ezidebit.com.au/'} ).text
        data[:Error] = xml.xpath("//ns:ClearScheduleResponse/ns:ClearScheduleResult/ns:Error",
          {ns: 'https://px.ezidebit.com.au/'} ).text
        data[:ErrorMessage] = xml.xpath("//ns:ClearScheduleResponse/ns:ClearScheduleResult/ns:ErrorMessage",
          {ns: 'https://px.ezidebit.com.au/'} ).text
        data
      end

      def parse_get_payment_detail(xml)
        data   = {}
        fieldnames = ['BankFailedReason', 'BankReturnCode', 'DebitDate', 'InvoiceID', 'PaymentAmount', 'PaymentI',
          'PaymentMethod', 'PaymentReference', 'PaymentStatus', 'SettlementDate', 'ScheduledAmount', 'TransactionFeeClient', 'TransactionFeeCustomer',
          'TransactionFeeCustomer', 'YourSystemReference']
        fieldnames.each do | fieldname|
          data[fieldname] = xml.xpath("//xmlns:GetPaymentDetailsResponse/xmlns:GetPaymentDetailsResult/xmlns:Data/xmlns:#{fieldname}",  {xmlns: 'https://px.ezidebit.com.au/'} ).text
        end
        data
      end

       def parse_get_scheduled_payments(xml)
          payments = []
          fieldnames = ['EziDebitCustomerID', 'YourSystemReference', 'YourGeneralReference', 'PaymentDate', 'PaymentAmount', 'PaymentReference',
            'ManuallyAddedPayment']
          payments_nodeset = xml.xpath("//xmlns:GetScheduledPaymentsResponse/xmlns:GetScheduledPaymentsResult/xmlns:Data/xmlns:ScheduledPayment",
            {xmlns: 'https://px.ezidebit.com.au/'} ).map { |node| node}
          DirectDebit.logger.debug  "Payment nodeset count: #{payments_nodeset.count}"
          payments_nodeset.each do |payment_node|
            data = Hash.new
            fieldnames.each do | fieldname|
              data[fieldname] = payment_node.xpath("ns:#{fieldname}",
                {ns: 'https://px.ezidebit.com.au/'} ).text
            end
            payments << data
          end
          payments
      end

      def parse_get_payments(xml)
        payments = []
        fieldnames = ['BankFailedReason', 'BankReceiptID', 'BankReturnCode', 'CustomerName', 'DebitDate', 'EziDebitCustomerID',
          'InvoiceID', 'PaymentAmount', 'PaymentID', 'PaymentMethod', 'PaymentReference', 'PaymentSource', 'PaymentStatus', 'SettlementDate',
          'ScheduledAmount', 'TransactionFeeClient', 'TransactionFeeCustomer', 'TransactionTime', 'YourGeneralReference', 'YourSystemReference']
        payments_nodeset = xml.xpath("//xmlns:GetPaymentsResponse/xmlns:GetPaymentsResult/xmlns:Data/xmlns:Payment",
          {xmlns: 'https://px.ezidebit.com.au/'} ).map { |node| node}
        payments_nodeset.each do |payment_node|
          data = Hash.new
          fieldnames.each do | fieldname|
            data[fieldname] = payment_node.xpath("ns:#{fieldname}",
              {ns: 'https://px.ezidebit.com.au/'} ).text
          end
          payments << data
        end
        payments
      end

    end
  end
end
