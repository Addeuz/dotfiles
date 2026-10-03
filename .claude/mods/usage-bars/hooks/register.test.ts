import { expect, test } from 'claude-code/testing'

import { barText, toContextFill, tokenText, toWindows } from './register'

test('maps the rate-limit windows by kind', async () => {
  const result = toWindows([
    { kind: 'seven_day', percentUsed: 40, resetsAt: '2026-10-06T08:00:00Z' },
    { kind: 'five_hour', percentUsed: 12.5 },
  ])
  expect(result.fiveHour?.percentUsed).toBe(12.5)
  expect(result.sevenDay?.percentUsed).toBe(40)
})

test('fills the bar in proportion and caps it at 100%', async () => {
  expect(barText(50)).toBe('█'.repeat(10) + '░'.repeat(10))
  expect(barText(140)).toBe('█'.repeat(20))
})

test('reads the context fill only once a response reported it', async () => {
  expect(toContextFill({ window: 200_000 })).toBe(null)
  expect(toContextFill({ tokens: 50_000, window: 200_000, percent: 25 })?.percent).toBe(25)
})

test('formats token counts in k and M', async () => {
  expect(tokenText(48_600)).toBe('49k')
  expect(tokenText(200_000)).toBe('200k')
  expect(tokenText(1_000_000)).toBe('1M')
  expect(tokenText(1_250_000)).toBe('1.3M')
})
