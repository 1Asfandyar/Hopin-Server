currencies = [
  { code: "USD", name: "US Dollar",         symbol: "$"   },
  { code: "EUR", name: "Euro",               symbol: "€"   },
  { code: "GBP", name: "British Pound",      symbol: "£"   },
  { code: "JPY", name: "Japanese Yen",       symbol: "¥"   },
  { code: "CAD", name: "Canadian Dollar",    symbol: "CA$" },
  { code: "AUD", name: "Australian Dollar",  symbol: "A$"  },
  { code: "CHF", name: "Swiss Franc",        symbol: "Fr"  },
  { code: "CNY", name: "Chinese Yuan",       symbol: "¥"   },
  { code: "INR", name: "Indian Rupee",       symbol: "₹"   },
  { code: "PKR", name: "Pakistani Rupee",    symbol: "₨"   },
  { code: "AED", name: "UAE Dirham",         symbol: "د.إ" },
  { code: "SAR", name: "Saudi Riyal",        symbol: "﷼"   },
  { code: "BRL", name: "Brazilian Real",     symbol: "R$"  },
  { code: "MXN", name: "Mexican Peso",       symbol: "$"   },
  { code: "SGD", name: "Singapore Dollar",   symbol: "S$"  },
  { code: "HKD", name: "Hong Kong Dollar",   symbol: "HK$" },
  { code: "SEK", name: "Swedish Krona",      symbol: "kr"  },
  { code: "NOK", name: "Norwegian Krone",    symbol: "kr"  },
  { code: "DKK", name: "Danish Krone",       symbol: "kr"  },
  { code: "NZD", name: "New Zealand Dollar", symbol: "NZ$" },
  { code: "ZAR", name: "South African Rand", symbol: "R"   },
  { code: "TRY", name: "Turkish Lira",       symbol: "₺"   },
  { code: "KWD", name: "Kuwaiti Dinar",      symbol: "د.ك" },
  { code: "QAR", name: "Qatari Riyal",       symbol: "ر.ق" }
]

currencies.each do |attrs|
  Currency.find_or_create_by(code: attrs[:code]) do |c|
    c.name   = attrs[:name]
    c.symbol = attrs[:symbol]
  end
end

Rails.logger.info "Seeded #{currencies.size} currencies"
