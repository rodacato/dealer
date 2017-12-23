module BitsDealer
  class Helper
    attr_reader :prompt, :formatter

    def initialize(prompt:, formatter:)
      @prompt = prompt
      @formatter = formatter
    end

    def ask_book
      book_options = BitsDealer::Books::DEFAULT_BOOKS

      book = prompt.select("Choose the book?") do |menu|
        menu.enum '.'

        book_options.each_pair do |key, value|
          menu.choice key, value
        end
      end
    end

    def print_tickers_table(tickers)
      tickers_formatted = tickers.sort{|a, b| a[:book] <=> b[:book] }.each_with_object({}){ |element, hsh| hsh[element[:book]] = element; hsh }

      table = Terminal::Table.new(
        :headings => [:book, :last, :last_mxn, :bid, :ask, 'high/low'],
        :rows => tickers.map do |ticker|
          if ['xrp_btc', 'eth_btc'].include? ticker[:book]
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
  end
end