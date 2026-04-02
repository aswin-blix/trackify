enum TipCategory { dailyHabits, bigPurchases, savings, investments, mindset }

class FinanceTip {
  final String id;
  final String text;
  final TipCategory category;
  final String emoji;

  const FinanceTip({
    required this.id,
    required this.text,
    required this.category,
    required this.emoji,
  });
}

const List<FinanceTip> allTips = [
  // ── Daily Habits ──────────────────────────────────────────────────────────
  FinanceTip(
    id: '1',
    text:
        'Track every rupee for 30 days — awareness alone reduces spending by 20%.',
    category: TipCategory.dailyHabits,
    emoji: '📊',
  ),
  FinanceTip(
    id: '2',
    text: 'Use the 24-hour rule before any non-essential purchase above ₹500.',
    category: TipCategory.dailyHabits,
    emoji: '⏰',
  ),
  FinanceTip(
    id: '3',
    text:
        'Cook at home 5 days a week — saves ₹3,000–₹8,000/month for most people.',
    category: TipCategory.dailyHabits,
    emoji: '🍳',
  ),
  FinanceTip(
    id: '4',
    text:
        'Cancel subscriptions you haven\'t used in 30 days. Review every 3 months.',
    category: TipCategory.dailyHabits,
    emoji: '📱',
  ),
  FinanceTip(
    id: '5',
    text: 'Never grocery shop hungry — impulse buys add 25–40% to your cart.',
    category: TipCategory.dailyHabits,
    emoji: '🛒',
  ),
  FinanceTip(
    id: '6',
    text: 'Make coffee at home 4 days a week — saves ₹1,500–₹3,000/month.',
    category: TipCategory.dailyHabits,
    emoji: '☕',
  ),
  FinanceTip(
    id: '7',
    text:
        'Use UPI for all purchases to maintain a digital trail — hidden spending becomes visible.',
    category: TipCategory.dailyHabits,
    emoji: '💳',
  ),
  FinanceTip(
    id: '8',
    text:
        'Do a weekly 10-minute money review — catch subscriptions, fees, and leaks early.',
    category: TipCategory.dailyHabits,
    emoji: '🔍',
  ),
  FinanceTip(
    id: '9',
    text: 'Unsubscribe from marketing emails — out of sight, out of cart.',
    category: TipCategory.dailyHabits,
    emoji: '📧',
  ),
  FinanceTip(
    id: '10',
    text:
        'Pack lunch 3x/week — even ₹100/day saved is ₹1,200/month in your pocket.',
    category: TipCategory.dailyHabits,
    emoji: '🍱',
  ),

  // ── Big Purchases ─────────────────────────────────────────────────────────
  FinanceTip(
    id: '11',
    text:
        'Before any big purchase, ask: "Will I still want this in 90 days?" Most answers are no.',
    category: TipCategory.bigPurchases,
    emoji: '🤔',
  ),
  FinanceTip(
    id: '12',
    text:
        'Buy electronics 2–3 generations behind the latest — 60–70% cheaper, 90% of the function.',
    category: TipCategory.bigPurchases,
    emoji: '📱',
  ),
  FinanceTip(
    id: '13',
    text:
        'Never buy a car with more than 15% of your annual income — depreciation is brutal.',
    category: TipCategory.bigPurchases,
    emoji: '🚗',
  ),
  FinanceTip(
    id: '14',
    text:
        'Use price-tracking apps (Keepa, PriceHistory) before any online purchase above ₹1,000.',
    category: TipCategory.bigPurchases,
    emoji: '📉',
  ),
  FinanceTip(
    id: '15',
    text:
        'Buy refurbished for appliances and electronics — often 30–50% off with full warranty.',
    category: TipCategory.bigPurchases,
    emoji: '🔄',
  ),
  FinanceTip(
    id: '16',
    text:
        'Negotiate everything — services, rent, insurance, internet. Asking costs nothing.',
    category: TipCategory.bigPurchases,
    emoji: '🤝',
  ),
  FinanceTip(
    id: '17',
    text:
        'Avoid zero-cost EMI traps — they often inflate product price by 8–15% upfront.',
    category: TipCategory.bigPurchases,
    emoji: '⚠️',
  ),
  FinanceTip(
    id: '18',
    text:
        'Compare cost-per-use, not cost. A ₹3,000 item used once costs more than ₹15,000 used daily.',
    category: TipCategory.bigPurchases,
    emoji: '💡',
  ),

  // ── Savings ───────────────────────────────────────────────────────────────
  FinanceTip(
    id: '19',
    text:
        'Pay yourself first — automate 20% savings before spending anything else.',
    category: TipCategory.savings,
    emoji: '💰',
  ),
  FinanceTip(
    id: '20',
    text:
        'Build a 3–6 month emergency fund before any investment. Security is the foundation.',
    category: TipCategory.savings,
    emoji: '🛡️',
  ),
  FinanceTip(
    id: '21',
    text:
        'The 50-30-20 rule: 50% needs, 30% wants, 20% savings/debt. Adjust to your reality.',
    category: TipCategory.savings,
    emoji: '📏',
  ),
  FinanceTip(
    id: '22',
    text:
        'Every raise is a chance to increase savings rate, not lifestyle. Try saving 50% of every increment.',
    category: TipCategory.savings,
    emoji: '📈',
  ),
  FinanceTip(
    id: '23',
    text:
        'Automate savings on salary day — willpower is a finite resource, systems aren\'t.',
    category: TipCategory.savings,
    emoji: '🤖',
  ),
  FinanceTip(
    id: '24',
    text:
        'Keep savings in a separate account with no debit card — friction reduces impulse withdrawals.',
    category: TipCategory.savings,
    emoji: '🔒',
  ),
  FinanceTip(
    id: '25',
    text: 'A savings rate of 10% is survival. 20% is comfort. 40%+ is freedom.',
    category: TipCategory.savings,
    emoji: '🎯',
  ),
  FinanceTip(
    id: '26',
    text:
        'Round up every transaction to the nearest ₹100 in your mental accounting — the buffer adds up.',
    category: TipCategory.savings,
    emoji: '⬆️',
  ),

  // ── Investments ───────────────────────────────────────────────────────────
  FinanceTip(
    id: '27',
    text:
        'Time in the market beats timing the market — 95% of investors who try to time it lose.',
    category: TipCategory.investments,
    emoji: '⏳',
  ),
  FinanceTip(
    id: '28',
    text:
        'Start a SIP of even ₹500/month — compounding over 20 years is more powerful than any "hot tip".',
    category: TipCategory.investments,
    emoji: '🌱',
  ),
  FinanceTip(
    id: '29',
    text:
        'Index funds outperform 80% of actively managed funds over 10+ years. Keep it simple.',
    category: TipCategory.investments,
    emoji: '📊',
  ),
  FinanceTip(
    id: '30',
    text:
        'Invest in yourself first — skills that increase your income have the highest ROI.',
    category: TipCategory.investments,
    emoji: '🎓',
  ),
  FinanceTip(
    id: '31',
    text: 'Max out ELSS to save tax under 80C — free ₹1.5L deduction per year.',
    category: TipCategory.investments,
    emoji: '🏛️',
  ),
  FinanceTip(
    id: '32',
    text:
        'Never put more than 5% of your portfolio in a single stock. Diversification is free insurance.',
    category: TipCategory.investments,
    emoji: '🧺',
  ),
  FinanceTip(
    id: '33',
    text:
        'Rebalance your portfolio once a year — not every market dip. Noise vs signal.',
    category: TipCategory.investments,
    emoji: '⚖️',
  ),
  FinanceTip(
    id: '34',
    text:
        'Emergency fund in liquid FD or liquid mutual fund — not savings account, not equities.',
    category: TipCategory.investments,
    emoji: '💧',
  ),
  FinanceTip(
    id: '35',
    text:
        'Real estate is not liquid — don\'t count your home as an investment unless you plan to sell.',
    category: TipCategory.investments,
    emoji: '🏠',
  ),

  // ── Mindset ───────────────────────────────────────────────────────────────
  FinanceTip(
    id: '36',
    text:
        'Wealth is not income, it\'s what you keep. A ₹1L/month spender is poorer than a ₹50K/month saver.',
    category: TipCategory.mindset,
    emoji: '🧠',
  ),
  FinanceTip(
    id: '37',
    text:
        'Lifestyle inflation is the silent killer — every upgrade costs you years of freedom.',
    category: TipCategory.mindset,
    emoji: '🚀',
  ),
  FinanceTip(
    id: '38',
    text:
        'Comparing your finances to others is toxic — everyone\'s starting line is different.',
    category: TipCategory.mindset,
    emoji: '🎭',
  ),
  FinanceTip(
    id: '39',
    text:
        'Frugality isn\'t deprivation — it\'s choosing what truly matters to you.',
    category: TipCategory.mindset,
    emoji: '🎯',
  ),
  FinanceTip(
    id: '40',
    text:
        'Financial freedom is buying time, not things. Time is the only non-renewable resource.',
    category: TipCategory.mindset,
    emoji: '⏰',
  ),
  FinanceTip(
    id: '41',
    text:
        'Small consistent actions compound more than big sporadic ones. ₹100/day > ₹3,000 once a month.',
    category: TipCategory.mindset,
    emoji: '🔁',
  ),
  FinanceTip(
    id: '42',
    text:
        'Know the difference between an asset (puts money in your pocket) and a liability (takes money out).',
    category: TipCategory.mindset,
    emoji: '📚',
  ),
  FinanceTip(
    id: '43',
    text:
        'The best financial decision you can make is staying healthy — medical costs can wipe savings fast.',
    category: TipCategory.mindset,
    emoji: '❤️',
  ),
  FinanceTip(
    id: '44',
    text:
        'Your network affects your net worth — surround yourself with financially disciplined people.',
    category: TipCategory.mindset,
    emoji: '🤝',
  ),
  FinanceTip(
    id: '45',
    text:
        'A budget isn\'t a restriction — it\'s permission to spend guilt-free on what you\'ve prioritized.',
    category: TipCategory.mindset,
    emoji: '✅',
  ),
  FinanceTip(
    id: '46',
    text:
        'The secret to getting rich is boring: spend less than you earn, invest the difference, repeat.',
    category: TipCategory.mindset,
    emoji: '🔑',
  ),
  FinanceTip(
    id: '47',
    text:
        'Every financial mistake is tuition — analyze it, learn, move on. Guilt costs you twice.',
    category: TipCategory.mindset,
    emoji: '🎓',
  ),
  FinanceTip(
    id: '48',
    text:
        'FOMO investing — buying because everyone else is — is how most retail investors lose money.',
    category: TipCategory.mindset,
    emoji: '😰',
  ),
  FinanceTip(
    id: '49',
    text:
        'Read one personal finance book a year — knowledge compounds exactly like money does.',
    category: TipCategory.mindset,
    emoji: '📖',
  ),
  FinanceTip(
    id: '50',
    text:
        'True luxury is waking up without financial anxiety — not owning the most expensive things.',
    category: TipCategory.mindset,
    emoji: '🌅',
  ),
];
