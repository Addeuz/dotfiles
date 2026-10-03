export type UsageWindow = { percentUsed: number; resetsAt?: string }

export type UsageWindows = { fiveHour: UsageWindow | null; sevenDay: UsageWindow | null }

export type ContextFill = { tokens: number; window: number; percent: number }

declare module 'claude-code' {
  interface PluginState {
    'usage-bars': { windows: UsageWindows; context: ContextFill | null }
  }
}
