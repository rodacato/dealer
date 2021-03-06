module BitsDealer
  class Helper
    attr_reader :prompt, :formatter

    def initialize(prompt:, formatter:)
      @prompt = prompt
      @formatter = formatter
    end

    def ask_book(books: nil)
      book_options = books || BitsDealer::Books::PLACE_ORDER_BOOKS

      book = prompt.select("Choose the book?") do |menu|
        menu.enum '.'

        book_options.each do |book|
          menu.choice book.name, book
        end
      end
    end

    def ask_order(orders:)
      book = prompt.select("Choose the order?") do |menu|
        menu.enum '.'

        orders.each do |order|
          side_formatted = order[:side] == 'buy' ? formatter.green(order[:side]) : formatter.red(order[:side])
          help_text = formatter.magenta("(#{order[:original_value]})")
          menu.choice "#{side_formatted} #{order[:original_amount]} at #{order[:price]} #{help_text}", order
        end
      end
    end

    def print_tickers_table(tickers:)
      tickers_formatted = tickers.sort{|a, b| a[:book] <=> b[:book] }.each_with_object({}){ |element, hsh| hsh[element[:book]] = element; hsh }

      table = Terminal::Table.new(
        :headings => [:book, :last, :last_mxn, :bid, :ask, 'high/low'],
        :rows => tickers.map do |ticker|
          if ['xrp_btc', 'eth_btc'].include?(ticker[:book]) && tickers_formatted['btc_mxn']
            last_mxn = ticker[:last] * tickers_formatted['btc_mxn'][:last]
          end

          if ticker[:book] == 'xrp_btc'
            next [ticker[:book], '%.8f' % ticker[:last], last_mxn, formatter.green('%.8f' % ticker[:bid]), formatter.red('%.8f' % ticker[:ask]), "#{'%.8f' % ticker[:high]} / #{'%.8f' % ticker[:low]}"]
          end

          [ticker[:book], ticker[:last], last_mxn, formatter.green(ticker[:bid]), formatter.red(ticker[:ask]), "#{ticker[:high]} / #{ticker[:low]}"]
        end
      )

      prompt.say table
    end

    def print_account_balance(balance:, filter: nil)
      balances = balance[:balances].map{|currency| currency.values }
      balances = balances.select{|balance| filter.include?(balance.first) } if filter

      table = Terminal::Table.new(
        :headings => [:currency, :available, :locked, :total, :pending_deposit, :pending_withdrawal],
        :rows => balances
      )

      prompt.say table
    end

    def place_order(book, side, minor, price)
      major = (minor/price).round(6)

      with_retries(:max_tries => 3) {
        Bitsor.place_order(book: book.id, side: side, type: :limit, major: major.to_s, price: price.to_s)
      }
    end

    def exchange_order(book, minor, price)
      with_retries(:max_tries => 3) {
        Bitsor.place_order(book: book.id, side: :sell, type: :limit, major: minor.to_s, price: price.to_s)
      }
    end
  end
end
