import { atom, read, update } from 'claude-code'
import type { Register, SessionContextUsage, SessionRateLimit } from 'claude-code'

import type { ContextFill, UsageWindow, UsageWindows } from '../types'

const windows = atom({ plugin: 'usage-bars', key: 'windows' } as const, {
  fiveHour: null,
  sevenDay: null,
} as UsageWindows)

const context = atom({ plugin: 'usage-bars', key: 'context' } as const, null as ContextFill | null)

const BAR_CELLS = 20
const WEEKDAYS = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']

export function toWindows(rateLimits: readonly SessionRateLimit[]): UsageWindows {
  const find = (kind: string): UsageWindow | null => {
    const limit = rateLimits.find(candidate => candidate.kind === kind)
    return limit ? { percentUsed: limit.percentUsed, resetsAt: limit.resetsAt } : null
  }
  return { fiveHour: find('five_hour'), sevenDay: find('seven_day') }
}

export function toContextFill(usage: SessionContextUsage): ContextFill | null {
  if (usage.tokens === undefined || usage.percent === undefined) return null
  return { tokens: usage.tokens, window: usage.window, percent: usage.percent }
}

export function tokenText(tokens: number): string {
  if (tokens >= 1_000_000) {
    return `${Number((tokens / 1_000_000).toFixed(1))}M`
  }
  return `${Math.round(tokens / 1000)}k`
}

export function barText(percentUsed: number): string {
  const filled = Math.round((Math.min(percentUsed, 100) / 100) * BAR_CELLS)
  return '█'.repeat(filled) + '░'.repeat(BAR_CELLS - filled)
}

function barColor(percentUsed: number): string {
  if (percentUsed >= 90) {
    return 'red'
  }
  if (percentUsed >= 70) {
    return 'yellow'
  }
  return 'green'
}

function resetText(resetsAt: string | undefined, withWeekday: boolean): string {
  if (!resetsAt) return ''
  const date = new Date(resetsAt)
  const time = `${String(date.getHours()).padStart(2, '0')}:${String(date.getMinutes()).padStart(2, '0')}`
  return withWeekday ? `resets ${WEEKDAYS[date.getDay()]} ${time}` : `resets ${time}`
}

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    const result = await next(e)
    const usage = await $.session.usage()
    await update($, windows, () => toWindows(usage.rateLimits))
    await update($, context, () => toContextFill(usage.context))
    return result
  })

  on('session.measure', async ($, e, next) => {
    if (e.changed.includes('rateLimits')) {
      await update($, windows, () => toWindows(e.rateLimits))
    }
    if (e.changed.includes('context')) {
      await update($, context, () => toContextFill(e.context))
    }
    return next(e)
  })

  on('ui.render', { component: 'PromptHint' }, async ($, e, next) => {
    const current = await read($, windows)
    const contextFill = await read($, context)
    if (!current.fiveHour && !current.sevenDay && !contextFill) {
      return next(e)
    }

    const { Box, Text } = $.ui.resolve(e)
    const row = (label: string, window: UsageWindow | null, withWeekday: boolean) =>
      window && (
        <Box key={label}>
          <Text dimColor>{label} </Text>
          <Text color={barColor(window.percentUsed)}>{barText(window.percentUsed)}</Text>
          <Text> {String(Math.round(window.percentUsed)).padStart(3)}% </Text>
          <Text dimColor>{resetText(window.resetsAt, withWeekday)}</Text>
        </Box>
      )

    return (
      <Box flexDirection="row" flexWrap="wrap" justifyContent="space-between" columnGap={4} width="100%">
        <Text dimColor>{e.props.hint}</Text>
        <Box flexDirection="row" flexWrap="wrap" justifyContent="flex-end" columnGap={4}>
          {contextFill && (
            <Box key="ctx">
              <Text dimColor>ctx </Text>
              <Text color={barColor(contextFill.percent)}>{barText(contextFill.percent)}</Text>
              <Text> {String(Math.round(contextFill.percent)).padStart(3)}% </Text>
              <Text dimColor>
                {tokenText(contextFill.tokens)} / {tokenText(contextFill.window)} tokens
              </Text>
            </Box>
          )}
          {row('5h', current.fiveHour, false)}
          {row('week', current.sevenDay, true)}
        </Box>
      </Box>
    )
  })
}
